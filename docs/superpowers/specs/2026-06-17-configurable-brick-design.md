# Configurable Brick (Step 1) — Design Spec

**Date:** 2026-06-17
**Brick:** `bricks/riverpod_simple_architecture`
**Status:** Approved design, pending implementation plan

## Context & Goal

This brick is becoming the shared base for many small **Android** utility apps. To
serve that role it must be **configurable per app** rather than one-size-fits-all.

Step 1 establishes the configuration mechanism and applies it to **per-app identity
/ branding** plus the single genuinely-optional subsystem that exists today
(`responsive_framework`). Networking stays **always on** (the user always needs it),
so it is **not** gated. Future optional modules (payments, ads, analytics — separate
sub-projects) will each add their own toggle following the pattern established here.

### Non-goals (explicitly out of scope for step 1)
- Gating the networking layer (Dio/interceptors/internet-checker) — stays always on.
- Building Settings/Onboarding/Analytics/Payments modules — later sub-projects. Step 1
  only produces the `AppConfig` values those modules will consume.
- Any toggle for a module that does not yet exist.

## Approach

**Hybrid (chosen over "inline conditionals everywhere" and "post_gen patches everything").**

- **Branding/identity** flows through a single generated constants file (`AppConfig`) via
  plain Mason substitution — no conditional logic in app code.
- **Native Android identity** (applicationId, launcher label) is patched by `post_gen.dart`
  (the brick is applied on top of an existing `flutter create`, so `android/` already
  exists; patching is the correct tool).
- **`responsive` toggle** is the only real conditional, done the idiomatic Mason way
  (conditional file path + one inline wiring block).

Rationale: keeps generated app code clean and analyzable, isolates the fragile native
patching to the hook, and limits conditional complexity to one toggle — the exact
pattern future module-toggles will reuse.

## Variables (`brick.yaml`)

| Var | Type | Default | Flows to |
|---|---|---|---|
| `project_name` | string | *(prompt; existing)* | pubspec `name`, package imports |
| `app_title` | string | title-cased `project_name` | `AppConfig.appTitle` → `MaterialApp.title` + Android `android:label` |
| `seed_color` | string (6-hex, no `#`) | `3F51B5` | `AppConfig.seedColor` → flex_color_scheme light/dark |
| `org` | string | `com.example` | Android `applicationId` = `<org>.<project_name.snakeCase()>` |
| `app_description` | string | `""` | pubspec `description` + `AppConfig.description` |
| `author` | string | `""` | `AppConfig.author` (About/Settings later) |
| `support_email` | string | `""` | `AppConfig.supportEmail` (About/Settings later) |
| `privacy_url` | string | `""` | `AppConfig.privacyUrl` (About/Settings later) |
| `responsive` | boolean | `false` | includes/excludes `responsive_framework` |

Notes:
- `seed_color` is the 6-digit hex **without** `#` so it templates directly into
  `Color(0xFF{{seed_color}})`. Documented in README. (A `pre_gen` normalization step may
  strip a leading `#`/whitespace defensively — decided during planning.)
- `app_title` default: if Mason cannot title-case in-template, `pre_gen` derives it from
  `project_name` (e.g. `unit_converter` → `Unit Converter`).

## Detailed design

### 1. `lib/const/app_config.dart` (new, generated) — the keystone
A single class of compile-time constants populated from the vars:
```dart
import 'package:flutter/material.dart';

/// Centralised, generated app identity/branding. Every later module
/// (Settings, About, analytics consent, paywall) reads identity from here.
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

### 2. Theme — derive from the seed color
`lib/core/theme/app_theme.dart` switches from the fixed `FlexScheme.brandBlue` to deriving
both light and dark `ThemeData` from `AppConfig.seedColor`, preserving the current
`subThemesData`, `useMaterial3`, density, and page-transition settings:
```dart
FlexThemeData.light(
  colors: FlexSchemeColor.from(primary: AppConfig.seedColor),
  // …existing surfaceMode/blend/subThemes/keyColors/pageTransitions/useMaterial3…
);
```

### 3. In-app title
`lib/app/view/app.dart`: `title: 'example App'` → `title: AppConfig.appTitle`.

### 4. pubspec
`__brick__/pubspec.yaml`: `description: "{{app_description}}"` (name/version unchanged).

### 5. Native Android identity (`hooks/post_gen.dart`)
After codegen, patch the host `android/` files (best-effort, no-op safe if patterns or
files are missing, and skipped when values equal their defaults):
- `android/app/build.gradle` **or** `build.gradle.kts`: set `applicationId` to
  `<org>.<project_name.snakeCase()>`.
- `android/app/src/main/AndroidManifest.xml`: set `android:label` to `{{app_title}}`.

Tolerant of Groovy vs Kotlin DSL; logs a warning and continues if a pattern is not found.

### 6. `responsive` toggle (the only conditional)
- **`responsive: true`** → current behavior: `responsive_framework` dependency present,
  `lib/shared/widget/responsive_wrapper.dart` generated, and `app.dart` wraps `child` in
  `ResponsiveBreakPointWrapper`.
- **`responsive: false`** (default) → omit the dependency (pubspec inline conditional),
  omit `responsive_wrapper.dart` (Mason conditional file path), and omit the
  `ResponsiveBreakPointWrapper` block in `app.dart` (inline conditional) so `child` is used
  directly.

### 7. README
Document every var, accepted formats (esp. `seed_color`), and example invocations
(default + `--responsive true`).

## Verification plan

The `responsive` toggle is the only branch, so verify **two** matrix points by
materialising `__brick__` into a throwaway `flutter create` project (token substituted),
excluding shipped generated files:

1. **`responsive=false` (default)** and **2. `responsive=true`** — each runs:
   `flutter pub get` → `dart run slang` → `dart run build_runner build` →
   `flutter analyze` (0 issues) → `flutter test` (all pass) → `flutter build apk`.

Additionally assert:
- `AppConfig` constants render correctly (title, `Color(0xFF…)`, author, etc.).
- Theme builds from the seed color (no reference to `FlexScheme.brandBlue`).
- Patched `applicationId` and `android:label` appear in the generated `android/` files
  for a non-default `org`/`app_title`.

## Risks

- **Android patching** is the main risk: gradle Groovy vs Kotlin DSL and varying
  `flutter create` output. Mitigation: pattern-match defensively, no-op + warn on miss,
  cover both DSLs.
- **`responsive=false` wiring**: `app.dart` must compile cleanly without the wrapper and
  without an unused import. Covered by the `responsive=false` verification run.

## Success criteria

- A single `mason make … --app_title "Unit Converter" --seed_color 3F51B5 --org dev.shreeman --responsive false`
  produces a project that analyzes clean, passes tests, builds an APK, is themed from the
  seed color, shows the right title/label, and has `applicationId = dev.shreeman.unit_converter`.
- `--responsive true` reproduces today's responsive behavior, also green.
- `AppConfig` is the single source of identity for all later modules.
