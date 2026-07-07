# 3.1.0

**G01–G04 scaffold-parity release — the brick now generates the full AppStudio foundation (structure, conventions, env, typed guarded router, theme token system) and is var-driven from a resolved stack.**

### Added
- 🧭 **Var-driven typed route table** (`routes` var): guarded routes (`OnboardingGuard`/`AuthGuard` with injected `NavigationStateReader`), the `guard_state.dart` single re-point seam (mock/storage-backed), placeholder `@RoutePage` pages, routed `SplashPage` resolver, and a `*` NotFound wildcard with recovery CTA.
- 🎨 **Theme token system**: `brand_palette.dart` (seeded from `seed_color`; the ONLY brand-hex file), `AppTokens`, `AppColorTheme` (+ `context.appColors`), registered in light AND dark themes; `PredictiveBackPageTransitionsBuilder` on Android (manifest opt-in patched by post_gen), Cupertino on iOS.
- 🧩 **Five design-system components** + barrel: `AppSelectableCard`, `AppPrimaryButton` (enabled/disabled/loading), `AppCategoryChipRow`, `AppPlayableListTile`, `AppBottomSheetScaffold` — themed exclusively through tokens, with light/dark/overflow (320dp × textScale 2.0) tests.
- 🧱 **Foundation seams**: sealed `AppFailure` hierarchy + `AppFailure.from`, analytics facade (`AnalyticsClient` + Noop/Recording impls, no SDK deps), `userSessionProvider` logout-generation scope, `PersistedStateStore`/`PersistedStateKeys` contract, `AsyncValueView` + failure-message mapper, `StorageKeys` registry, `SecureKvStore` + `obtainBoxEncryptionKey`, state-management conventions doc-in-code.
- 🌐 **Flavors + AppEnv**: live `main_<flavor>.dart` entrypoints → `runFlavoredApp(AppEnv)`; per-flavor `api_base_url_*` vars; `dioProvider` fails fast on an empty base URL.
- 🌍 **Var-driven language set** (`languages` var) and **feature skeletons** (`features` var, controller/view/barrel + mirrored test dir).
- 🔐 `.env.example` (provider blocks from the `providers` var) and `.gitignore` secret rules (firebase lines when `backend=firebase`); conditional analyzer excludes.
- 🍏 **iOS identity patching** in post_gen (bundle id + `CFBundleDisplayName`) — Android and iOS are co-equal.
- 📜 `MANIFEST.txt`: the brick-owned file enumeration (drift-checkable).

### Removed / Fixed
- 🗑️ Removed the demo `counter` and `theme_segmented_btn` features (theme switch moved into settings), the dead flavored mains, `splasher.dart`'s duplicate MaterialApp, and the `randomuser.me` demo baseUrl.
- 🐛 Fixed the `'appBox'` box-name mismatch via `StorageKeys`; realigned the test tree 1:1 with lib/ (incl. the `no_interenet_widget_test.dart` typo); textScaler clamp raised to `tokens.maxTextScale`; hardcoded widget colors re-routed through tokens (enforced by a brand-guard test).
- 📦 The brick no longer ships generated files (`router.gr.dart`, `strings*.g.dart`) — post_gen regenerates them for the selected language set.

# 3.0.0

**Modernization release — brings the template to current best practices and latest stable dependencies. Contains breaking changes.**

### Breaking
- ⬆️ **Migrated to Riverpod 3.** `AutoDisposeNotifier`/`AutoDisposeStreamNotifier` replaced with the unified `Notifier`/`StreamNotifier`; `StateProvider` now imported from `package:flutter_riverpod/legacy.dart`; the vendored talker observer and `ProviderObserver` usage updated to the new `ProviderObserverContext` signature; `ProviderBase`/`Override` now imported from `package:flutter_riverpod/misc.dart`.
- ⬆️ **auto_route 11**, **flex_color_scheme 8**, and other majors are now the pinned baseline.
- 🔁 **Replaced `flutter_secure_storage_x` with the official `flutter_secure_storage` (10.x)** and the **`responsive_framework` git fork with the pub.dev release (1.5.1)**. Android now requires **minSdk 23**.
- 🧪 **Dropped `riverpod_test`** (no Riverpod 3 release); provider/notifier tests use plain `ProviderContainer` and the observer test drives real provider lifecycle events.

### Changed / Fixed
- 📌 **All dependencies are now pinned in `pubspec.yaml`** instead of being added unpinned by the post-generation hook — generation is reproducible and the code always matches its dependencies.
- 🪝 **Reworked the post-generation hook:** resolves packages, deletes stale generated files, runs `dart run slang` for localization and `dart run build_runner build` for routes, and is non-interactive (CI-friendly).
- 🛡️ **Security:** the "trust all TLS certificates" helper is now gated behind `kDebugMode` so it can never weaken certificate validation in production builds.
- 🔧 Fixed deprecated Flutter APIs (`MediaQuery.textScaleFactor`, `Color.withOpacity`) and the flex_color_scheme 8 `CupertinoPageTransitionsBuilder` import.
- 📝 Refreshed README (requirements, platform minimums) and lint config; bumped to **3.0.0**.

 ## [2.3.0] - 2024-05-24

 ### Added
 - `CHANGELOG.md` to track project changes.
 - `TalkerRiverpodObserver` for improved state management logging and debugging.
 - `riverpod_test` package for streamlined provider testing.
 - Tests for `TalkerRiverpodObserver`.

 ### Changed
 - Downgraded `flutter_riverpod` to `^2.6.1`.
 - Switched `responsive_framework` to a git dependency for the latest updates and fixes.

# 2.2.1
 # Changelog

### 🐛 Bug Fixes
 All notable changes to this project will be documented in this file.

*   **test**: update import paths in tests to use the correct project name (`example` -> `{{project_name.snakeCase()}}`).
 ## [2.3.0] - 2024-05-24

# 2.2.0
 ### Added
 - `CHANGELOG.md` to track project changes.
 - `TalkerRiverpodObserver` for improved state management logging and debugging.
 - `riverpod_test` package for streamlined provider testing.
 - Tests for `TalkerRiverpodObserver`.

This release focuses on significant core refactoring, dependency cleanup, and code quality improvements for a more robust and maintainable foundation.

### 🚀 Features & Enhancements

*   **🎨 Persistent Theme Controller**: Upgraded the theme controller from `AutoDisposeNotifier` to `Notifier`. This ensures your selected theme persists throughout the app's lifecycle and isn't reset when UI components are rebuilt.
*   **📡 Reliable Internet Checker**: The internet connectivity provider now uses `StreamNotifier` instead of `AutoDisposeStreamNotifier`. This guarantees a continuous and stable stream of connectivity status, crucial for global features like the "No Internet" widget.
*   **🏗️ Native Flutter UI**: Replaced the `velocity_x` package with native Flutter widgets. This reduces external dependencies, providing more control and stability over the UI components.
*   **Riverpod v3 Support**: Upgraded all Riverpod-related packages to `^3.0.0-dev.17` to support the latest features and improvements from the upcoming Riverpod v3 release.

### ♻️ Refactoring & Code Quality

*   **✍️ Code Formatting**: Standardized Dart code line width to 80 characters for better readability and consistency across the project.
*   **📂 Improved Project Structure**: Relocated the `RiverpodObserver` to its own dedicated folder, improving code organization and maintainability.
*   **🗑️ Dependency Cleanup**:
    *   Removed `talker_riverpod_logger` and `riverpod_test` to streamline dependencies and simplify the testing setup.
    *   Removed the redundant `initialCounterValuePod`, simplifying the state logic for the counter example feature.

### 🐛 Bug Fixes

*   **✅ Splash Screen Logic**: Corrected a conditional check in the splash view to ensure a smoother and more reliable app initialization sequence.

# 2.1.5
- Fixed dependency erro of velocityx for intl.


# 2.1.4
- Fix responsive framework mobile size
-
# 2.1.3
- Fix heading

# 2.1.2
- Fix links

# 2.1.1
- ✨ **Architecture Documentation:** Added comprehensive architecture documentation ([architecture/architecture.md](__brick__/architecture/architecture.md)) detailing the feature-first approach, layer responsibilities, and usage of Riverpod, AutoRoute, and other libraries.
- ✨ **README Enhancement:** Updated the README to include a reference to the architecture documentation, making it easily accessible to users.


# 2.1.0
- ✨ **Enhanced Error Handling:** Improved error handling across the architecture, providing more robust and informative error messages and recovery mechanisms.
- ✨ **Dependency Management Refinements:** Addressed and resolved several dependency-related issues, ensuring better stability and compatibility within the project. This includes:
    - Updated dependency constraints to be more specific and reliable.
    - Fixed potential conflicts between dependencies.
    - Resolved issues related to incorrect or missing dependency installations.
    - dependency `spot` updated version

# 2.0.33
- Fix error installing dependency `riverpod_test`


# 2.0.32
- Fix error removeing dependency `custom_lint` and `riverpod_lint`

# 2.0.31
- Fix error installing dependency `riverpod_test`

# 2.0.30
- Upgrade version


# 2.0.29
- Fix error installing dependency `riverpod_test`


# 2.0.28+28
- Fix unused import in `no_internet_widget_test.dart`

# 2.0.27+27
-Improved Pre-Generation Script:
The pre-generation script now prompts the user to specify the project name.
If the user leaves the input empty, the script automatically uses the default project name from pubspec.yaml.
A hint is provided in the prompt message to guide the user.

- Fix `spot` version (semantic problem on pub add)

# 2.0.26+26
- Improved pre gen with auto filling project name
- fix `spot` dependency not added to dev_dependencies

# 2.0.25+25
- Fix dependency adding
- added default project name in

# 2.0.24+24
- Migrated to slang for localization
- Fix tests for internet checker
- Add `spot` for widget test


# 2.0.23+23
- fix missing dependency
- fixed imports
- remove depreceate class,functions(`AutoDisposeRef` -> `Ref`)


# 2.0.22+22
- Fixed for new version upgrade
```dart
mason upgrade --global
The current mason version is 0.1.0.
Because riverpod_simple_architecture requires mason version >=0.1.0-dev.49 <0.1.0, version solving failed.
```

# 2.0.21+21
- Added success error handler

# 2.0.20+20
- Fixed hive_ce_flutter import replace old hive import

# 2.0.19+19
- Fixed Wasm Support for flutter_secure_storage

# 2.0.18+18
- dependecy fixes

# 2.0.17+17
- Fix issues

# 2.0.16+16
- Fix issues

# 2.0.15+15
- Add talker_riverpod_logger for better logging
- Refactored code for logger of riverpod

# 2.0.14+14
- Update project name include in class App

# 2.0.13+13
- Fixed unused import

# 2.0.12+12
- Pinning dependency
- Chore: Update dependencies to latest
- Responsive framework nowusing a fork from [this repo](https://github.com/Shreemanarjun/ResponsiveFramework.git)
- Updated on test to cover 100%

# 2.0.11+11
- Fix tests for internet checker


# 2.0.10+10
- Fix IOS loading splash due to keychain access
- Fix themed segment button(remove MaterialStatePropertyAll with WidgetStatePropertyAll) (Flutter 3.22)

# 2.0.10+8
- Added secure storage for encryption
- Replaced bootstrap with Splasher. So user can have a smooth splash screen without flickering(deferFrame/allowFrame).
- (The template now using two runApp which will helpful for long async initialization with a freedback loading screen.)
- Fixed error on responsive framework where type cast failed due to the flutter engines first frame always return heigh and width as 0.


# 2.0.7+7
- fixed cache extension with commenting onResume function
- added additional pub get on all steps complete
- Covered 100% of code now....

# 2.0.5+5
- Fix spellings

# 2.0.4+4
- Added mason upgrades

# 2.0.3+4
- Fix localization errors

# 2.0.2+3
- Fix import with post generation conflicts

# 2.0.1+2
- Fix project name replacement

# 2.0.0+1
- Upgrade with 100% coverage
- Fixed all test case

# 1.0.2+1
- update internet checker to internet connectin plus for web support
- update tests for 100% coverage

# 1.0.1+7
- update docs

# 1.0.1+6
- fix issues

# 1.0.1+5
- fix issues

# 1.0.1+4
- upgraded responsive framework
- migration of dependencies to latest

# 1.0.1+3
- add vscode recommendation extensions

# 1.0.1+2
- fix gitignore

# 1.0.1+1
- Fix project name in pubspec

# 1.0.1+0
- no internet widget refined and restructured for simple usecase
- downgrade responsive framework (no migration note/docs to 1.1.0)
- fix text scaling issue
- rename no internet widget to ConnectionMonitor widget

# 1.0.0+11
- doc improvement

# 1.0.0+10
- remove custom lint

# 1.0.0+9
- remove custom lint

# 1.0.0+8
- 🐛 add herotag on floating action button
- ✨ add no internet to Root app
- ✨ added default main.dart
- 🐛 disable talker in release mode
- ✨ added analysis options with custom lint

# 1.0.0+7
- 🐛 changes in talker dio logger

# 1.0.0+6
- Fix interceptor (form data)

# 1.0.0+5
- Fix test files

# 1.0.0+4
- Fix test files

# 1.0.0+3
- Replace main.dart

# 1.0.0+2
- Fix Errors

# 1.0.0+1
- Make widgets testable
- Added test coverage
- Removed some dependency
- Added test tree

# 0.1.0+20
- 📝 update on completion msg

# 0.1.0+19
- 📝 update on completion msg

# 0.1.0+18
- 📝 update on completion msg

# 0.1.0+17
- 🚑 fix analysis issue
- 📝 update on docs

# 0.1.0+16
- ✨ fix postgen directory path

# 0.1.0+15
- ✨ fix postgen directory path

# 0.1.0+14
- ✨ fix postgen directory path

# 0.1.0+13
- ✨ Add postgen hooks

# 0.1.0+12
- 🚑 fix docs

# 0.1.0+11
- 🚑 fix state restoration on internet disconnection

# 0.1.0+10
- 🚑 theme selection in ui

# 0.1.0+9
- bootstraping method update to support provider scope

# 0.1.0+8
- 🌐 localization l10n.yaml file added

# 0.1.0+7
- fix runInShell
- removed hooks

# 0.1.0+6
- fix runInShell

# 0.1.0+5
- fix pregen

# 0.1.0+4
- fix pregen

# 0.1.0+3
- Check project on pregen

# 0.1.0+2
- Fix path and build issue post gen  release.

# 0.1.0+1
- initial release.
 ### Changed
 - Upgraded `flutter_riverpod` to `^2.6.1`.
 - Switched `responsive_framework` to a git dependency for the latest updates and fixes.
 - Refactored widget tests to improve reliability, remove unnecessary `runAsync` calls, and align with `riverpod_test` best practices.
 - Improved asynchronous testing in `cache_extension_test.dart` for better accuracy.
