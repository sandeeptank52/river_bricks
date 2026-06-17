# Crash + Error Capture (Firebase Crashlytics) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add app-wide crash + uncaught-error capture to the brick via a no-op-default pluggable `CrashReporter`, with a marker-based script that activates Firebase Crashlytics per app.

**Architecture:** A `CrashReporter` interface with a default `NoopCrashReporter` (so apps run with zero Firebase). `wireCrashHandlers(reporter, talker)` routes `FlutterError.onError` + `PlatformDispatcher.onError` to talker AND the reporter, defensively. `bootstrap` calls it with the provider's reporter. A `tool/setup_firebase.sh` script + marker comments activate the Firebase implementation when the developer runs it.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3, talker, (script-added) firebase_core + firebase_crashlytics.

## Global Constraints

- Brick path: `bricks/riverpod_simple_architecture`; template root `<brick>/__brick__`; mason token `{{project_name.snakeCase()}}` in ALL source AND test imports (the harness substitutes it to `river_verify`).
- **No-op default:** the generated app compiles/runs with NO Firebase. No new runtime deps are added to the brick's `pubspec.yaml`; the script adds `firebase_core`/`firebase_crashlytics` at setup time.
- Errors route to **both** the global `talker` (always) and the active `CrashReporter`. A throwing reporter must never crash the app.
- The brick's `tool/*.dart` files are analyzed by `flutter analyze` — keep them firebase-free (pure Dart). The Firebase impl ships as `__brick__/tool/templates/firebase_crash_reporter.dart.tmpl` (`.tmpl` → not analyzed; mason still substitutes its token).
- Verify with the harness: `bricks/riverpod_simple_architecture/tool/verify_brick.sh <project_name> <responsive> [--key value ...]` → `mason make` → `flutter analyze` (0 issues) → `flutter test`. Prints `WORKDIR=<path>` then `VERIFY_OK`. **Run with the Bash sandbox disabled.**
- **Honest limitation:** the Firebase-ACTIVE path (`flutterfire configure` + real Crashlytics) is NOT harness-verifiable (needs a real Firebase project/account). It is documented + manually verified. Everything else — the no-op path, the error routing, and the Gradle-patch logic — IS harness-verified.

---

### Task 1: `CrashReporter` interface + no-op + provider

**Files:**
- Create: `__brick__/lib/shared/observability/crash_reporter.dart`
- Create: `__brick__/lib/shared/observability/crash_reporter_pod.dart`
- Test: `__brick__/test/shared/observability/crash_reporter_test.dart`

**Interfaces:**
- Produces: `abstract class CrashReporter` (`recordError`, `recordFlutterError`, `log`, `setCustomKey`); `class NoopCrashReporter implements CrashReporter`; `final crashReporterPod = Provider<CrashReporter>` (default `NoopCrashReporter`).

- [ ] **Step 1: Write the failing test** `crash_reporter_test.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_verify/shared/observability/crash_reporter.dart';

void main() {
  test('NoopCrashReporter completes every method without throwing', () async {
    const reporter = NoopCrashReporter();
    await reporter.recordError(Exception('x'), StackTrace.current);
    await reporter.recordFlutterError(
      FlutterErrorDetails(exception: Exception('x')),
    );
    await reporter.log('hello');
    await reporter.setCustomKey('k', 'v');
    // Reaching here without throwing is the assertion; make it explicit:
    expect(reporter, isA<CrashReporter>());
  });
}
```

- [ ] **Step 2: Run to verify it fails** — confirmed by the harness in Step 5 (build fails: `CrashReporter`/`NoopCrashReporter` undefined).

- [ ] **Step 3: Implement `crash_reporter.dart`**

```dart
import 'package:flutter/foundation.dart';

/// Pluggable crash/error reporter. The default [NoopCrashReporter] lets apps
/// run with no Firebase; `tool/setup_firebase.sh` swaps in a Firebase-backed
/// implementation.
abstract class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });

  Future<void> log(String message);

  Future<void> setCustomKey(String key, Object value);
}

/// Default reporter: does nothing. Errors are still logged via talker.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}
```

- [ ] **Step 4: Implement `crash_reporter_pod.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

/// The active [CrashReporter]. Defaults to a no-op so the app runs without
/// Firebase. `tool/setup_firebase.sh` replaces the no-op below with the
/// Firebase implementation.
final crashReporterPod = Provider<CrashReporter>(
  // FIREBASE_CRASH_REPORTER (do not remove — setup_firebase.sh swaps the line below)
  (ref) => const NoopCrashReporter(),
  name: 'crashReporterPod',
);
```

- [ ] **Step 5: Verify (harness)**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh crash_iface false`
Expected: `VERIFY_OK` — analyze 0 issues, all tests pass (incl. the new `crash_reporter_test`).

- [ ] **Step 6: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/shared/observability/crash_reporter.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/shared/observability/crash_reporter_pod.dart \
  bricks/riverpod_simple_architecture/__brick__/test/shared/observability/crash_reporter_test.dart
git commit -m "feat(brick): add CrashReporter interface + NoopCrashReporter + provider"
```

---

### Task 2: `wireCrashHandlers` error routing

**Files:**
- Create: `__brick__/lib/shared/observability/error_handlers.dart`
- Test: `__brick__/test/shared/observability/error_handlers_test.dart`

**Interfaces:**
- Consumes: `CrashReporter` (Task 1), global `talker` is NOT imported here (avoids a cycle with bootstrap) — `Talker` is passed in.
- Produces: `void wireCrashHandlers(CrashReporter reporter, Talker talker)`.

- [ ] **Step 1: Write the failing test** `error_handlers_test.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:river_verify/shared/observability/crash_reporter.dart';
import 'package:river_verify/shared/observability/error_handlers.dart';

class _SpyReporter implements CrashReporter {
  int flutterErrors = 0;
  int errors = 0;
  bool throwOnRecord = false;

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
      {bool fatal = false}) async {
    flutterErrors++;
    if (throwOnRecord) throw StateError('boom');
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false, String? reason}) async {
    errors++;
    if (throwOnRecord) throw StateError('boom');
  }

  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

void main() {
  final silentTalker = Talker(settings: TalkerSettings(enabled: false));
  FlutterExceptionHandler? original;
  setUp(() => original = FlutterError.onError);
  tearDown(() => FlutterError.onError = original);

  test('routes a FlutterError to the reporter', () {
    final spy = _SpyReporter();
    wireCrashHandlers(spy, silentTalker);
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('x')));
    expect(spy.flutterErrors, 1);
  });

  test('a throwing reporter does not crash the handler', () {
    final spy = _SpyReporter()..throwOnRecord = true;
    wireCrashHandlers(spy, silentTalker);
    // Must not throw synchronously:
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('x')));
    expect(spy.flutterErrors, 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — confirmed by the harness in Step 4 (build fails: `wireCrashHandlers` undefined).

- [ ] **Step 3: Implement `error_handlers.dart`**

```dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

/// Routes uncaught framework and async errors to both [talker] (always) and
/// [reporter]. Reporter failures are swallowed (logged to talker) so crash
/// reporting can never itself crash the app.
void wireCrashHandlers(CrashReporter reporter, Talker talker) {
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
    _safe(() => reporter.recordFlutterError(details), talker);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    _safe(() => reporter.recordError(error, stack, fatal: true), talker);
    return true;
  };
}

void _safe(Future<void> Function() op, Talker talker) {
  try {
    op().catchError((Object e, StackTrace s) => talker.handle(e, s));
  } catch (e, s) {
    talker.handle(e, s);
  }
}
```

- [ ] **Step 4: Verify (harness)**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh crash_handlers false`
Expected: `VERIFY_OK` — analyze 0 issues, all tests pass (incl. both `error_handlers_test` cases; test output pristine — the silent Talker prevents log noise).

- [ ] **Step 5: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/shared/observability/error_handlers.dart \
  bricks/riverpod_simple_architecture/__brick__/test/shared/observability/error_handlers_test.dart
git commit -m "feat(brick): add wireCrashHandlers (route FlutterError + async errors)"
```

---

### Task 3: Wire into `bootstrap` + add the `future_initializer` marker

**Files:**
- Modify: `__brick__/lib/bootstrap.dart`
- Modify: `__brick__/lib/features/splash/controller/future_initializer.dart`

**Interfaces:**
- Consumes: `wireCrashHandlers` (Task 2), `crashReporterPod` (Task 1), global `talker` (already in `bootstrap.dart`).

- [ ] **Step 1: Update `bootstrap.dart`.** Remove the `import 'dart:developer';` line. Add these imports (with the other project imports):

```dart
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/error_handlers.dart';
```
Then replace this block inside `bootstrap(...)`:

```dart
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };
```
with:

```dart
  wireCrashHandlers(parent.read(crashReporterPod), talker);
```

- [ ] **Step 2: Add the `FIREBASE_INIT` marker** in `future_initializer.dart`. Change:

```dart
  await (init());
  await Hive.initFlutter();
```
to:

```dart
  await (init());
  // FIREBASE_INIT (do not remove — setup_firebase.sh inserts Firebase.initializeApp here)
  await Hive.initFlutter();
```

- [ ] **Step 3: Verify (harness, BOTH responsive states)**

Run (sandbox disabled):
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh crash_wired false
bricks/riverpod_simple_architecture/tool/verify_brick.sh crash_wired_resp true
```
Then confirm the wiring + marker in the OFF run's WORKDIR:
```bash
grep -c "wireCrashHandlers" "$WORKDIR/lib/bootstrap.dart"                                   # expect 1
grep -c "FIREBASE_INIT" "$WORKDIR/lib/features/splash/controller/future_initializer.dart"   # expect 1
grep -c "dart:developer" "$WORKDIR/lib/bootstrap.dart"                                       # expect 0
```
Expected: both runs `VERIFY_OK` (analyze 0 issues, all tests pass); grep results 1/1/0.

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/bootstrap.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/features/splash/controller/future_initializer.dart
git commit -m "feat(brick): route uncaught errors via wireCrashHandlers in bootstrap"
```

---

### Task 4: Android Gradle plugin patcher (Dart, tested)

**Files:**
- Create: `__brick__/tool/firebase_gradle_patch.dart`
- Test: `__brick__/test/tool/firebase_gradle_patch_test.dart`

**Interfaces:**
- Produces: `String addFirebasePlugins(String content, {required bool isSettings})` — pure, idempotent; adds the Firebase Gradle plugins to a Kotlin-DSL `plugins { }` block. Plus a `main(args)` CLI: `dart run tool/firebase_gradle_patch.dart <settings|app> <path>`.

- [ ] **Step 1: Write the failing test** `firebase_gradle_patch_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../tool/firebase_gradle_patch.dart';

const _settings = '''
pluginManagement { }
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.5.0" apply false
}
''';

const _app = '''
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
''';

void main() {
  test('settings.gradle.kts gets both plugins with version + apply false', () {
    final out = addFirebasePlugins(_settings, isSettings: true);
    expect(out, contains('com.google.gms.google-services'));
    expect(out, contains('com.google.firebase.crashlytics'));
    expect(out, contains('apply false'));
  });

  test('app build.gradle.kts gets both plugins applied (no version)', () {
    final out = addFirebasePlugins(_app, isSettings: false);
    expect(out, contains('id("com.google.gms.google-services")'));
    expect(out, contains('id("com.google.firebase.crashlytics")'));
    expect(out.contains('apply false'), isFalse);
  });

  test('is idempotent', () {
    final once = addFirebasePlugins(_app, isSettings: false);
    final twice = addFirebasePlugins(once, isSettings: false);
    expect(
      'com.google.gms.google-services'.allMatches(twice).length,
      'com.google.gms.google-services'.allMatches(once).length,
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails** — confirmed by the harness in Step 4 (build fails: `addFirebasePlugins` undefined).

- [ ] **Step 3: Implement `firebase_gradle_patch.dart`**

```dart
import 'dart:io';

/// Adds the Firebase Gradle plugins to a Kotlin-DSL gradle file's first
/// `plugins { }` block. [isSettings] true → `settings.gradle.kts` (with version
/// + `apply false`); false → `app/build.gradle.kts` (applied, no version).
/// Idempotent: a plugin already present is not added again.
String addFirebasePlugins(String content, {required bool isSettings}) {
  final lines = isSettings
      ? const [
          'id("com.google.gms.google-services") version "4.4.2" apply false',
          'id("com.google.firebase.crashlytics") version "3.0.2" apply false',
        ]
      : const [
          'id("com.google.gms.google-services")',
          'id("com.google.firebase.crashlytics")',
        ];

  var result = content;
  for (final line in lines) {
    final id = RegExp(r'id\("([^"]+)"\)').firstMatch(line)!.group(1)!;
    if (result.contains(id)) continue; // already present — idempotent
    result = result.replaceFirst(
      RegExp(r'plugins\s*\{'),
      'plugins {\n    $line',
    );
  }
  return result;
}

/// CLI: `dart run tool/firebase_gradle_patch.dart <settings|app> <path>`
void main(List<String> args) {
  if (args.length != 2 || (args[0] != 'settings' && args[0] != 'app')) {
    stderr.writeln('usage: firebase_gradle_patch.dart <settings|app> <path>');
    exitCode = 2;
    return;
  }
  final file = File(args[1]);
  if (!file.existsSync()) {
    stderr.writeln('file not found: ${args[1]}');
    exitCode = 2;
    return;
  }
  file.writeAsStringSync(
    addFirebasePlugins(file.readAsStringSync(), isSettings: args[0] == 'settings'),
  );
  stdout.writeln('patched ${args[1]}');
}
```

- [ ] **Step 4: Verify (harness)**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh gradlepatch false`
Expected: `VERIFY_OK` — analyze 0 issues (the pure-Dart `tool/firebase_gradle_patch.dart` analyzes clean), all tests pass (incl. the three `firebase_gradle_patch_test` cases).

- [ ] **Step 5: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/tool/firebase_gradle_patch.dart \
  bricks/riverpod_simple_architecture/__brick__/test/tool/firebase_gradle_patch_test.dart
git commit -m "feat(brick): add tested Android Gradle Firebase-plugin patcher"
```

---

### Task 5: Activation script + Firebase impl template + README + final verify

**Files:**
- Create: `__brick__/tool/setup_firebase.sh`
- Create: `__brick__/tool/templates/firebase_crash_reporter.dart.tmpl`
- Modify: `bricks/riverpod_simple_architecture/README.md`

**Interfaces:** none (tooling + docs + final gate).

- [ ] **Step 1: Create the Firebase impl template** `tool/templates/firebase_crash_reporter.dart.tmpl` (mason substitutes the token; `.tmpl` keeps it out of `flutter analyze` until the script copies it in)

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

/// [CrashReporter] backed by Firebase Crashlytics. Installed by
/// tool/setup_firebase.sh.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {bool fatal = false, String? reason}) =>
      _crashlytics.recordError(error, stack, fatal: fatal, reason: reason);

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
          {bool fatal = false}) =>
      _crashlytics.recordFlutterError(details, fatal: fatal);

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);
}
```

- [ ] **Step 2: Create `setup_firebase.sh`**

```bash
#!/usr/bin/env bash
# Activates Firebase Crashlytics in this generated app. Run from the project root.
# Prereq: dart pub global activate flutterfire_cli
set -euo pipefail

command -v flutterfire >/dev/null 2>&1 || {
  echo "flutterfire CLI not found. Install it with:"
  echo "  dart pub global activate flutterfire_cli"
  exit 1
}

PKG=$(awk '/^name:/{print $2; exit}' pubspec.yaml)
OBS="lib/shared/observability"

echo "==> flutterfire configure (interactive: log in + select/create a Firebase project)"
flutterfire configure

echo "==> Adding Firebase dependencies"
flutter pub add firebase_core firebase_crashlytics

echo "==> Installing the Firebase crash reporter"
cp tool/templates/firebase_crash_reporter.dart.tmpl "$OBS/firebase_crash_reporter.dart"

echo "==> Wiring crashReporterPod -> FirebaseCrashReporter"
perl -0pi -e 's/\(ref\) => const NoopCrashReporter\(\),/(ref) => FirebaseCrashReporter(),/' "$OBS/crash_reporter_pod.dart"
grep -q "firebase_crash_reporter.dart" "$OBS/crash_reporter_pod.dart" || \
  perl -0pi -e "s{(import 'package:${PKG}/shared/observability/crash_reporter.dart';)}{\$1\nimport 'package:${PKG}/shared/observability/firebase_crash_reporter.dart';}" "$OBS/crash_reporter_pod.dart"

echo "==> Inserting Firebase.initializeApp into the init flow"
FI="lib/features/splash/controller/future_initializer.dart"
perl -0pi -e 's{// FIREBASE_INIT \(do not remove[^\n]*\n}{await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);\n}' "$FI"
grep -q "package:firebase_core/firebase_core.dart" "$FI" || \
  perl -0pi -e "s{(import 'package:hive_ce_flutter/hive_flutter.dart';)}{\$1\nimport 'package:firebase_core/firebase_core.dart';\nimport 'package:${PKG}/firebase_options.dart';}" "$FI"

echo "==> Patching Android Gradle plugins"
[ -f android/settings.gradle.kts ] && dart run tool/firebase_gradle_patch.dart settings android/settings.gradle.kts || echo "  (android/settings.gradle.kts not found — skipping)"
[ -f android/app/build.gradle.kts ] && dart run tool/firebase_gradle_patch.dart app android/app/build.gradle.kts || echo "  (android/app/build.gradle.kts not found — skipping)"

echo "==> Done. Run: flutter pub get && flutter run"
echo "    iOS: upload dSYMs to Crashlytics (see Firebase docs) for symbolicated crashes."
```

- [ ] **Step 3: Make the scripts executable in the template** so generated apps inherit the bit:

```bash
chmod +x bricks/riverpod_simple_architecture/__brick__/tool/setup_firebase.sh
```

- [ ] **Step 4: Add the README section** (after the existing feature list / before "Getting Started"):

```markdown
## Crash reporting (Firebase Crashlytics) 🐞

Apps ship with a no-op crash reporter, so they build and run with **no Firebase** — uncaught
errors are still logged via talker. To send crashes to Firebase Crashlytics:

```sh
dart pub global activate flutterfire_cli   # one-time
./tool/setup_firebase.sh                    # run in your generated app
```

The script runs `flutterfire configure` (the one interactive step — log in and pick/create a
Firebase project), adds the Firebase deps, installs the Firebase crash reporter, wires it in, and
patches the Android Gradle plugins. iOS needs dSYM upload (see the Firebase docs) for symbolicated
crashes.
```

- [ ] **Step 5: Final full-matrix verification (both responsive states)**

Run (sandbox disabled):
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_crash_off false
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_crash_on true
```
Then confirm the activation tooling is present in the OFF run's WORKDIR (no-op path still green; the `.tmpl` is NOT analyzed):
```bash
test -x "$WORKDIR/tool/setup_firebase.sh" && echo "SCRIPT_OK"
test -f "$WORKDIR/tool/templates/firebase_crash_reporter.dart.tmpl" && echo "TEMPLATE_OK"
```
Expected: both runs `VERIFY_OK` (analyze 0 issues, all tests pass); `SCRIPT_OK` + `TEMPLATE_OK`.

- [ ] **Step 6: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/tool/setup_firebase.sh \
  bricks/riverpod_simple_architecture/__brick__/tool/templates/firebase_crash_reporter.dart.tmpl \
  bricks/riverpod_simple_architecture/README.md
git commit -m "feat(brick): add Firebase Crashlytics setup script + template + docs"
```

---

## Self-Review

**Spec coverage:** `CrashReporter` interface + `NoopCrashReporter` (Task 1) ✓; `crashReporterPod` no-op default with marker (Task 1) ✓; `wireCrashHandlers` routing to talker + reporter, defensive (Task 2) ✓; bootstrap wiring + `FIREBASE_INIT` marker (Task 3) ✓; `setup_firebase.sh` (flutterfire configure → deps → impl → marker swaps → Gradle patch) (Task 5) ✓; Firebase impl template not analyzed (`.tmpl`) (Task 5) ✓; tested Gradle patcher (Task 4) ✓; README (Task 5) ✓; no new runtime deps in default brick (✓ — script adds them); harness-verified no-op path + both responsive states (Tasks 3/5) ✓; honest Firebase-active limitation (documented, not harness-tested) ✓.

**Placeholder scan:** none — every file has complete code; every verify step has exact commands + expected output.

**Type consistency:** `CrashReporter` methods (`recordError(Object, StackTrace?, {bool fatal, String? reason})`, `recordFlutterError(FlutterErrorDetails, {bool fatal})`, `log(String)`, `setCustomKey(String, Object)`) are identical in the interface (Task 1), the `_SpyReporter` + `wireCrashHandlers` calls (Task 2), and the Firebase impl template (Task 5). `crashReporterPod` (Provider<CrashReporter>) defined Task 1, consumed Task 3. `wireCrashHandlers(CrashReporter, Talker)` defined Task 2, called Task 3. `addFirebasePlugins(String, {required bool isSettings})` defined + tested Task 4, invoked by the script Task 5. Marker strings (`FIREBASE_CRASH_REPORTER`, `FIREBASE_INIT`) match between the files that carry them (Tasks 1/3) and the script that swaps them (Task 5).
