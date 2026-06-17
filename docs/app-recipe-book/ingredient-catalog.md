# Ingredient Catalog

> Every ingredient Claude may select for a new app. One entry per ingredient.
> Tiers: must-have · recommended · optional · avoid-unless-needed.
> "Brick-provided" means the riverpod_simple_architecture brick already ships it.

---

## crash-reporting
**Classification:** must-have  ·  **Brick-provided:** yes (Firebase Crashlytics + `wireCrashHandlers`)

- **Why it matters:** Production crashes are invisible without a crash reporter. Crashlytics captures stack traces, device metadata, and custom keys so you can reproduce and fix issues your users experience but never report. The first hour after a release is the most critical — without this you are flying blind.
- **When to include:** Always. Every production app shipped to real users needs crash reporting from day one. There is no tier of app small enough to skip it.
- **When NOT to:** You can defer setup during early prototyping / internal testing phases, but enable it before any external beta or store submission.
- **Suggested package/service:** `firebase_crashlytics` (default); alt `sentry_flutter` (Sentry) if you prefer a non-Firebase stack.
- **Setup notes:** The brick ships Firebase Crashlytics and a `wireCrashHandlers()` call in `bootstrap.dart` that routes both Flutter framework errors and Dart zone errors to Crashlytics. Run `bash tool/setup_firebase.sh` (repo root) to configure FlutterFire CLI, add `google-services.json` / `GoogleService-Info.plist`, and apply the Gradle plugin patcher. No additional wiring required after that script.
- **Common mistakes:** (1) Forgetting to call `wireCrashHandlers()` before `runApp` — the brick handles this, but manual projects often skip it. (2) Not uploading dSYMs for iOS release builds, leading to symbolication failures. (3) Running Crashlytics in debug mode and polluting the dashboard with dev noise — wrap `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)`.

---

## analytics
**Classification:** must-have  ·  **Brick-provided:** no

- **Why it matters:** Without analytics you make product decisions based on gut feel. Analytics tells you which features are used, where users drop off, what your retention curve looks like, and whether a new release made things better or worse.
- **When to include:** Every app that has real users. Even a simple utility should track active users and core action counts so you know whether the app is alive.
- **When NOT to:** Internal tools used by a known, small group with no growth ambition. Also skip personalized analytics for apps targeting minors (COPPA/GDPR implications).
- **Suggested package/service:** `firebase_analytics` (default, free, integrates with Crashlytics and Remote Config); alt PostHog (`posthog_flutter` — open source, self-hostable); alt Mixpanel / Amplitude for product-analytics depth.
- **Setup notes:** Initialize `FirebaseAnalytics` in `bootstrap.dart` after `Firebase.initializeApp()`. Add `FirebaseAnalyticsObserver` to your `auto_route` router observers. Follow the event taxonomy in `analytics-events.md` — define constants for all event names to avoid typos.
- **Common mistakes:** (1) Tracking PII (email, name, phone) directly in event params — use anonymized IDs only. (2) Not setting `userId` after login, making user-level funnels useless. (3) Logging every micro-interaction (scroll, tap) without a clear question you are answering — leads to data bloat and noise.

---

## ci-cd
**Classification:** must-have  ·  **Brick-provided:** no

- **Why it matters:** Manual builds and manual store uploads break down the first time a team member is sick or in a hurry. CI/CD enforces quality gates (analyze, test, build) on every PR and automates the mechanical parts of shipping — build, sign, upload to TestFlight / Play internal track.
- **When to include:** From the first PR, even solo. The cost of setting it up early is trivial; the cost of bolting it on after six months of accumulated technical debt is not.
- **When NOT to:** Pure research/throwaway prototypes that will never be submitted to a store.
- **Suggested package/service:** GitHub Actions (free tier sufficient for most Flutter projects); alt Codemagic (managed, strong Flutter support); alt Fastlane for local automation lanes.
- **Setup notes:** Minimum pipeline: `flutter analyze`, `flutter test`, `flutter build apk --no-codesign` (or `flutter build ios --no-codesign`) on every PR. Signing and upload lanes can be added incrementally. Store secrets (keystore, API keys, App Store Connect key) in GitHub Actions secrets — never in the repo.
- **Common mistakes:** (1) Committing signing keystores or `key.properties` to git — use secrets. (2) Only running CI on `main` instead of all PRs, so regressions slip through. (3) Not caching Flutter/Dart pub dependencies, making builds unnecessarily slow.

---

## automated-testing
**Classification:** must-have  ·  **Brick-provided:** no (but brick provides `test/helpers/notifier_tester.dart` with `testNotifier`)

- **Why it matters:** Automated tests are the only sustainable way to refactor and add features without fear of regressions. They also serve as living documentation of intended behavior. Without them, every release is a manual regression run.
- **When to include:** Always. Start with unit tests for business logic (notifiers) on day one. Add widget tests for key screens. Integration tests come later as the app stabilizes.
- **When NOT to:** Do not write tests for generated code (`*.g.dart`, `router.gr.dart`, `*.freezed.dart`) — these are artefacts of code generation and test the generator, not your logic.
- **Suggested package/service:** `flutter_test` (built-in); `mocktail` for mocking; `patrol` for integration/E2E. The brick's `testNotifier` helper from `test/helpers/notifier_tester.dart` handles Riverpod notifier testing with minimal boilerplate.
- **Setup notes:** Use `testNotifier` from the brick's test helper to test all Riverpod `AsyncNotifier` / `Notifier` classes. Group tests by feature. Run `flutter test --coverage` in CI and consider a coverage gate (e.g., 70% on business-logic files).
- **Common mistakes:** (1) Testing implementation details (internal state) instead of observable outputs. (2) Not mocking network/storage in unit tests, making them slow and flaky. (3) Writing zero tests, then writing hundreds of brittle snapshot tests at once — build the habit incrementally.

---

## store-readiness
**Classification:** must-have  ·  **Brick-provided:** no

- **Why it matters:** App stores have specific technical requirements (icon sizes, bundle IDs, build settings, entitlements) that are distinct from product quality. Failing a store review for a technical reason after weeks of development is painful and avoidable.
- **When to include:** Set up correctly from day one — bundle ID, version scheme, signing, icons, and splash screen. Do not defer until release week.
- **When NOT to:** Internal enterprise distribution via MDM (different signing path, no public store submission).
- **Suggested package/service:** `flutter_launcher_icons` + `flutter_native_splash` for assets; `fastlane deliver` / `fastlane supply` for metadata automation; App Store Connect / Google Play Console for manual submission.
- **Setup notes:** Use a consistent `com.company.appname` bundle ID everywhere (Xcode, `build.gradle`, Firebase). Version scheme: `major.minor.patch+buildNumber`. Generate all icon sizes from a single 1024×1024 source. Fill all store metadata (title, subtitle, description, keywords, screenshots for every required device size) before first submission.
- **Common mistakes:** (1) Using a placeholder bundle ID that conflicts with another app. (2) Forgetting to set `NSUserTrackingUsageDescription` (iOS) or Data Safety declaration (Android) before submission — instant rejection. (3) Submitting with a debug build or with test credentials visible in screenshots.

---

## privacy-basics
**Classification:** must-have  ·  **Brick-provided:** no

- **Why it matters:** Privacy regulations (GDPR, CCPA, PDPB/India) require a compliant privacy policy, informed consent for data collection, and data deletion capabilities. Non-compliance risks store rejection, fines, and user trust loss. Both app stores now require privacy labels / data safety declarations.
- **When to include:** Every app that collects any personal data — and most apps do (analytics, crash logs, IP addresses).
- **When NOT to:** Fully local, no-network apps with no analytics and no accounts can minimize this, but still need a basic privacy policy if submitted to stores.
- **Suggested package/service:** Privacy policy: use a hosted URL (iubenda, Termly, or self-hosted). ATT prompt (iOS 14.5+): `app_tracking_transparency` package. GDPR consent for ads: Google UMP SDK (`google_mobile_ads` includes it).
- **Setup notes:** Host your privacy policy at a stable URL (store it in the brick's `privacy_url` build var). Add `NSUserTrackingUsageDescription` to `Info.plist` for iOS. Fill Google Play Data Safety and App Store Privacy Nutrition labels accurately — mismatches between declared and actual data collection trigger rejections.
- **Common mistakes:** (1) Copy-pasting a generic privacy policy that doesn't match what the app actually collects. (2) Not requesting ATT before initializing advertising SDKs on iOS. (3) Forgetting to provide a data deletion mechanism — required for apps with accounts in most jurisdictions.

---

## secure-storage
**Classification:** must-have  ·  **Brick-provided:** yes (`flutter_secure_storage` 10, Android minSdk 23)

- **Why it matters:** Tokens, API keys, and user credentials stored in `SharedPreferences` / `NSUserDefaults` are readable by other apps on rooted/jailbroken devices and visible in backups. `flutter_secure_storage` uses the iOS Keychain and Android Keystore — hardware-backed on modern devices.
- **When to include:** Any time you store an auth token, refresh token, API key, or any sensitive user credential. This is the default for all such data.
- **When NOT to:** Non-sensitive preferences (theme choice, onboarding completion flag) do not need secure storage — use `shared_preferences` for those.
- **Suggested package/service:** `flutter_secure_storage` 10 (brick-provided). No alternative needed — it is the Flutter standard.
- **Setup notes:** The brick ships this. Android `minSdk` is set to 23 (`AndroidKeyStore` requires it). Use the storage service abstraction the brick provides rather than calling `FlutterSecureStorage` directly — it makes mocking in tests trivial. Clear all secure storage on logout.
- **Common mistakes:** (1) Storing JWTs in `SharedPreferences` — use `flutter_secure_storage`. (2) Not clearing storage on logout, leaving stale tokens that can be replayed. (3) Forgetting that secure storage is not encrypted on Android below API 23, which is why the brick enforces `minSdk 23`.

---

## observability-talker
**Classification:** must-have  ·  **Brick-provided:** yes (talker logging, bootstrap-wired)

- **Why it matters:** `print()` statements vanish in production. A structured logger (talker) lets you control log levels, route logs to different outputs (console, file, remote), and filter noise. In production, talker feeds Crashlytics custom logs so you have breadcrumbs leading up to a crash.
- **When to include:** Always. The brick wires it in bootstrap — there is zero setup cost.
- **When NOT to:** There is no reason to remove it. Disable verbose levels in production via talker's log-level configuration.
- **Suggested package/service:** `talker_flutter` + `talker_riverpod_logger` (brick-provided). Optional: `talker_dio_logger` if you add Dio for HTTP.
- **Setup notes:** The brick instantiates `Talker` in `bootstrap.dart` and passes it to `ProviderScope`'s `observers` via `TalkerRiverpodObserver`. Configure log levels per environment: `verbose`/`debug` in development, `warning`/`error` in production. Attach to `FirebaseCrashlytics` as a custom log handler so breadcrumbs appear in crash reports.
- **Common mistakes:** (1) Using `print()` in new code after the logger is available — use `talker.debug()` / `talker.error()` consistently. (2) Logging sensitive data (tokens, PII) at any level — log IDs and codes only. (3) Not suppressing verbose logs in production builds, polluting crash reports with noise.

---

## theming-settings
**Classification:** must-have  ·  **Brick-provided:** yes (`flex_color_scheme` 8 + SettingsPage/AboutSection on `/settings` route)

- **Why it matters:** Users expect light/dark mode and accessible typography. A settings page provides a home for theme toggle, language selection, about/legal links, and privacy policy URL — all required before store submission. Starting with a proper theming system avoids a painful migration later.
- **When to include:** Always. The brick provides this at zero cost.
- **When NOT to:** There is no reason to remove it. You may extend or replace the default color scheme, but the infrastructure should stay.
- **Suggested package/service:** `flex_color_scheme` 8 (brick-provided). For advanced dynamic theming: `dynamic_color` to follow Material You on Android.
- **Setup notes:** The brick ships `SettingsPage` at route `/settings` with an `AboutSection` that shows the app version (from `package_info_plus`), privacy policy URL, and licenses. To customize: add new `ListTile` entries to `SettingsPage`, adjust the `FlexColorScheme` seed color in `app_theme.dart`. Localization strings for settings are in the slang ARB files.
- **Common mistakes:** (1) Hard-coding colors throughout the app instead of using `Theme.of(context)` — makes dark-mode support extremely painful. (2) Not wiring the theme toggle to persisted state (the brick uses `flutter_secure_storage` for settings persistence). (3) Skipping the `AboutSection` privacy policy URL, causing store review failure.

---

## authentication
**Classification:** recommended  ·  **Brick-provided:** no

- **Why it matters:** User accounts enable personalized experiences, cross-device sync, subscription entitlements, and the ability to restore data after a reinstall. Without auth, you cannot associate data with a user across sessions or devices.
- **When to include:** Any app with cloud sync, subscriptions, social features, or content personalization. Include it early — retrofitting auth into an app built around anonymous local state is painful.
- **When NOT to:** Local-only utility apps with no cloud features, no subscriptions, and no user-specific data. Adding auth to a calculator or a unit converter creates friction with no benefit.
- **Suggested package/service:** `firebase_auth` (default — integrates with Firestore, Crashlytics user ID, RevenueCat); alt `supabase_flutter` auth for Supabase backends; alt `appwrite` for self-hosted.
- **Setup notes:** Use Firebase Auth with at minimum email/password + Google Sign-In. Set `FirebaseCrashlytics.instance.setUserIdentifier(uid)` after login so crash reports are linkable to users (UID only, not email). Store the auth token in `flutter_secure_storage` (brick-provided). Implement a proper logout that clears secure storage, Riverpod state, and Crashlytics user ID.
- **Common mistakes:** (1) Not handling token expiry — use Firebase Auth's `authStateChanges()` stream rather than caching the token manually. (2) Not clearing user state on sign-out, causing stale data bleed between accounts. (3) Gating all app value behind auth for apps where most features could be anonymous — leads to high drop-off at the auth wall.

---

## onboarding
**Classification:** recommended  ·  **Brick-provided:** no

- **Why it matters:** Users who don't understand your app's core value prop within the first 30 seconds churn. Onboarding is the bridge between install and first meaningful action ("aha moment"). It also handles permissions requests at the right moment and reduces support load.
- **When to include:** Any app where the primary value is not immediately obvious from the UI, or where you need permissions (notifications, camera, location) that benefit from a rationale screen shown before the system prompt.
- **When NOT to:** Trivially obvious utilities (a flashlight, a timer). Forced multi-step onboarding on a simple tool creates friction and increases churn.
- **Suggested package/service:** Custom implementation (onboarding is UI, not a package concern). `introduction_screen` or `smooth_page_indicator` for paginated flows. `permission_handler` for permission rationale screens.
- **Setup notes:** Gate completion behind a flag stored in `flutter_secure_storage` or `SharedPreferences`. Skip onboarding on subsequent launches. Deep-link handling (if included) should bypass onboarding for users arriving via a link. Track `onboarding_completed` event in analytics.
- **Common mistakes:** (1) Requesting all permissions on the first screen before any context — users deny them. (2) Making onboarding unskippable for users who already know the app (e.g., reinstallers). (3) Onboarding that is pure marketing copy with no actionable first step — users skip it entirely.

---

## deep-links
**Classification:** recommended  ·  **Brick-provided:** no

- **Why it matters:** Deep links allow external surfaces (emails, push notifications, social shares, web pages) to open a specific screen in your app. Without them, every notification or share just opens the app home screen, losing context. Required for referral flows, content sharing, and payment return URLs.
- **When to include:** Any app with push notifications, share functionality, referrals, email campaigns, or web presence. Also required for OAuth redirect flows (Google Sign-In, Cashfree payment return).
- **When NOT to:** Purely local apps with no external integrations, no sharing, and no marketing communications.
- **Suggested package/service:** `app_links` (maintained successor to `uni_links`). Universal Links (iOS) + App Links (Android) for production — they work without the app installed fallback to web. `auto_route` (brick-provided) handles deep link route parsing natively.
- **Setup notes:** Configure `auto_route`'s `deepLinkBuilder` or use `app_links` to receive the URI and navigate. Add Associated Domains entitlement (iOS) and `assetlinks.json` (Android) to your web domain. Test both cold-start and warm-start deep link scenarios.
- **Common mistakes:** (1) Using only custom scheme links (`myapp://`) instead of universal/app links — they don't work when the app is not installed. (2) Not handling the deep link on cold start (app not running) — check initial URI in `main.dart`. (3) Not verifying `assetlinks.json` / `apple-app-site-association` is accessible at the domain root.

---

## remote-config
**Classification:** recommended  ·  **Brick-provided:** no

- **Why it matters:** Remote Config lets you change app behavior without a store release — toggle features, adjust copy, update limits, run experiments. It is the safety valve between releases and the foundation for feature flags and A/B testing.
- **When to include:** Any app where you want to iterate on behavior without waiting for store review. Particularly valuable for content-heavy apps, subscription apps where pricing may change, and AI apps where model parameters need tuning.
- **When NOT to:** Very early MVP with a single developer and no A/B testing needs. Don't add it just to add it — it has a non-trivial setup and mental overhead.
- **Suggested package/service:** `firebase_remote_config` (default — free, integrates with Firebase Analytics for conditional targeting); alt LaunchDarkly / Statsig for enterprise feature-flag needs.
- **Setup notes:** Define all config keys with safe defaults in the Firebase Console AND in your Dart constants (so the app works if Remote Config is unreachable). Fetch and activate on app start with a short timeout (`fetchAndActivate()` with `minimumFetchInterval` of 1 hour in production, 0 in debug). Never make Remote Config a blocking call on the critical path.
- **Common mistakes:** (1) Using Remote Config as a content management system for large payloads — it's for small config values, not JSON documents. (2) No local defaults, so the app fails on first launch without network. (3) Forgetting to activate after fetch — `fetchAndActivate()` does both atomically; separate `fetch()` + `activate()` is error-prone.

---

## performance-monitoring
**Classification:** recommended  ·  **Brick-provided:** no

- **Why it matters:** Crashes captured by Crashlytics tell you when the app dies. Performance monitoring tells you when it is slow, janky, or making too many network calls. Firebase Performance tracks app start time, HTTP response times, and custom traces — all without writing much code.
- **When to include:** Apps with network-heavy screens, complex rendering (feeds, lists with images), or startup time sensitivity. Content/feed apps especially benefit.
- **When NOT to:** Simple local utility apps with no network calls and minimal rendering complexity. The overhead is minimal but so is the value.
- **Suggested package/service:** `firebase_performance` (default — automatic HTTP monitoring + app start tracing); alt `datadog_flutter_plugin` for Datadog APM if you are already on Datadog.
- **Setup notes:** Initialize in `bootstrap.dart`. The Dart plugin automatically instruments network calls made via `dio` when you add the `DioFirebasePerformanceInterceptor`. Add custom `Trace` objects around expensive operations (e.g., heavy local computations, large Hive reads). Check the Firebase Console's Performance dashboard after a release.
- **Common mistakes:** (1) Not adding the HTTP monitoring interceptor — you only get app start data, not the most valuable network latency data. (2) Creating custom traces with generic names (`trace1`) that are meaningless in the dashboard. (3) Assuming `firebase_performance` replaces profiling in DevTools — it captures real-world averages, not root-cause frame issues.

---

## local-database
**Classification:** recommended  ·  **Brick-provided:** yes (hive_ce)

- **Why it matters:** A local database enables offline access, fast reads without network round-trips, and caching that survives app restarts. For productivity and note-taking apps it is the primary data store; for network-first apps it is the cache layer.
- **When to include:** Any app with offline support, complex local state that survives restarts, or significant read-heavy data (feed cache, user content). Strongly recommended for productivity/notes app type.
- **When NOT to:** Purely real-time apps where stale local data causes confusion (e.g., a collaborative live document editor). Also avoid if data complexity (relations, complex queries) exceeds what a key-value or simple box store handles — use `drift` (SQLite) instead.
- **Suggested package/service:** `hive_ce` (brick-provided — fast, pure Dart, no native dependency); alt `drift` for relational/SQL needs; alt `isar` for indexed queries on large datasets.
- **Setup notes:** The brick initializes Hive in `bootstrap.dart`. Define your `HiveObject` models and register adapters before `runApp`. For sensitive data, encrypt the Hive box using `HiveAesCipher` with a key stored in `flutter_secure_storage`. Do not put large binary blobs in Hive — store file paths instead.
- **Common mistakes:** (1) Storing large images or files as bytes in Hive — use the filesystem and store the path. (2) Not registering a type adapter before opening a box — causes `HiveError` at runtime. (3) Using Hive for relational data with complex queries — the query API is limited; use `drift` for those cases.

---

## payments-revenuecat
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** App Store and Google Play require that digital goods and subscriptions sold within an app use store IAP — using a third-party gateway for digital content is a policy violation and grounds for app removal. RevenueCat abstracts both stores' IAP APIs into one SDK and handles receipt validation, entitlement management, and subscription status server-side.
- **When to include:** Any app selling digital subscriptions, one-time unlocks, or consumable in-app purchases. This is the only compliant path for digital goods in consumer apps.
- **When NOT to:** Physical goods, real-world services, and business-to-business invoicing — store IAP does not apply to those (and would be rejected by stores). For India direct payments use `payments-cashfree` instead.
- **Suggested package/service:** `purchases_flutter` (RevenueCat's official Flutter SDK). RevenueCat backend handles receipt validation — no server required for basic flows.
- **Setup notes:** Initialize `Purchases.configure(PurchasesConfiguration(apiKey))` in `bootstrap.dart` after auth (set `appUserId` to your Firebase UID so entitlements follow the user). Define products in App Store Connect and Google Play Console first. Use RevenueCat's Paywalls or build a custom paywall that calls `Purchases.purchasePackage()`. Always implement restore purchases — required by store guidelines.
- **Common mistakes:** (1) Not implementing restore purchases — leads to app rejection. (2) Confirming entitlements on the client without checking `CustomerInfo` from RevenueCat — a cancelled subscription can still appear active locally. (3) Sandbox testing with production API keys, polluting your subscription data.

---

## payments-cashfree
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** For Indian-market apps selling real-world goods or services, Cashfree is a compliant, widely-supported payment gateway. Unlike RevenueCat, this path is for transactions that should NOT go through the app store (physical goods, services, B2B, food delivery, etc.). Server-side order creation and webhook verification are mandatory — never trust the client to confirm payment.
- **When to include:** Indian-market apps with real-world commerce where store IAP rules do not apply. Also used for direct B2B payments, utility bill payments, and marketplace payouts.
- **When NOT to:** Digital in-app goods or subscriptions — use `payments-revenuecat` for those. Cashfree for digital content would violate App Store / Play Store policies.
- **Suggested package/service:** `flutter_cashfree_pg_sdk` (client-side SDK for payment collection). A server is required to: create the order via Cashfree's Orders API, receive and verify the payment webhook, and fulfill the transaction server-side.
- **Setup notes:** Flow: (1) User initiates payment → your server creates a Cashfree order and returns `payment_session_id`. (2) Flutter SDK calls `CFPaymentGatewayService.doPayment()` with the session ID. (3) Cashfree calls your server webhook on payment success/failure. (4) Your server verifies the webhook signature, then fulfills the order. Never fulfill based on the client callback alone — it can be spoofed. Store Cashfree API keys server-side only.
- **Common mistakes:** (1) Fulfilling orders based on the client-side success callback — always wait for and verify the server webhook. (2) Storing Cashfree API secret in the Flutter app — it must live on your server. (3) Not testing the webhook failure/retry path — Cashfree retries webhooks; your server must be idempotent.

---

## push-notifications
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Push notifications are the primary re-engagement tool for mobile apps. They drive users back to the app for time-sensitive content, social activity, order updates, and reminders. Without them, retention is almost entirely organic.
- **When to include:** Apps with time-sensitive content (news, sports, chats), user-triggered activity feeds (social, collaboration), transactional events (orders, payments), or scheduled reminders.
- **When NOT to:** Utility apps where the user opens the app on demand and doesn't benefit from interruptions. Overusing push kills retention — only include if you have a genuine reason to interrupt the user.
- **Suggested package/service:** `firebase_messaging` (FCM — free, cross-platform, integrates with Firebase backend); `flutter_local_notifications` for local scheduling and notification display customization.
- **Setup notes:** Add `FirebaseMessaging.instance.requestPermission()` at an appropriate moment (not on first launch — after the user understands the value). Handle foreground, background, and terminated-state messages separately. Store the FCM token in your backend tied to the user ID. On iOS, APNs setup is required (provisioning profile with Push Notifications entitlement).
- **Common mistakes:** (1) Requesting notification permission on first app open before the user understands the value — leads to high deny rates. (2) Not handling notification tap when the app is terminated (check `FirebaseMessaging.instance.getInitialMessage()`). (3) Not refreshing the FCM token on `onTokenRefresh` — stale tokens cause silent delivery failures.

---

## offline-support
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Mobile networks are unreliable. Offline support means users can continue working (or at least reading) when connectivity drops. For productivity apps, offline is a differentiator; for content apps, it prevents blank-screen frustration.
- **When to include:** Productivity/notes apps where data creation is the core loop, content apps where pre-fetching improves experience, and any app used in areas with poor connectivity (travel, field work).
- **When NOT to:** Real-time collaborative apps where offline edits create unresolvable conflicts, or purely transactional apps (payment kiosks) where offline state is inherently invalid.
- **Suggested package/service:** `connectivity_plus` for network state monitoring; `hive_ce` (brick-provided) or `drift` for local data; custom sync queue (Riverpod `AsyncNotifier`) for pending operations.
- **Setup notes:** Use `connectivity_plus` to detect connectivity changes and expose a stream to a Riverpod provider. Queue writes in `hive_ce` when offline; flush the queue when connectivity returns. Surface offline state clearly in the UI (a banner or indicator). Test with Airplane Mode — not just simulated slow network.
- **Common mistakes:** (1) No UI indicator that the app is offline — users think it's broken. (2) Not handling the case where offline writes conflict with server state on reconnect. (3) Assuming `connectivity_plus` returning "connected" means the network is functional — check with a real request before assuming internet access.

---

## cloud-sync
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Cloud sync lets users switch devices, reinstall the app, or share data across platforms without losing their work. It is the bridge between local-first (hive_ce) and multi-device access. Essential for productivity apps with paying users.
- **When to include:** Productivity apps with subscription tiers, any app where user-generated content is valuable and irreplaceable, and apps with web counterparts.
- **When NOT to:** Apps where data is inherently device-local (a device-health monitor), apps targeting offline-only markets, or MVP phases where the complexity is not justified.
- **Suggested package/service:** Firestore (Firebase) for real-time sync with conflict-free reads; Supabase Postgres for relational sync; custom REST API with optimistic UI for full control.
- **Setup notes:** Use Firestore's `snapshots()` stream to keep local Riverpod state in sync. For complex conflict resolution (simultaneous offline edits), implement last-write-wins or a CRDT approach. Tie sync to auth — users must be signed in. Display sync status (syncing / synced / error) in the UI.
- **Common mistakes:** (1) Syncing on every keystroke — debounce writes to avoid excessive Firestore calls and costs. (2) Not handling partial sync failures — use Firestore transactions for atomic multi-document updates. (3) No sync status indicator — users don't know if their data is saved.

---

## feature-flags
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Feature flags let you ship code to production in a disabled state and enable it gradually or roll it back instantly without a store release. They decouple deployment from release and are essential for safe progressive rollouts, beta testing with a subset of users, and kill-switches for unstable features.
- **When to include:** Teams shipping frequently, apps with high-risk features (payments, AI), or anywhere you want to de-risk a release with a gradual rollout.
- **When NOT to:** Single-developer apps with simple, well-tested features and low release risk. Don't add the complexity unless you genuinely need the rollout control.
- **Suggested package/service:** `firebase_remote_config` (simple boolean flags, free, sufficient for most apps); alt LaunchDarkly / Statsig for advanced targeting, experiments, and analytics integration.
- **Setup notes:** Define a `FeatureFlags` class that reads from Remote Config with sensible local defaults. Gate new features behind `if (featureFlags.isNewCheckoutEnabled)` checks. Wire to a Riverpod provider so the entire UI tree reacts when flags update. Remove the flag and its guard once the feature is fully rolled out — flag debt is real.
- **Common mistakes:** (1) Shipping flags without local defaults — the app breaks if Remote Config is unreachable. (2) Never cleaning up old flags — the codebase accumulates dead branches. (3) Using feature flags for permanent configuration (e.g., enabling/disabling paid features) — that's entitlement management, not feature flags.

---

## referral-system
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Referrals are one of the highest-ROI growth channels for consumer apps. A referral system converts happy users into growth drivers, often with a cost-per-acquisition far below paid channels. Dynamic links allow referrers to be credited even when the referred user installs fresh.
- **When to include:** Consumer apps with network effects, subscription products where the LTV justifies an incentive, and apps targeting growth phase with viral potential.
- **When NOT to:** B2B / enterprise apps (referrals rarely work), utility apps where users don't naturally talk about the app, or pre-PMF apps where you need to understand retention before optimizing acquisition.
- **Suggested package/service:** Firebase Dynamic Links (deprecated — migrate to custom deep links + `app_links`); Branch.io (`flutter_branch_sdk`) for attribution-grade referral tracking; or a custom short-link service if you control the backend.
- **Setup notes:** Pair with `deep-links` — the referral link must deep-link into the app. Track `referral_link_created` and `referral_converted` events in analytics. The reward logic (credit, discount) lives on your backend to prevent manipulation. Test the full attribution loop: generate link → share → fresh install → referrer credited.
- **Common mistakes:** (1) Implementing referral logic on the client only — trivially gameable. (2) Not testing the fresh-install path (the new user doesn't have the app yet). (3) Building referrals before you have retention — if existing users churn, referred users will too.

---

## ai-integration
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** AI features (text generation, summarization, image analysis, voice interaction) are increasingly a core product differentiator. Flutter apps can call LLM APIs directly from the client or via a server proxy for cost control and rate limiting.
- **When to include:** Apps where AI is a core value proposition (writing assistant, code helper, smart search, personalized recommendations) or a meaningful productivity enhancer.
- **When NOT to:** Apps where AI is a gimmick bolted onto an otherwise complete feature set. AI adds cost, latency, and complexity — only include it if it genuinely solves a user problem better than a non-AI approach.
- **Suggested package/service:** `anthropic_sdk_dart` / `dart_anthropic` for Claude (server-proxy recommended); `dart_openai` for OpenAI; `google_generative_ai` for Gemini (direct client call supported). For on-device: `flutter_gemma` (Gemma 2B on-device).
- **Setup notes:** Never put LLM API keys in the Flutter app — proxy all calls through your server. Implement rate limiting and cost guards server-side (`rate-limiting` ingredient). Use streaming responses (`SSE`) for a better UX on longer outputs. Track token usage and cost per user. Add the `rate-limiting` ingredient whenever you add `ai-integration`.
- **Common mistakes:** (1) Putting the API key in the Flutter app — it will be extracted and abused. (2) No loading/streaming indicator for LLM responses — users think the app froze. (3) No cost guard or per-user rate limit — a few heavy users can run up a large bill overnight.

---

## experimentation-ab
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** A/B testing lets you make product decisions based on data rather than opinion. Even small experiments (button copy, onboarding flow, paywall layout) can yield double-digit conversion improvements. Without A/B testing infrastructure, every product decision is a guess.
- **When to include:** Apps with sufficient traffic to reach statistical significance (generally 1,000+ DAU per variant), a clear North Star metric, and a team that will act on results.
- **When NOT to:** Pre-scale apps with < 1,000 DAU — you won't reach significance and the infrastructure complexity isn't worth it. Also avoid during early product discovery where the hypothesis space is still too broad.
- **Suggested package/service:** Firebase A/B Testing (integrates with Remote Config and Analytics — free); alt Statsig / Optimizely for advanced experiment management.
- **Setup notes:** Firebase A/B Testing wraps Remote Config experiments. Define the experiment in the Firebase Console, set variants via Remote Config keys, and define the goal metric (a Firebase Analytics event). Ensure you are not running too many simultaneous experiments — overlapping experiments contaminate results.
- **Common mistakes:** (1) Ending experiments early when you see a promising result — wait for significance. (2) Running experiments that change too many variables at once. (3) Not tracking the secondary metrics alongside the primary — a higher conversion with lower retention is not a win.

---

## ads
**Classification:** optional  ·  **Brick-provided:** no

- **Why it matters:** Ads are a viable monetization strategy for free utility and content apps with volume. AdMob provides banner, interstitial, rewarded, and native ad formats. However, poorly implemented ads destroy user experience and app store ratings — the implementation quality matters as much as the revenue potential.
- **When to include:** Free apps with sufficient DAU where the content/utility warrants monetization but a paywall would cause excessive churn. Rewarded ads in games/utilities can add value without friction.
- **When NOT to:** Premium / paid apps, apps where ads would conflict with brand perception (enterprise, health, finance), or apps with low enough DAU that ad revenue is negligible but UX cost is real.
- **Suggested package/service:** `google_mobile_ads` (AdMob — dominant in Flutter ecosystem); alt `facebook_audience_network` for Facebook Audience Network.
- **Setup notes:** Register the app in AdMob and add the App ID to `AndroidManifest.xml` and `Info.plist` before submitting to stores — missing this causes crashes on launch. Request ATT permission (iOS 14.5+) before showing personalized ads via the Google UMP SDK (`privacy-basics` dependency). Use test ad unit IDs during development.
- **Common mistakes:** (1) Not requesting ATT before showing personalized ads on iOS — violates policy. (2) Using production ad unit IDs during development — risks AdMob account suspension. (3) Placing banners in a way that overlaps UI controls or is too close to them — leads to accidental clicks and policy violations.

---

## admin-panel-cms
**Classification:** avoid-unless-needed  ·  **Brick-provided:** no

- **Why it matters:** Some apps require a web-based admin interface to manage content, users, or operations — a blog platform's editor, a marketplace's vendor dashboard, a B2B app's customer success portal. This is substantial additional scope.
- **When to include:** Only when end users (non-developers) need to manage content or operations that cannot be handled through the app itself or Firebase Console. Validate this is genuinely needed before building.
- **When NOT to:** Most apps. The Firebase Console handles most CMS needs for small teams. Avoid building an admin panel during MVP — serve internal needs with the Firebase Console or a simple Retool instance first.
- **Suggested package/service:** Retool / AppSmith (no-code admin panels — fastest path); Directus / Strapi (headless CMS with Flutter API); custom Flutter Web admin app; Firebase Extensions for specific needs.
- **Setup notes:** Separate the admin app from the consumer app — different bundle ID, different auth rules (Admin SDK or custom claims). Use Firebase Security Rules to ensure only admin-role users can read/write admin-only collections. Never expose admin APIs to the consumer client.
- **Common mistakes:** (1) Building a custom admin panel before validating that Retool or Firebase Console can't meet the need. (2) Using the same Firebase project without proper security rules — consumer users can access admin data. (3) Scope creep — admin panels expand indefinitely; define the minimum viable admin surface and enforce it.

---

## rate-limiting
**Classification:** avoid-unless-needed  ·  **Brick-provided:** no

- **Why it matters:** Without rate limiting, a single misbehaving client (or attacker) can exhaust your API quota, run up your AI API bill, or degrade service for all users. Rate limiting is the first line of defense for any server-side resource that has cost or capacity constraints.
- **When to include:** Any time you add `ai-integration` (LLM API calls are expensive), or when you have a public API endpoint that could be abused. Also consider when you add `payments-cashfree` (protect order creation).
- **When NOT to:** Apps with a Firebase backend and no custom server — Firebase's own quotas and security rules provide baseline protection. Don't build rate limiting before you have a server.
- **Suggested package/service:** Server-side: Redis + `express-rate-limit` (Node.js) or Firebase Cloud Functions with a Firestore-based counter; Upstash Redis for serverless rate limiting.
- **Setup notes:** Implement rate limiting at the API Gateway or Cloud Function level — not in the Flutter app (client-side rate limiting is trivially bypassed). Distinguish between per-user limits (daily AI token quota) and global limits (protect the service). Return HTTP 429 with a `Retry-After` header; handle it gracefully in the Flutter app.
- **Common mistakes:** (1) Implementing rate limiting in the Flutter client — it protects nothing. (2) Using a fixed window counter instead of a sliding window — allows burst attacks at window boundaries. (3) Not communicating rate limit status to the user — silent failures feel like bugs.

---

## background-jobs
**Classification:** avoid-unless-needed  ·  **Brick-provided:** no

- **Why it matters:** Background jobs (periodic sync, background fetch, scheduled processing) can improve user experience for data-heavy apps. However, iOS and Android have increasingly aggressive background execution restrictions — what works in development often fails in production.
- **When to include:** Only when the specific use case genuinely requires it: silent push notifications triggering background fetch, geofencing, periodic background sync for a health/fitness app. Validate on real devices with aggressive battery optimization before committing.
- **When NOT to:** Most use cases are better served by foreground processing on app launch, or by server-side processing triggered by webhooks. Avoid background jobs unless you have validated they actually run reliably on your target devices and OS versions.
- **Suggested package/service:** `workmanager` (Android background work; iOS support is limited); `flutter_background_fetch`; Firebase Cloud Functions (server-side jobs that don't require the app to be running).
- **Setup notes:** On Android, use `WorkManager` via `workmanager` for deferrable background tasks. On iOS, register background modes in `Info.plist` and use `BGTaskScheduler`. Test on real hardware with battery optimization enabled — the simulator does not reflect real-world OS behavior. Prefer server-side jobs for anything that doesn't require device context.
- **Common mistakes:** (1) Assuming background jobs run reliably on iOS — they are heavily throttled by the OS. (2) Doing heavy computation in a background isolate without handling the isolate lifecycle. (3) Not handling the case where the background job fails silently — always log outcomes and surface sync status to the user on next foreground.

---

## security-hardening-advanced
**Classification:** avoid-unless-needed  ·  **Brick-provided:** no

- **Why it matters:** Advanced security hardening (certificate pinning, root/jailbreak detection, code obfuscation, anti-tampering) raises the bar for sophisticated attackers. For most consumer apps, the standard security posture (`secure-storage`, HTTPS, proper auth) is sufficient. Advanced hardening is justified when the threat model includes targeted attacks on the client binary.
- **When to include:** Financial apps, mobile banking, healthcare apps handling PHI, apps with high-value digital assets or IP, or apps operating under regulatory requirements (PCI-DSS, HIPAA) that mandate client-side controls.
- **When NOT to:** The vast majority of consumer apps. Certificate pinning breaks on every certificate rotation if not managed carefully. Root detection frustrates legitimate users on custom ROMs. The security benefit is real but the operational cost is high — only justify it with an actual threat model.
- **Suggested package/service:** `ssl_pinning_plugin` or `dio_certificate_pinner` for cert pinning; `flutter_jailbreak_detection` for root/jailbreak detection; `--obfuscate --split-debug-info` Flutter build flags for code obfuscation (these are free and should be used in all release builds as a baseline).
- **Setup notes:** Always use `--obfuscate --split-debug-info=build/debug-info` for all release builds — this is low-cost baseline obfuscation that should be on for every app, even if the rest of this ingredient is skipped. Certificate pinning requires a rotation plan — pinned certificates expire, and a bad rotation means all installed versions stop working. Root/jailbreak detection should degrade gracefully (warn, not crash) unless your threat model truly requires hard enforcement.
- **Common mistakes:** (1) Implementing certificate pinning without a certificate rotation procedure — when the cert expires, the app breaks for all users. (2) Using root detection as the sole security control — a determined attacker bypasses it in minutes. (3) Skipping `--obfuscate` on release builds — it's free and provides meaningful protection against casual reverse engineering.
