# Configurable Brick (Step 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `riverpod_simple_architecture` Mason brick configurable per app — per-app branding/identity via a generated `AppConfig`, seed-color theming, native Android identity patching, and a `responsive_framework` on/off toggle.

**Architecture:** Branding/identity flows through a single generated constants file (`AppConfig`) via plain Mason substitution. Native Android identity (applicationId, launcher label) is patched by `post_gen.dart` (the brick is applied on top of an existing `flutter create`). The `responsive` toggle is the only real conditional, done with Mason conditional file paths + inline `{{#responsive}}`/`{{^responsive}}` blocks. Networking stays always-on.

**Tech Stack:** Mason (brick + Dart hooks), Flutter 3.44 / Dart 3.12, flex_color_scheme 8, Riverpod 3.

## Global Constraints

- Brick path: `bricks/riverpod_simple_architecture`. Template root: `<brick>/__brick__`. Hooks: `<brick>/hooks`.
- The brick is applied **on top of** an existing `flutter create` project (pre_gen reads the host `pubspec.yaml`); `android/` already exists at generation time.
- Mason token for the project name is `{{project_name.snakeCase()}}`.
- `seed_color` is a 6-hex string **without** `#` (templates into `Color(0xFF{{seed_color}})`).
- Networking is **not** gated — it stays in every generated app.
- Each generated project must end green: `flutter analyze` (0 issues) + `flutter test` (all pass) + `flutter build apk` (exit 0). Network operations require running the harness with the sandbox disabled.
- Pinned versions already in the brick: flutter_riverpod ^3.3.2, auto_route ^11.1.0, auto_route_generator ^10.5.0, flex_color_scheme ^8.4.0, responsive_framework ^1.5.1. Do not change these.
- `responsive` default = `false`; `org` default = `com.example`; `seed_color` default = `3F51B5`.

---

### Task 1: Verification harness

**Files:**
- Create: `bricks/riverpod_simple_architecture/tool/verify_brick.sh`

**Interfaces:**
- Produces: a script `verify_brick.sh <project_name> <responsive:true|false> [extra mason flags...]` that materializes the brick via real `mason make` into a throwaway Flutter project and runs `flutter analyze` + `flutter test`. Prints `VERIFY_OK` on success. Used by every later task.

- [ ] **Step 1: Write the harness script**

```bash
#!/usr/bin/env bash
# Usage: verify_brick.sh <project_name> <responsive> [extra mason flags...]
# Materializes the brick into a throwaway flutter project and verifies it.
set -euo pipefail

NAME="${1:?project_name required}"
RESPONSIVE="${2:?responsive (true|false) required}"
shift 2
EXTRA=("$@")

BRICK_DIR="$(cd "$(dirname "$0")/.." && pwd)"           # .../riverpod_simple_architecture
WORK="$(mktemp -d)/$NAME"

flutter create --org com.verify --project-name "$NAME" "$WORK" >/dev/null
cd "$WORK"

mason add "$(basename "$BRICK_DIR")" --path "$BRICK_DIR" >/dev/null 2>&1 || true
mason make "$(basename "$BRICK_DIR")" \
  --project_name "$NAME" \
  --responsive "$RESPONSIVE" \
  --on-conflict overwrite \
  "${EXTRA[@]}"

echo "=== analyze ===" && flutter analyze
echo "=== test ===" && flutter test
echo "WORKDIR=$WORK"
echo "VERIFY_OK"
```

- [ ] **Step 2: Make it executable and run the baseline against the CURRENT brick**

Run:
```bash
chmod +x bricks/riverpod_simple_architecture/tool/verify_brick.sh
bricks/riverpod_simple_architecture/tool/verify_brick.sh baseline_app false
```
Expected: ends with `VERIFY_OK` (the current modernized brick still generates a green project). If `mason make` fails because `responsive` is not yet a declared var, that is expected and resolved in Task 6 — for the baseline run, temporarily drop the `--responsive` flag to confirm the harness itself works, then restore it.

> NOTE for the implementer: run the harness with the Bash sandbox **disabled** (it needs pub.dev + Gradle network access).

- [ ] **Step 3: Commit**

```bash
git add bricks/riverpod_simple_architecture/tool/verify_brick.sh
git commit -m "test: add brick verification harness (mason make + analyze + test)"
```

---

### Task 2: Declare brick variables + pre_gen derivations

**Files:**
- Modify: `bricks/riverpod_simple_architecture/brick.yaml`
- Modify: `bricks/riverpod_simple_architecture/hooks/pre_gen.dart`

**Interfaces:**
- Produces: context vars available to all templates: `project_name` (existing, set by pre_gen), `app_title`, `seed_color`, `org`, `app_description`, `author`, `support_email`, `privacy_url`, `responsive`. `app_title` defaults to a title-cased `project_name` when left blank; `seed_color` has any leading `#`/whitespace stripped.

- [ ] **Step 1: Add the `vars` block to `brick.yaml`** (replace the commented-out `# vars:` section at the end of the file)

```yaml
vars:
  app_title:
    type: string
    description: App display title (blank = derived from project name)
    default: ""
    prompt: App display title?
  seed_color:
    type: string
    description: Brand seed color, 6-hex without '#'
    default: "3F51B5"
    prompt: Brand seed color (6-hex, no #)?
  org:
    type: string
    description: Organization in reverse-domain form
    default: "com.example"
    prompt: Organization (reverse-domain)?
  app_description:
    type: string
    description: Short app description
    default: ""
    prompt: App description?
  author:
    type: string
    description: Author / publisher name
    default: ""
    prompt: Author name?
  support_email:
    type: string
    description: Support email
    default: ""
    prompt: Support email?
  privacy_url:
    type: string
    description: Privacy policy URL
    default: ""
    prompt: Privacy policy URL?
  responsive:
    type: boolean
    description: Include responsive_framework
    default: false
    prompt: Include responsive_framework?
```

> `project_name` is intentionally NOT declared here — `pre_gen.dart` continues to own it (so its default can be read from the host `pubspec.yaml`). Mason prompts these vars BEFORE `pre_gen` runs, so pre_gen can read/adjust them.

- [ ] **Step 2: Extend `pre_gen.dart`** to derive `app_title` and normalize `seed_color`. Add this, after the existing block that sets `context.vars['project_name'] = projectName;`:

```dart
  // Derive a display title from the project name when not provided.
  final providedTitle = (context.vars['app_title'] as String?)?.trim() ?? '';
  if (providedTitle.isEmpty) {
    final title = projectName
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    context.vars['app_title'] = title;
  } else {
    context.vars['app_title'] = providedTitle;
  }

  // Normalize the seed color: strip a leading '#' and whitespace.
  final seed = (context.vars['seed_color'] as String?)?.trim() ?? '3F51B5';
  context.vars['seed_color'] =
      seed.startsWith('#') ? seed.substring(1) : seed;
```

- [ ] **Step 3: Verify generation still succeeds with the new vars (defaults)**

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh vars_app false
```
Expected: `VERIFY_OK`. (Vars are declared but not yet consumed; generation must still be green.)

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/brick.yaml bricks/riverpod_simple_architecture/hooks/pre_gen.dart
git commit -m "feat(brick): declare config vars + derive app_title/seed_color in pre_gen"
```

---

### Task 3: Generated `AppConfig` + pubspec description

**Files:**
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/const/app_config.dart`
- Modify: `bricks/riverpod_simple_architecture/__brick__/pubspec.yaml` (the `description:` line)

**Interfaces:**
- Produces: `AppConfig` with `static const` members: `appTitle` (String), `seedColor` (Color), `description` (String), `author` (String), `supportEmail` (String), `privacyUrl` (String). Consumed by Task 4 (`seedColor`) and Task 5 (`appTitle`), and by future modules.

- [ ] **Step 1: Create `app_config.dart`**

```dart
import 'package:flutter/material.dart';

/// Centralised, generated app identity/branding.
///
/// Every later module (Settings, About, analytics consent, paywall) reads
/// app identity from here instead of hard-coding literals.
class AppConfig {
  const AppConfig._();

  static const String appTitle = '{{app_title}}';
  static const Color seedColor = Color(0xFF{{seed_color}});
  static const String description = '{{app_description}}';
  static const String author = '{{author}}';
  static const String supportEmail = '{{support_email}}';
  static const String privacyUrl = '{{privacy_url}}';
}
```

- [ ] **Step 2: Set the pubspec description.** In `__brick__/pubspec.yaml`, change:

```yaml
description: ""
```
to:
```yaml
description: "{{app_description}}"
```

- [ ] **Step 3: Verify `AppConfig` renders and analyzes**

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh config_app false \
  --app_title "Config App" --seed_color 112233 --author "Shreeman" \
  --support_email "a@b.com" --privacy_url "https://x.dev/privacy" \
  --app_description "A config test app"
```
Then confirm the generated file (path printed as `WORKDIR`):
```bash
grep -E "appTitle = 'Config App'|Color\(0xFF112233\)|author = 'Shreeman'" "$WORKDIR/lib/const/app_config.dart"
```
Expected: harness prints `VERIFY_OK`; grep matches all three lines.

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/const/app_config.dart bricks/riverpod_simple_architecture/__brick__/pubspec.yaml
git commit -m "feat(brick): generate AppConfig identity constants + pubspec description"
```

---

### Task 4: Theme derives from `AppConfig.seedColor`

**Files:**
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/core/theme/app_theme.dart`

**Interfaces:**
- Consumes: `AppConfig.seedColor` (from Task 3).
- Produces: `Themes.theme` / `Themes.darkTheme` derived from the seed color (no `FlexScheme.brandBlue`).

- [ ] **Step 1: Add the import** at the top of `app_theme.dart`:

```dart
import 'package:{{project_name.snakeCase()}}/const/app_config.dart';
```

- [ ] **Step 2: Replace the fixed scheme with the seed color.** In BOTH `Themes.theme` (`FlexThemeData.light(...)`) and `Themes.darkTheme` (`FlexThemeData.dark(...)`), replace the line:

```dart
        scheme: FlexScheme.brandBlue,
```
with:
```dart
        colors: FlexSchemeColor.from(
          primary: AppConfig.seedColor,
          brightness: Brightness.light, // use Brightness.dark in darkTheme
        ),
```
(In `darkTheme`, set `brightness: Brightness.dark`.) Leave all other arguments — `surfaceMode`, `blendLevel`, `appBarOpacity`, `subThemesData`, `keyColors`, `pageTransitionsTheme`, `visualDensity`, `useMaterial3` — unchanged.

- [ ] **Step 3: Verify theme builds from the seed and analyzes**

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh theme_app false --seed_color 9C27B0
```
Then:
```bash
grep -c "FlexScheme.brandBlue" "$WORKDIR/lib/core/theme/app_theme.dart"   # expect 0
grep -c "FlexSchemeColor.from" "$WORKDIR/lib/core/theme/app_theme.dart"   # expect 2
```
Expected: `VERIFY_OK`; brandBlue count 0; `FlexSchemeColor.from` count 2.

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/core/theme/app_theme.dart
git commit -m "feat(brick): derive theme from AppConfig.seedColor"
```

---

### Task 5: In-app title from `AppConfig`

**Files:**
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/app/view/app.dart`

**Interfaces:**
- Consumes: `AppConfig.appTitle` (Task 3).

- [ ] **Step 1: Add the import** at the top of `app.dart` (with the other project imports):

```dart
import 'package:{{project_name.snakeCase()}}/const/app_config.dart';
```

- [ ] **Step 2: Use it for the title.** Replace:

```dart
      title: 'example App',
```
with:
```dart
      title: AppConfig.appTitle,
```

- [ ] **Step 3: Verify**

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh title_app false --app_title "My Tool"
```
Then:
```bash
grep -c "AppConfig.appTitle" "$WORKDIR/lib/app/view/app.dart"   # expect 1
```
Expected: `VERIFY_OK`; grep count 1.

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/app/view/app.dart
git commit -m "feat(brick): use AppConfig.appTitle for MaterialApp title"
```

---

### Task 6: `responsive` toggle

**Files:**
- Modify: `bricks/riverpod_simple_architecture/__brick__/pubspec.yaml`
- Rename: `bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/responsive_wrapper.dart` → `bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/{{#responsive}}responsive_wrapper.dart{{/responsive}}`
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/app/view/app.dart`

**Interfaces:**
- Consumes: `responsive` boolean var.
- Produces: when `responsive=false`, no `responsive_framework` dependency, no `responsive_wrapper.dart`, and `app.dart` does not reference `ResponsiveBreakPointWrapper`. When `true`, today's behavior.

- [ ] **Step 1: Gate the dependency in `pubspec.yaml`.** Replace:

```yaml
  responsive_framework: ^1.5.1
```
with:
```yaml
{{#responsive}}  responsive_framework: ^1.5.1
{{/responsive}}
```

- [ ] **Step 2: Gate the wrapper file via its path.** Rename the file so the directory entry is conditional:

```bash
git mv \
  bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/responsive_wrapper.dart \
  "bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/{{#responsive}}responsive_wrapper.dart{{/responsive}}"
```
Mason omits a file whose name contains a falsy section, so the wrapper is only generated when `responsive=true`.

- [ ] **Step 3: Gate the import in `app.dart`.** Replace:

```dart
import 'package:{{project_name.snakeCase()}}/shared/widget/responsive_wrapper.dart';
```
with:
```dart
{{#responsive}}import 'package:{{project_name.snakeCase()}}/shared/widget/responsive_wrapper.dart';
{{/responsive}}
```

- [ ] **Step 4: Gate the wrapper usage in `app.dart`.** Replace this block:

```dart
          child = ResponsiveBreakPointWrapper(
            firstFrameWidget: Container(
              color: Colors.white,
            ),
            child: child!,
          );
```
with:
```dart
{{#responsive}}
          child = ResponsiveBreakPointWrapper(
            firstFrameWidget: Container(
              color: Colors.white,
            ),
            child: child!,
          );
{{/responsive}}
{{^responsive}}
          child = child!;
{{/responsive}}
```
(The `{{^responsive}}` branch preserves the non-null assertion that the wrapper previously provided, so the subsequent `MediaQuery(child: child)` still receives a non-null `Widget`.)

- [ ] **Step 5: Verify BOTH toggle states are green**

Run (responsive OFF — default):
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh resp_off false
grep -c "responsive_framework" "$WORKDIR/pubspec.yaml"                 # expect 0
test ! -e "$WORKDIR/lib/shared/widget/responsive_wrapper.dart" && echo NO_WRAPPER
grep -c "ResponsiveBreakPointWrapper" "$WORKDIR/lib/app/view/app.dart" # expect 0
```
Run (responsive ON):
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh resp_on true
grep -c "responsive_framework" "$WORKDIR/pubspec.yaml"                 # expect 1
test -e "$WORKDIR/lib/shared/widget/responsive_wrapper.dart" && echo HAS_WRAPPER
grep -c "ResponsiveBreakPointWrapper" "$WORKDIR/lib/app/view/app.dart" # expect 1
```
Expected: both runs print `VERIFY_OK` and the grep/file assertions match.

- [ ] **Step 6: Commit**

```bash
git add -A bricks/riverpod_simple_architecture/__brick__
git commit -m "feat(brick): add responsive_framework on/off toggle"
```

---

### Task 7: Native Android identity patching in `post_gen`

**Files:**
- Modify: `bricks/riverpod_simple_architecture/hooks/post_gen.dart`

**Interfaces:**
- Consumes: `org`, `project_name`, `app_title` vars (available via `context.vars`).
- Produces: patched `applicationId` (`<org>.<project_name snake>`) and `android:label` (`app_title`) in the generated `android/` files. No-op + warn if files/patterns are missing or values are defaults.

- [ ] **Step 1: Add an Android-identity patch step to `post_gen.dart`.** Add this function and call it from `run` (after the codegen steps, before the success banner):

```dart
void _patchAndroidIdentity(HookContext context) {
  final org = (context.vars['org'] as String?)?.trim() ?? '';
  final name = (context.vars['project_name'] as String?)?.trim() ?? '';
  final title = (context.vars['app_title'] as String?)?.trim() ?? '';
  final snake = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  // applicationId in build.gradle(.kts), only when org is non-default.
  if (org.isNotEmpty && org != 'com.example' && snake.isNotEmpty) {
    final appId = '$org.$snake';
    for (final p in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
      final f = File(p);
      if (!f.existsSync()) continue;
      var src = f.readAsStringSync();
      final patched = src.replaceAllMapped(
        RegExp(r'''applicationId\s*=?\s*["'][^"']*["']'''),
        (_) => 'applicationId = "$appId"',
      );
      if (patched != src) {
        f.writeAsStringSync(patched);
        context.logger.detail('Set applicationId to $appId in $p');
      } else {
        context.logger.detail('applicationId pattern not found in $p');
      }
    }
  }

  // android:label in AndroidManifest.xml.
  if (title.isNotEmpty) {
    final f = File('android/app/src/main/AndroidManifest.xml');
    if (f.existsSync()) {
      var src = f.readAsStringSync();
      final patched = src.replaceAllMapped(
        RegExp(r'android:label="[^"]*"'),
        (_) => 'android:label="$title"',
      );
      if (patched != src) {
        f.writeAsStringSync(patched);
        context.logger.detail('Set android:label to "$title"');
      } else {
        context.logger.detail('android:label not found in AndroidManifest.xml');
      }
    }
  }
}
```

Then add the call inside `run`, right before the final success `context.logger.info(...)`:
```dart
  _patchAndroidIdentity(context);
```

- [ ] **Step 2: Verify the patches land**

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh ident_app false \
  --org dev.shreeman --app_title "Ident App"
```
Then:
```bash
grep -E 'applicationId\s*=\s*"dev.shreeman.ident_app"' \
  "$WORKDIR"/android/app/build.gradle* 2>/dev/null
grep 'android:label="Ident App"' \
  "$WORKDIR/android/app/src/main/AndroidManifest.xml"
```
Expected: `VERIFY_OK`; both greps match.

- [ ] **Step 3: Verify the default-org case is a safe no-op** (does not corrupt the gradle file)

Run:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh noident_app false
```
Expected: `VERIFY_OK` (default `org=com.example` → applicationId left as flutter create set it; generation still green).

- [ ] **Step 4: Commit**

```bash
git add bricks/riverpod_simple_architecture/hooks/post_gen.dart
git commit -m "feat(brick): patch Android applicationId + label from org/app_title vars"
```

---

### Task 8: Document the vars + final full-matrix verification

**Files:**
- Modify: `bricks/riverpod_simple_architecture/README.md`

**Interfaces:** none (docs + final gate).

- [ ] **Step 1: Add a "Configuration variables" section to the README** (place it just after the existing "Variables ✨" table; replace that table's single-row body with the full set):

```markdown
## Variables ✨

| Variable          | Description                                  | Default       | Type    |
| ----------------- | -------------------------------------------- | ------------- | ------- |
| `project_name`    | Project / package name                       | *(prompted)*  | string  |
| `app_title`       | Display title (launcher + in-app)            | derived       | string  |
| `seed_color`      | Brand seed color, **6-hex without `#`**      | `3F51B5`      | string  |
| `org`             | Reverse-domain org (→ `applicationId`)       | `com.example` | string  |
| `app_description` | Short description (pubspec + About)          | `""`          | string  |
| `author`          | Author / publisher                           | `""`          | string  |
| `support_email`   | Support email (About)                        | `""`          | string  |
| `privacy_url`     | Privacy policy URL (About)                   | `""`          | string  |
| `responsive`      | Include `responsive_framework`               | `false`       | boolean |

### Example

```sh
mason make riverpod_simple_architecture \
  --project_name unit_converter \
  --app_title "Unit Converter" \
  --seed_color 3F51B5 \
  --org dev.shreeman \
  --responsive false
```

App identity is centralised in `lib/const/app_config.dart` (`AppConfig`). The theme is
derived from `seed_color`. With `--responsive true`, `responsive_framework` and its
wrapper are included; otherwise they are omitted.
```

- [ ] **Step 2: Final full-matrix verification (both toggle states, incl. APK build)**

Run (sandbox disabled):
```bash
# responsive OFF + full identity, then build an APK
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_off false \
  --app_title "Final Off" --seed_color 00897B --org dev.shreeman \
  --author "Shreeman" --support_email "s@shreeman.dev" \
  --privacy_url "https://shreeman.dev/privacy" --app_description "Final off app"
( cd "$WORKDIR" && flutter build apk --release )

# responsive ON
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_on true --seed_color 00897B
( cd "$WORKDIR" && flutter build apk --release )
```
Expected: both harness runs print `VERIFY_OK`; both `flutter build apk --release` exit 0.

- [ ] **Step 3: Commit**

```bash
git add bricks/riverpod_simple_architecture/README.md
git commit -m "docs(brick): document configuration variables"
```

---

## Self-Review

**Spec coverage:** AppConfig (Task 3) ✓; seed-color theme (Task 4) ✓; app_title in-app (Task 5) + Android label (Task 7) ✓; pubspec description (Task 3) ✓; org → applicationId (Task 7) ✓; author/support_email/privacy_url in AppConfig (Task 3) ✓; responsive toggle across pubspec + file + app.dart (Task 6) ✓; vars + defaults + pre_gen derivations (Task 2) ✓; README (Task 8) ✓; two-point verification matrix incl. APK (Tasks 6 & 8) ✓. Networking left untouched ✓.

**Placeholder scan:** No TBD/TODO; every code change shows full before/after; every verification step has exact commands + expected output.

**Type consistency:** `AppConfig.seedColor` is `Color` (defined Task 3, consumed Task 4); `AppConfig.appTitle` is `String` (Task 3 → Task 5). `context.vars` keys (`app_title`, `seed_color`, `org`, `project_name`, `responsive`) consistent across pre_gen (Task 2), templates (Tasks 3–6), and post_gen (Task 7). `{{#responsive}}`/`{{^responsive}}` section name matches the `responsive` var.
