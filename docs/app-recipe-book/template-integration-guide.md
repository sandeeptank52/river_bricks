# Template Integration Guide

How recipe-book ingredients map onto the `riverpod_simple_architecture` brick.

This guide answers the question: "When I generate a new app from the brick, which
ingredients do I already have, and what do I still need to add?" Use this
alongside [production-foundation.md](production-foundation.md) and the
[ingredient-catalog.md](ingredient-catalog.md) when planning a new app.

---

## Already provided by the brick

| Ingredient | Provided by | Notes |
|---|---|---|
| [crash-reporting](ingredient-catalog.md#crash-reporting) | Firebase Crashlytics + `wireCrashHandlers` in `bootstrap.dart` | Run `bash tool/setup_firebase.sh` to complete Firebase project setup; the handler routes both Flutter framework errors and Dart zone errors |
| [observability-talker](ingredient-catalog.md#observability-talker) | `talker_flutter` + `TalkerRiverpodObserver`, bootstrap-wired | Riverpod provider state changes and errors are logged automatically; add `talker_dio_logger` if you add Dio |
| [secure-storage](ingredient-catalog.md#secure-storage) | `flutter_secure_storage` 10 | Android `minSdk` is enforced at 23 (required for `AndroidKeyStore`); use the storage service abstraction for easy mocking |
| [theming-settings](ingredient-catalog.md#theming-settings) | `flex_color_scheme` 8 + `SettingsPage` / `AboutSection` on `/settings` route | AboutSection shows app version, privacy policy URL, and OSS licenses; customize seed color in `app_theme.dart` |
| [local-database](ingredient-catalog.md#local-database) | `hive_ce` (initialized in `bootstrap.dart`) | Register type adapters before `runApp`; encrypt sensitive boxes with `HiveAesCipher` + a key from `flutter_secure_storage` |
| localization | `slang` (ARB-based, generated) | Add locale strings under `lib/i18n/`; re-run `flutter pub run slang` after edits; settings page is already localized |

> **Routing:** `auto_route` 11 is brick-provided and supports deep link parsing via
> `deepLinkBuilder`. Wire additional routes in `lib/router/app_router.dart`.

> **State management:** Riverpod 3 (`flutter_riverpod` + `riverpod_annotation`) is
> the default. Use `testNotifier` from `test/helpers/notifier_tester.dart` for
> notifier unit tests — it handles `ProviderContainer` setup and override wiring.

---

## Add-on ingredients (not in the brick)

These ingredients are NOT shipped by the brick and must be added per the plan
produced by `/flutter-app-planner`. Each links to its catalog entry for setup
notes and package references.

- **[analytics](ingredient-catalog.md#analytics)** — add `firebase_analytics` + `FirebaseAnalyticsObserver` to the auto_route router; follow `analytics-events.md` taxonomy.
- **[ci-cd](ingredient-catalog.md#ci-cd)** — create a GitHub Actions workflow (or Codemagic pipeline) with analyze → test → build gates; store signing secrets in CI secrets.
- **[automated-testing](ingredient-catalog.md#automated-testing)** — the brick provides `testNotifier` but test files themselves are per-feature; use `mocktail` for mocking.
- **[store-readiness](ingredient-catalog.md#store-readiness)** — set bundle ID, configure `flutter_launcher_icons` + `flutter_native_splash`, fill store metadata; the brick does not generate these.
- **[privacy-basics](ingredient-catalog.md#privacy-basics)** — add `app_tracking_transparency` (iOS ATT), host a privacy policy URL, fill App Store Privacy labels and Play Data Safety.
- **[authentication](ingredient-catalog.md#authentication)** — add `firebase_auth`; set Crashlytics user identifier after login; clear secure storage on logout.
- **[onboarding](ingredient-catalog.md#onboarding)** — custom screens; gate completion flag in secure storage; skip on re-launch.
- **[deep-links](ingredient-catalog.md#deep-links)** — add `app_links`; configure Universal Links / App Links on your web domain; wire into `auto_route`'s deep link handler.
- **[remote-config](ingredient-catalog.md#remote-config)** — add `firebase_remote_config`; define a `FeatureFlags` provider with local defaults.
- **[performance-monitoring](ingredient-catalog.md#performance-monitoring)** — add `firebase_performance`; add `DioFirebasePerformanceInterceptor` if using Dio.
- **[payments-revenuecat](ingredient-catalog.md#payments-revenuecat)** — add `purchases_flutter`; configure in `bootstrap.dart` after auth; implement restore purchases.
- **[payments-cashfree](ingredient-catalog.md#payments-cashfree)** — add `flutter_cashfree_pg_sdk`; requires a server for order creation and webhook verification.
- **[push-notifications](ingredient-catalog.md#push-notifications)** — add `firebase_messaging` + `flutter_local_notifications`; configure APNs (iOS) and handle all three message states.
- **[offline-support](ingredient-catalog.md#offline-support)** — add `connectivity_plus`; use `hive_ce` (already in brick) for the local write queue.
- **[cloud-sync](ingredient-catalog.md#cloud-sync)** — add Firestore (`cloud_firestore`) or Supabase; tie sync status to auth state.
- **[feature-flags](ingredient-catalog.md#feature-flags)** — build on `remote-config`; define a `FeatureFlags` class with Riverpod provider.
- **[referral-system](ingredient-catalog.md#referral-system)** — requires `deep-links`; use Branch.io or a custom short-link service; attribution logic lives on your server.
- **[ai-integration](ingredient-catalog.md#ai-integration)** — proxy all LLM calls through your server; add `rate-limiting` on the server; never put API keys in the Flutter app.
- **[experimentation-ab](ingredient-catalog.md#experimentation-ab)** — build on `remote-config` + `analytics`; use Firebase A/B Testing in the console.
- **[ads](ingredient-catalog.md#ads)** — add `google_mobile_ads`; add AdMob App ID to `AndroidManifest.xml` and `Info.plist`; request ATT before showing personalized ads.
- **[admin-panel-cms](ingredient-catalog.md#admin-panel-cms)** — separate app / separate bundle ID; use Retool for MVP, custom Flutter Web app if needed.
- **[rate-limiting](ingredient-catalog.md#rate-limiting)** — server-side only (Redis / Cloud Functions); implement at API gateway level.
- **[background-jobs](ingredient-catalog.md#background-jobs)** — add `workmanager` (Android) or register `BGTaskScheduler` modes (iOS); test on real hardware.
- **[security-hardening-advanced](ingredient-catalog.md#security-hardening-advanced)** — always use `--obfuscate --split-debug-info` for release builds (free baseline); add cert pinning only if your threat model requires it.

---

## Template improvement recommendations

The brick is already well-structured. The following are concrete suggestions for
future template iterations that would reduce the friction of adding common add-on
ingredients:

1. **Analytics abstraction interface.** The brick ships a `CrashReporter` abstraction (mirroring the Crashlytics service). Adding a parallel `AnalyticsReporter` interface with a `NoOpAnalyticsReporter` default would let apps plug in `firebase_analytics`, PostHog, or Mixpanel without changing call sites — the same pattern already used for crash reporting.

2. **CI workflow template.** Include a `.github/workflows/ci.yml` (or `codemagic.yaml`) stub in the brick's `__brick__` directory. Even a minimal `flutter analyze && flutter test` workflow eliminates a common copy-paste task for every new project.

3. **Feature-flag / remote-config seam.** Add a `FeatureFlags` class with a `LocalFeatureFlags` implementation (all flags return compile-time defaults) alongside the existing service abstractions. Teams can drop in `FirebaseRemoteConfigFlags` without changing any call site — and the local implementation makes testing trivial.

4. **Analytics observer pre-wired.** The brick wires `TalkerRiverpodObserver` into `ProviderScope` and the router. Wiring a `NullRouteObserver` slot for analytics (a no-op `NavigatorObserver`) would mean adding Firebase Analytics is a one-line swap, not a refactor of the router setup.

5. **`flutter_launcher_icons` + `flutter_native_splash` configuration stubs.** Adding commented-out config blocks in `pubspec.yaml` with placeholder values and instructions would reduce the friction of the first icon/splash setup for every generated app.

6. **Separate `dev` / `staging` / `production` Firebase projects.** The `setup_firebase.sh` script currently configures one Firebase project. A multi-environment variant (with `--dart-define=FLAVOR=dev/prod` support) would prevent dev crash reports and analytics from polluting the production dashboard.
