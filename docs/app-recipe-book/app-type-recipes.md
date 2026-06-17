# App-Type Recipes

Four concrete recipes for the four supported app types. Each recipe describes
the full ingredient stack for that type, where to look for deeper guidance, and
exactly what the `riverpod_simple_architecture` brick already provides.

Start from the 9 must-haves in [production-foundation.md](production-foundation.md),
then add the type-specific layers described here. Cross-reference
[decision-matrix.md](decision-matrix.md) to add further ingredients based on
interview answers.

---

## Utility / tools

Simple, single-purpose tools where the core value is immediate and the UI is
lean. Examples: unit converter, QR scanner, file renamer, clipboard manager,
markdown preview, DNS lookup tool.

- **Required modules:**
  crash-reporting, analytics, ci-cd, automated-testing, store-readiness,
  privacy-basics, secure-storage, observability-talker, theming-settings
  *(the 9 must-haves — no type-specific additions required)*

- **Optional modules:**
  ads (if free + ad-supported), payments-revenuecat (one-time unlock),
  onboarding (if value is not immediately obvious), deep-links (if the tool
  acts on content shared from other apps), push-notifications (scheduled
  reminders for recurrence-based tools), offline-support (if network access
  would otherwise block the core action)

- **Backend fit:**
  Most utility apps need **no backend** — [local-only](backend-recipes.md#local-only-no-backend)
  is the default. If you add accounts or sync, Firebase is the lean path
  ([backend-recipes.md](backend-recipes.md#firebase-default)).

- **Key analytics events:**
  `app_open`, `screen_view`, `tool_run` (core action invoked with `tool_name`
  and `result`), `settings_changed`. See [analytics-events.md](analytics-events.md#utility--tools).

- **Security concerns:**
  Utility apps that process files, clipboard content, or network data must
  sanitize inputs to avoid path traversal or injection issues. If the tool
  accesses device APIs (camera, contacts, files), request permissions at the
  moment of use — not on launch. API keys for any third-party services must
  use `--dart-define` / server-side secrets, never committed to source.
  See [security-checklist.md](security-checklist.md#secrets--keys).

- **Testing scope:**
  Unit tests for all transformation/computation logic (the engine of the tool).
  Widget tests for the primary action screen. No integration tests required
  at MVP. See [testing-strategy.md](testing-strategy.md#always-solid-default).

- **Release checklist:**
  Standard store metadata (icon, screenshots, description). If the tool
  uses any device API (camera, microphone, contacts), add the appropriate
  usage description strings to `Info.plist` / `AndroidManifest.xml` before
  submission — omission causes rejection. See
  [release-checklist.md](release-checklist.md#store-metadata).

- **Suggested folder structure:**
  ```
  lib/
  ├── features/
  │   └── tool/
  │       ├── data/          # data sources (if any: local file, network API)
  │       ├── domain/        # models, result types
  │       ├── application/   # ToolNotifier (AsyncNotifier)
  │       └── presentation/  # ToolScreen, result widgets
  ├── shared/
  │   ├── router/            # auto_route config
  │   └── widgets/           # shared UI components
  └── bootstrap.dart
  ```

- **What the brick gives you:**
  Firebase Crashlytics + `wireCrashHandlers` (crash-reporting), talker logging
  wired in bootstrap (observability-talker), `flutter_secure_storage` 10
  (secure-storage), `flex_color_scheme` 8 + SettingsPage/AboutSection
  (theming-settings), hive_ce initialized (local-database), slang for
  localization. The CI/CD pipeline, analytics, and any optional modules are
  added per the decision matrix.

---

## Content / feed

Apps where the primary loop is discovering, consuming, and sharing a stream of
content. Examples: news reader, recipe app, sports scores, podcast directory,
photo gallery, community feed, curated link digest.

- **Required modules:**
  crash-reporting, analytics, ci-cd, automated-testing, store-readiness,
  privacy-basics, secure-storage, observability-talker, theming-settings
  *(9 must-haves)* **+** deep-links, remote-config, performance-monitoring

- **Optional modules:**
  authentication (personalization, bookmarks, comments),
  push-notifications (breaking news, new content from followed creators),
  offline-support (download articles / cache feed for offline reading),
  ads (free-tier monetization), payments-revenuecat (premium ad-free tier),
  cloud-sync (sync bookmarks / reading progress across devices),
  feature-flags (A/B test feed ranking or layout),
  experimentation-ab (optimize onboarding or paywall conversion),
  referral-system (share-to-unlock, viral growth),
  onboarding (topic / interest selection on first launch)

- **Backend fit:**
  [Firebase](backend-recipes.md#firebase-default) is the default — Firestore
  for content collections, Remote Config for feed algorithm parameters, FCM for
  push, Crashlytics already in the brick. If you own the content server or need
  advanced SQL queries over large datasets, consider
  [Supabase](backend-recipes.md#supabase) or a
  [Custom REST / GraphQL](backend-recipes.md#custom-rest--graphql) backend.

- **Key analytics events:**
  `app_open`, `screen_view`, `content_view` (with `content_id`, `content_type`),
  `content_share` (with `content_id`, `share_method`), `search_performed`
  (with `query`), `feed_scroll_depth`. See
  [analytics-events.md](analytics-events.md#content--feed).

- **Security concerns:**
  Deep links must validate the incoming URI before navigating — an open redirect
  in a deep link handler can be exploited. If the app shows user-generated
  content (comments, bios), sanitize HTML/markdown before rendering. ATT
  prompt is required before showing personalized ads on iOS. See
  [security-checklist.md](security-checklist.md#transport) and
  [security-checklist.md](security-checklist.md#payments--pii).

- **Testing scope:**
  Unit tests for feed pagination logic, content model parsing, and search
  ranking. Widget tests for the feed list item and content detail screen
  (especially empty/error/loading states). Performance testing: profile
  the feed list with 100+ items to catch jank before release. See
  [testing-strategy.md](testing-strategy.md#add-by-ingredient).

- **Release checklist:**
  Deep-link verification (Associated Domains / `assetlinks.json`) must be live
  before submission. If the app aggregates third-party content, confirm
  licensing. If push notifications are included, include notification
  permission rationale in the App Review notes. See
  [release-checklist.md](release-checklist.md).

- **Suggested folder structure:**
  ```
  lib/
  ├── features/
  │   ├── feed/
  │   │   ├── data/          # FeedRepository, content API client
  │   │   ├── domain/        # ContentItem, FeedPage models
  │   │   ├── application/   # FeedNotifier, SearchNotifier
  │   │   └── presentation/  # FeedScreen, ContentDetailScreen, FeedTile
  │   ├── bookmarks/
  │   │   ├── data/          # local hive_ce box or Firestore
  │   │   ├── application/   # BookmarksNotifier
  │   │   └── presentation/  # BookmarksScreen
  │   └── search/
  │       ├── application/   # SearchNotifier
  │       └── presentation/  # SearchScreen, SearchResultTile
  ├── shared/
  │   ├── router/
  │   ├── remote_config/     # RemoteConfigService, feature toggles
  │   └── widgets/
  └── bootstrap.dart
  ```

- **What the brick gives you:**
  Crashlytics (crash-reporting), talker (observability-talker), secure storage
  (secure-storage), flex_color_scheme + SettingsPage (theming-settings),
  hive_ce for local bookmarks cache (local-database), slang for localization.
  deep-links, remote-config, performance-monitoring, and push-notifications are
  add-ons wired per the decision matrix.

---

## Productivity / notes

Apps where the core loop is creating and organizing user-generated content.
Examples: note-taking, to-do lists, habit tracker, journaling, task manager,
read-later queue, personal CRM, time tracker.

- **Required modules:**
  crash-reporting, analytics, ci-cd, automated-testing, store-readiness,
  privacy-basics, secure-storage, observability-talker, theming-settings
  *(9 must-haves)* **+** local-database, offline-support, onboarding

- **Optional modules:**
  authentication (sync, multi-device, backup),
  cloud-sync (cross-device access — requires authentication),
  push-notifications (reminders, recurring task nudges),
  payments-revenuecat (premium tier: unlimited items, cloud sync, export),
  remote-config (tune limits like free-tier item cap without a store release),
  feature-flags (gradual rollout of new editor features),
  deep-links (share a note / invite a collaborator),
  experimentation-ab (optimize paywall or onboarding funnel),
  background-jobs (periodic background sync — validate OS behavior on real
  devices first; often Firebase Cloud Functions is a better choice)

- **Backend fit:**
  **Local-only** ([hive_ce](backend-recipes.md#local-only-no-backend)) is a
  valid and often correct default for MVP — no backend, no auth, works
  immediately. Add [Firebase](backend-recipes.md#firebase-default) when you
  add cloud-sync or authentication. If data is relational (tasks → projects →
  labels with complex queries), consider
  [Supabase](backend-recipes.md#supabase) or `drift` (SQLite) over hive_ce.

- **Key analytics events:**
  `app_open`, `screen_view`, `item_created` (with `item_type`),
  `item_completed` (with `item_type`), `item_deleted`, `sync_completed`
  (with `item_count`, `duration_ms`), `paywall_view` (if paid tier exists),
  `export_triggered`. See
  [analytics-events.md](analytics-events.md#productivity--notes).

- **Security concerns:**
  User notes may contain sensitive personal information — treat note content
  like PII. If syncing to Firestore, enforce Firestore Security Rules so
  users can only read/write their own documents (auth UID path scoping). If
  encrypting notes locally, store the encryption key in `flutter_secure_storage`
  (brick-provided), never in SharedPreferences or in the note body. See
  [security-checklist.md](security-checklist.md#storage).

- **Testing scope:**
  Unit tests for CRUD operations on the note/task Riverpod notifier
  (use `testNotifier` from the brick's test helper). Widget tests for the
  list screen empty state and the note editor. Offline behavior tests:
  create item with network off → reconnect → verify sync. See
  [testing-strategy.md](testing-strategy.md#add-by-ingredient).

- **Release checklist:**
  Privacy policy must explicitly mention that user-created content is stored
  locally and/or synced — especially for EU/GDPR users who can request
  deletion. If the app supports export (PDF, CSV), verify the exported content
  doesn't include system metadata that leaks internal identifiers. See
  [release-checklist.md](release-checklist.md#privacy--consent).

- **Suggested folder structure:**
  ```
  lib/
  ├── features/
  │   ├── notes/
  │   │   ├── data/          # NoteRepository (hive_ce box + optional Firestore)
  │   │   ├── domain/        # Note, NoteId, Tag models
  │   │   ├── application/   # NotesNotifier, NoteDetailNotifier, SyncNotifier
  │   │   └── presentation/  # NotesListScreen, NoteEditorScreen, TagChip
  │   ├── onboarding/
  │   │   ├── application/   # OnboardingNotifier
  │   │   └── presentation/  # OnboardingScreen, PermissionsRationaleScreen
  │   └── sync/
  │       ├── data/          # SyncQueue, ConflictResolver
  │       └── application/   # SyncStatusNotifier
  ├── shared/
  │   ├── router/
  │   ├── connectivity/      # ConnectivityProvider (connectivity_plus)
  │   └── widgets/
  └── bootstrap.dart
  ```

- **What the brick gives you:**
  Crashlytics (crash-reporting), talker (observability-talker), secure storage
  for encryption keys and tokens (secure-storage), flex_color_scheme +
  SettingsPage (theming-settings), **hive_ce** initialized and ready for your
  Note boxes (local-database). offline-support, cloud-sync, authentication,
  and onboarding are add-ons wired per the decision matrix.

---

## Subscription / SaaS / AI

Apps with a recurring subscription or usage-based AI model where conversion,
retention, and monetization are the key metrics. Examples: AI writing assistant,
smart journaling with AI summaries, subscription recipe generator, SaaS project
management, AI coding tutor, subscription photo editor.

- **Required modules:**
  crash-reporting, analytics, ci-cd, automated-testing, store-readiness,
  privacy-basics, secure-storage, observability-talker, theming-settings
  *(9 must-haves)* **+** authentication, payments-revenuecat, remote-config,
  onboarding

- **Optional modules:**
  ai-integration + rate-limiting (add together — mandatory pairing),
  push-notifications (onboarding nudges, AI job completion, trial expiry),
  cloud-sync (sync user content / AI-generated outputs across devices),
  deep-links (paywall sharing, invite-to-trial flows, email campaigns),
  feature-flags (gate new AI models or premium features behind flags),
  experimentation-ab (optimize paywall layout, trial length, pricing),
  referral-system (refer-a-friend for subscription credit — high LTV apps),
  offline-support (cache AI outputs for offline reading),
  performance-monitoring (AI response latency tracking, paywall load time),
  admin-panel-cms (if human-curated content supplements the AI outputs)

- **Backend fit:**
  [Firebase](backend-recipes.md#firebase-default) is the default — Firebase
  Auth for accounts, Firestore for user content and subscription metadata,
  Remote Config for pricing and trial lengths, FCM for engagement. For
  AI features, proxy all LLM API calls through Firebase Cloud Functions or
  a custom server — **never put LLM API keys in the Flutter app**. If you
  need relational data (complex billing, usage metering, multi-tenant SaaS),
  consider [Supabase](backend-recipes.md#supabase) or a
  [Custom REST / GraphQL](backend-recipes.md#custom-rest--graphql) backend.

- **Key analytics events:**
  `app_open`, `screen_view`, `sign_up` / `login` / `logout`,
  `paywall_view` (with `source`), `purchase_started` (with `sku`),
  `purchase_completed` (with `sku`, `revenue`), `trial_started`,
  `trial_converted`, `subscription_cancelled`, `ai_request` (with `model`,
  `tokens`, `feature`), `ai_response_received` (with `latency_ms`).
  See [analytics-events.md](analytics-events.md#subscription--saas--ai).

- **Security concerns:**
  This is the highest-security app type in this recipe book. Key concerns:
  (1) Never put RevenueCat API keys or LLM API keys in the Flutter app binary.
  (2) Validate subscription entitlements server-side on sensitive operations —
  do not rely solely on the client-side `CustomerInfo` from RevenueCat.
  (3) Proxy AI calls through your server with per-user token quotas to prevent
  runaway costs. (4) Auth tokens must be stored in `flutter_secure_storage`
  (brick-provided) and cleared on logout. (5) If AI handles PII (user writes
  diary entries, the AI summarizes them), document this in your privacy policy
  and data safety declaration. See [security-checklist.md](security-checklist.md).

- **Testing scope:**
  Unit tests for entitlement logic (free tier vs paid tier feature gating),
  subscription state machine (active → cancelled → grace period → lapsed),
  and the AI request/response notifier. Widget tests for the paywall screen
  and the onboarding flow. Mock RevenueCat SDK in tests — never make live IAP
  calls in CI. Integration test the purchase → entitlement → feature-unlock
  flow in a sandbox environment. See
  [testing-strategy.md](testing-strategy.md#add-by-ingredient).

- **Release checklist:**
  (1) App Store and Google Play subscriptions must be created and approved in
  the respective consoles before submission — this can take 24–48 hours.
  (2) RevenueCat sandbox testing must pass the full purchase → restore →
  cancel → reactivate loop. (3) Privacy policy must explicitly mention AI data
  processing and subscription auto-renewal terms. (4) iOS: include subscription
  terms and the auto-renewal disclosure on the paywall screen (required by
  App Store guidelines). (5) Android: fill the Play Data Safety form accurately
  for financial data. See [release-checklist.md](release-checklist.md).

- **Suggested folder structure:**
  ```
  lib/
  ├── features/
  │   ├── auth/
  │   │   ├── data/          # AuthRepository (firebase_auth)
  │   │   ├── application/   # AuthNotifier
  │   │   └── presentation/  # SignInScreen, SignUpScreen
  │   ├── onboarding/
  │   │   ├── application/   # OnboardingNotifier
  │   │   └── presentation/  # OnboardingScreen, PaywallScreen
  │   ├── paywall/
  │   │   ├── data/          # EntitlementRepository (purchases_flutter)
  │   │   ├── application/   # EntitlementNotifier, PurchaseNotifier
  │   │   └── presentation/  # PaywallScreen, SubscriptionStatusBanner
  │   ├── ai/
  │   │   ├── data/          # AiRepository (server proxy client)
  │   │   ├── application/   # AiRequestNotifier
  │   │   └── presentation/  # AiChatScreen, AiOutputWidget
  │   └── dashboard/
  │       ├── application/   # DashboardNotifier
  │       └── presentation/  # DashboardScreen, UsageIndicator
  ├── shared/
  │   ├── router/
  │   ├── remote_config/     # RemoteConfigService, FeatureFlags
  │   ├── entitlements/      # EntitlementGuard widget
  │   └── widgets/
  └── bootstrap.dart
  ```

- **What the brick gives you:**
  Crashlytics (crash-reporting), talker (observability-talker), secure storage
  for auth tokens and API keys (secure-storage), flex_color_scheme +
  SettingsPage with privacy policy URL (theming-settings), hive_ce for local
  caching of AI outputs (local-database). authentication, payments-revenuecat,
  remote-config, onboarding, ai-integration, and rate-limiting are all
  add-ons wired per the decision matrix and interview answers.
