# Settings + About Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a routed Settings/About page to the `riverpod_simple_architecture` brick — theme + language selectors (reused), and an About section (app name + version, contact support, privacy policy) sourced from `AppConfig`.

**Architecture:** A new feature-first `settings` feature with a `/settings` auto_route page, reached via a reusable gear `SettingsButton` in the app bar. About identity strings are injected into a presentational `AboutSection`; the running version comes from a `package_info_plus` provider; mailto/URL launching is a thin `url_launcher` wrapper. Labels are localized via slang.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3, auto_route 11, slang, `package_info_plus`, `url_launcher`.

## Global Constraints

- Brick path: `bricks/riverpod_simple_architecture`; template root `<brick>/__brick__`; mason token `{{project_name.snakeCase()}}`.
- App identity comes from `AppConfig` (generated, `lib/const/app_config.dart`): `AppConfig.appTitle`, `AppConfig.supportEmail`, `AppConfig.privacyUrl` (all `String`).
- Translations are slang; read via `final t = ref.watch(translationsPod);` then `t.settings.<key>`. New keys go in BOTH `lib/i18n/en.i18n.json` and `es.i18n.json`; the post-gen hook regenerates `strings*.g.dart` (do NOT hand-edit generated files).
- Error feedback uses the existing `GlobalHelper` mixin's `showErrorSnack({required Widget child})` (works on a `ConsumerState`, as `app.dart` already does).
- Pin new deps in `__brick__/pubspec.yaml`: `package_info_plus: ^10.1.0`, `url_launcher: ^6.3.2`. Do not change other pinned versions.
- Networking stays always-on; the `responsive` toggle must keep working.
- Verify with sub-project #1's harness: `bricks/riverpod_simple_architecture/tool/verify_brick.sh <project_name> <responsive> [--key value ...]` → real `mason make` (hooks: slang + build_runner) → `flutter analyze` (0 issues) → `flutter test` (all pass). It prints `WORKDIR=<path>` then `VERIFY_OK`. **Run it with the Bash sandbox disabled (needs network).** auto_route generates routes for files matching `lib/features/**_page.dart` and `lib/core/router/router.dart` (see `build.yaml`), so the page file MUST be named `settings_page.dart`.

---

### Task 1: Foundations — deps, leaf utilities, i18n keys

**Files:**
- Modify: `bricks/riverpod_simple_architecture/__brick__/pubspec.yaml`
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/shared/helper/launcher_helper.dart`
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/features/settings/controller/package_info_pod.dart`
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/i18n/en.i18n.json`
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/i18n/es.i18n.json`

**Interfaces:**
- Produces: `Future<bool> launchEmail(String email)`, `Future<bool> launchWebUrl(String url)` (in `launcher_helper.dart`); `final packageInfoPod` = `FutureProvider.autoDispose<PackageInfo>`; slang keys `t.settings.{title,appearance,language,about,version,contactSupport,privacyPolicy,launchError}`.

- [ ] **Step 1: Add the two dependencies** to `__brick__/pubspec.yaml` under `dependencies:` (place near the other UI/utility deps):

```yaml
  package_info_plus: ^10.1.0
  url_launcher: ^6.3.2
```

- [ ] **Step 2: Create `launcher_helper.dart`**

```dart
import 'package:url_launcher/url_launcher.dart';

/// Opens the device mail composer addressed to [email].
/// Returns false if launching fails (e.g. no mail app).
Future<bool> launchEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Opens [url] in the external browser. Returns false on failure
/// (unparseable URL or no handler).
Future<bool> launchWebUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
```

- [ ] **Step 3: Create `package_info_pod.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Exposes the running app's [PackageInfo] (name, version, build number).
final packageInfoPod = FutureProvider.autoDispose<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
```

- [ ] **Step 4: Add the `settings` block to `en.i18n.json`.** Replace the file contents with:

```json
{
  "locale": "en",
  "locale_en": "English",
  "locale_es": "Spanish",
  "counterAppBarTitle": "Counter",
  "settings": {
    "title": "Settings",
    "appearance": "Appearance",
    "language": "Language",
    "about": "About",
    "version": "Version",
    "contactSupport": "Contact support",
    "privacyPolicy": "Privacy policy",
    "launchError": "Could not open. Please try again."
  }
}
```

- [ ] **Step 5: Add the `settings` block to `es.i18n.json`.** Replace the file contents with:

```json
{
  "locale": "es",
  "locale_en": "English",
  "locale_es": "Spanish",
  "counterAppBarTitle": "Contador",
  "settings": {
    "title": "Ajustes",
    "appearance": "Apariencia",
    "language": "Idioma",
    "about": "Acerca de",
    "version": "Versión",
    "contactSupport": "Contactar soporte",
    "privacyPolicy": "Política de privacidad",
    "launchError": "No se pudo abrir. Inténtalo de nuevo."
  }
}
```

- [ ] **Step 6: Verify (harness)**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh settings_found false`
Then confirm the slang keys regenerated:
```bash
grep -c "contactSupport" "$WORKDIR/lib/i18n/strings.g.dart"   # expect >= 1
```
Expected: `VERIFY_OK` (deps resolve, analyze 0 issues, 99 tests pass), grep ≥ 1.

- [ ] **Step 7: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/pubspec.yaml \
  bricks/riverpod_simple_architecture/__brick__/lib/shared/helper/launcher_helper.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/features/settings/controller/package_info_pod.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/i18n/en.i18n.json \
  bricks/riverpod_simple_architecture/__brick__/lib/i18n/es.i18n.json
git commit -m "feat(brick): add package_info/url_launcher deps + settings i18n + leaf utils"
```

---

### Task 2: `AboutSection` widget

**Files:**
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/features/settings/view/about_section.dart`
- Test: `bricks/riverpod_simple_architecture/__brick__/test/features/settings/view/about_section_test.dart`

**Interfaces:**
- Consumes: `packageInfoPod` (Task 1), `t.settings.*` (Task 1), `easyWhen` (existing).
- Produces: `AboutSection({required String appTitle, required String supportEmail, required String privacyUrl, required VoidCallback onContactSupport, required VoidCallback onPrivacyPolicy})` — a presentational `ConsumerWidget`. Contact/Privacy rows have keys `ValueKey('contact_support_tile')` / `ValueKey('privacy_policy_tile')` and render only when their string is non-empty.

- [ ] **Step 1: Write the failing test** `about_section_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:river_verify/core/local_storage/app_storage_pod.dart';
import 'package:river_verify/features/settings/controller/package_info_pod.dart';
import 'package:river_verify/features/settings/view/about_section.dart';
import 'package:river_verify/i18n/strings.g.dart';
import 'package:river_verify/shared/pods/translation_pod.dart';

import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appBox', bytes: Uint8List(0));
  });
  tearDown(() => appBox.clear());

  final fakeInfo = PackageInfo(
    appName: 'Test',
    packageName: 'com.test',
    version: '1.2.3',
    buildNumber: '4',
  );

  ProviderContainer containerWith() => ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
          packageInfoPod.overrideWith((ref) => fakeInfo),
        ],
      );

  testWidgets('renders app title, version and both action rows', (tester) async {
    var contactTapped = 0;
    final container = containerWith();
    await tester.pumpApp(
      container: container,
      child: AboutSection(
        appTitle: 'My Tool',
        supportEmail: 's@x.dev',
        privacyUrl: 'https://x.dev/privacy',
        onContactSupport: () => contactTapped++,
        onPrivacyPolicy: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Tool'), findsOneWidget);
    expect(find.textContaining('1.2.3+4'), findsOneWidget);
    expect(find.byKey(const ValueKey('contact_support_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy_policy_tile')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('contact_support_tile')));
    expect(contactTapped, 1);
  });

  testWidgets('hides action rows when their config is empty', (tester) async {
    await tester.pumpApp(
      container: containerWith(),
      child: AboutSection(
        appTitle: 'My Tool',
        supportEmail: '',
        privacyUrl: '',
        onContactSupport: () {},
        onPrivacyPolicy: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('contact_support_tile')), findsNothing);
    expect(find.byKey(const ValueKey('privacy_policy_tile')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails** — it cannot even compile until `about_section.dart` exists. Run via the harness in Step 4 (the brick's tests run inside a generated project). Expected at this point: build failure (`AboutSection` undefined).

- [ ] **Step 3: Implement `about_section.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/controller/package_info_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/asynvalue_easy_when.dart';

/// The About section of the settings page. Presentational: identity strings are
/// injected; the running version comes from [packageInfoPod].
class AboutSection extends ConsumerWidget {
  const AboutSection({
    super.key,
    required this.appTitle,
    required this.supportEmail,
    required this.privacyUrl,
    required this.onContactSupport,
    required this.onPrivacyPolicy,
  });

  final String appTitle;
  final String supportEmail;
  final String privacyUrl;
  final VoidCallback onContactSupport;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsPod);
    final packageInfo = ref.watch(packageInfoPod);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            t.settings.about,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(appTitle),
          subtitle: packageInfo.easyWhen(
            data: (info) => Text(
              '${t.settings.version} ${info.version}+${info.buildNumber}',
            ),
            loadingWidget: () => const SizedBox.shrink(),
            errorWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
        if (supportEmail.isNotEmpty)
          ListTile(
            key: const ValueKey('contact_support_tile'),
            leading: const Icon(Icons.mail_outline),
            title: Text(t.settings.contactSupport),
            onTap: onContactSupport,
          ),
        if (privacyUrl.isNotEmpty)
          ListTile(
            key: const ValueKey('privacy_policy_tile'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.settings.privacyPolicy),
            onTap: onPrivacyPolicy,
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the test via the harness**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh about_app false`
Expected: `VERIFY_OK` — analyze 0 issues and ALL tests pass (the two new `about_section_test` cases plus the existing suite). The harness substitutes `{{project_name.snakeCase()}}` → `river_verify`, matching the test's `package:river_verify/...` imports.

- [ ] **Step 5: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/features/settings/view/about_section.dart \
  bricks/riverpod_simple_architecture/__brick__/test/features/settings/view/about_section_test.dart
git commit -m "feat(brick): add AboutSection (app name + version, contact/privacy rows)"
```

---

### Task 3: `SettingsPage` + route registration

**Files:**
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/features/settings/view/settings_page.dart`
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/core/router/router.dart`
- Test: `bricks/riverpod_simple_architecture/__brick__/test/features/settings/view/settings_page_test.dart`

**Interfaces:**
- Consumes: `AboutSection` (Task 2), `launchEmail`/`launchWebUrl` (Task 1), `AppConfig`, `ThemeSegmentedBtn`, `AppLocalePopUp`, `GlobalHelper`, `t.settings.*`.
- Produces: `@RoutePage` `SettingsPage` → generated `SettingsRoute` (used by Task 4). Route at path `/settings`.

- [ ] **Step 1: Write the failing test** `settings_page_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:river_verify/core/local_storage/app_storage_pod.dart';
import 'package:river_verify/features/settings/controller/package_info_pod.dart';
import 'package:river_verify/features/settings/view/about_section.dart';
import 'package:river_verify/features/settings/view/settings_page.dart';
import 'package:river_verify/features/theme_segmented_btn/view/theme_segmented_btn.dart';
import 'package:river_verify/i18n/strings.g.dart';
import 'package:river_verify/shared/pods/translation_pod.dart';
import 'package:river_verify/shared/widget/app_locale_popup.dart';

import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appBox', bytes: Uint8List(0));
  });
  tearDown(() => appBox.clear());

  final fakeInfo = PackageInfo(
    appName: 'Test',
    packageName: 'com.test',
    version: '1.0.0',
    buildNumber: '1',
  );

  testWidgets('renders appearance, language and about sections', (tester) async {
    await tester.pumpApp(
      container: ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
          packageInfoPod.overrideWith((ref) => fakeInfo),
        ],
      ),
      child: const SettingsPage(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byType(ThemeSegmentedBtn), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(AppLocalePopUp), findsOneWidget);
    expect(find.byType(AboutSection), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails** — verified by the harness in Step 5 (build fails: `SettingsPage` undefined).

- [ ] **Step 3: Implement `settings_page.dart`**

```dart
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/const/app_config.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/about_section.dart';
import 'package:{{project_name.snakeCase()}}/features/theme_segmented_btn/view/theme_segmented_btn.dart';
import 'package:{{project_name.snakeCase()}}/shared/helper/global_helper.dart';
import 'package:{{project_name.snakeCase()}}/shared/helper/launcher_helper.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/app_locale_popup.dart';

@RoutePage()
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with GlobalHelper {
  Future<void> _contactSupport() async {
    final ok = await launchEmail(AppConfig.supportEmail);
    if (!ok && mounted) {
      showErrorSnack(child: Text(ref.read(translationsPod).settings.launchError));
    }
  }

  Future<void> _privacyPolicy() async {
    final ok = await launchWebUrl(AppConfig.privacyUrl);
    if (!ok && mounted) {
      showErrorSnack(child: Text(ref.read(translationsPod).settings.launchError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsPod);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              t.settings.appearance,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeSegmentedBtn(),
          ),
          ListTile(
            title: Text(t.settings.language),
            trailing: const AppLocalePopUp(),
          ),
          const Divider(),
          AboutSection(
            appTitle: AppConfig.appTitle,
            supportEmail: AppConfig.supportEmail,
            privacyUrl: AppConfig.privacyUrl,
            onContactSupport: _contactSupport,
            onPrivacyPolicy: _privacyPolicy,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Register the route** in `router.dart`. Replace the `routes` list body with:

```dart
  late final List<AutoRoute> routes = [
    AutoRoute(
      page: CounterRoute.page,
      path: '/',
      initial: true,
    ),
    AutoRoute(
      page: SettingsRoute.page,
      path: '/settings',
    ),
  ];
```

- [ ] **Step 5: Run the test via the harness**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh settings_app false`
Then confirm the route generated:
```bash
grep -c "class SettingsRoute" "$WORKDIR/lib/core/router/router.gr.dart"   # expect 1
```
Expected: `VERIFY_OK` (build_runner generates `SettingsRoute`, analyze 0 issues, all tests pass incl. the new `settings_page_test`); grep = 1.

- [ ] **Step 6: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/features/settings/view/settings_page.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/core/router/router.dart \
  bricks/riverpod_simple_architecture/__brick__/test/features/settings/view/settings_page_test.dart
git commit -m "feat(brick): add SettingsPage (theme/language/about) + /settings route"
```

---

### Task 4: `SettingsButton` + wire into the home app bar

**Files:**
- Create: `bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/settings_button.dart`
- Modify: `bricks/riverpod_simple_architecture/__brick__/lib/features/counter/view/counter_page.dart`
- Test: `bricks/riverpod_simple_architecture/__brick__/test/shared/widgets/settings_button_test.dart`

**Interfaces:**
- Consumes: generated `SettingsRoute` (Task 3), `t.settings.title`.
- Produces: `SettingsButton` — a `ConsumerWidget` gear `IconButton` (key `ValueKey('settings_button')`) that pushes `SettingsRoute`.

- [ ] **Step 1: Write the failing test** `settings_button_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:river_verify/core/local_storage/app_storage_pod.dart';
import 'package:river_verify/i18n/strings.g.dart';
import 'package:river_verify/shared/pods/translation_pod.dart';
import 'package:river_verify/shared/widget/settings_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appBox', bytes: Uint8List(0));
  });
  tearDown(() => appBox.clear());

  testWidgets('renders a settings icon button', (tester) async {
    await tester.pumpApp(
      container: ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
        ],
      ),
      child: Scaffold(appBar: AppBar(actions: const [SettingsButton()])),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings_button')), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails** — verified by the harness in Step 5 (build fails: `SettingsButton` undefined).

- [ ] **Step 3: Implement `settings_button.dart`**

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

/// App-bar action that opens the [SettingsPage].
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsPod);
    return IconButton(
      key: const ValueKey('settings_button'),
      icon: const Icon(Icons.settings),
      tooltip: t.settings.title,
      onPressed: () => context.router.push(const SettingsRoute()),
    );
  }
}
```

- [ ] **Step 4: Add the button to the counter app bar.** In `counter_page.dart`, add the import:

```dart
import 'package:{{project_name.snakeCase()}}/shared/widget/settings_button.dart';
```
and change the app bar `actions` from:

```dart
        actions: const [AppLocalePopUp()],
```
to:

```dart
        actions: const [AppLocalePopUp(), SettingsButton()],
```

- [ ] **Step 5: Run the test via the harness**

Run (sandbox disabled): `bricks/riverpod_simple_architecture/tool/verify_brick.sh settingsbtn_app false`
Then confirm the button is wired into the counter app bar:
```bash
grep -c "SettingsButton" "$WORKDIR/lib/features/counter/view/counter_page.dart"   # expect >= 1
```
Expected: `VERIFY_OK` (analyze 0 issues, all tests pass incl. `settings_button_test` and the unchanged `counter_page_test`); grep ≥ 1.

- [ ] **Step 6: Commit**

```bash
git add bricks/riverpod_simple_architecture/__brick__/lib/shared/widget/settings_button.dart \
  bricks/riverpod_simple_architecture/__brick__/lib/features/counter/view/counter_page.dart \
  bricks/riverpod_simple_architecture/__brick__/test/shared/widgets/settings_button_test.dart
git commit -m "feat(brick): add SettingsButton and wire it into the home app bar"
```

---

### Task 5: README note + final full-matrix verification

**Files:**
- Modify: `bricks/riverpod_simple_architecture/README.md`

**Interfaces:** none (docs + final gate).

- [ ] **Step 1: Add a one-line feature note** to the README feature list (after the Logging bullet), so the brick advertises the new screen:

```markdown
✅ Settings & About - A routed settings page (theme, language, app version, contact support, privacy policy) wired from `AppConfig`, reachable via a gear button in the app bar. ⚙️
```

- [ ] **Step 2: Final full-matrix verification (both responsive states)**

Run BOTH (sandbox disabled), exercising the About rows with real config so they render:
```bash
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_settings_off false \
  --app_title "Settings Demo" --support_email "s@shreeman.dev" \
  --privacy_url "https://shreeman.dev/privacy"
bricks/riverpod_simple_architecture/tool/verify_brick.sh final_settings_on true \
  --support_email "s@shreeman.dev" --privacy_url "https://shreeman.dev/privacy"
```
Expected: both print `VERIFY_OK` (analyze 0 issues, all tests pass in both responsive states).

- [ ] **Step 3: Commit**

```bash
git add bricks/riverpod_simple_architecture/README.md
git commit -m "docs(brick): mention the settings & about page"
```

---

## Self-Review

**Spec coverage:** routed `/settings` page (Task 3) ✓; reusable gear button + home wiring (Task 4) ✓; About app name + version (Task 2, `packageInfoPod` Task 1) ✓; Contact support mailto + Privacy URL via `url_launcher` (Tasks 1+3) ✓; empty-config row hiding (Task 2) ✓; theme + language reuse (`ThemeSegmentedBtn`/`AppLocalePopUp`, Task 3) ✓; localized labels en+es (Task 1) ✓; error feedback via `GlobalHelper.showErrorSnack` (Task 3) ✓; deps pinned (Task 1) ✓; counter demo otherwise unchanged (Task 4 only adds the button) ✓; testing via `pump_app` + harness, both responsive states (Tasks 2–5) ✓.

> Spec refinement applied: `AboutSection` takes `appTitle`/`supportEmail`/`privacyUrl` as injected params (rather than reading `AppConfig` directly) so the empty-vs-non-empty row-hiding is testable in a single run; `SettingsPage` injects the `AppConfig` values. This satisfies the spec's intent and is strictly more testable.

**Placeholder scan:** none — every file has complete code; every verify step has exact commands + expected output.

**Type consistency:** `AboutSection(appTitle, supportEmail, privacyUrl, onContactSupport, onPrivacyPolicy)` is defined in Task 2 and consumed identically in Task 3. `packageInfoPod` (FutureProvider<PackageInfo>) defined Task 1, consumed Tasks 2/3 tests. `launchEmail`/`launchWebUrl` defined Task 1, consumed Task 3. `SettingsRoute` produced by Task 3's `@RoutePage SettingsPage`, consumed Task 4. Tile keys (`contact_support_tile`, `privacy_policy_tile`, `settings_button`) consistent between widgets and tests. `t.settings.*` keys identical across i18n (Task 1) and all consumers.
