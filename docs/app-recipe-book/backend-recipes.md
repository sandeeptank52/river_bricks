# Backend Recipes

Backend is chosen per app. Firebase is the lean default because the brick already wires Firebase Crashlytics — adding Firestore, Auth, and Remote Config on top of an existing Firebase project is near-zero marginal setup. Document covers fit, services, auth story, cost, and gotchas for each option.

---

## Firebase (default)

**Best for:** Apps that need a fast start, real-time data, push notifications, and deep integration with the analytics/crash stack the brick already sets up. Ideal for: Content/feed, Subscription/SaaS/AI, and any app that needs user accounts + cloud sync without owning a server.

**Services included:**
- **Auth:** `firebase_auth` — email/password, Google, Apple, anonymous; token refresh handled automatically via `authStateChanges()` stream.
- **Database/sync:** Firestore (document/collection, real-time `snapshots()` streams, offline persistence via local cache) for structured data; Firebase Storage for files/images.
- **Functions:** Cloud Functions (Node.js/Python) for server-side logic, webhook handlers, and any secret-holding operations (Cashfree order creation, RevenueCat webhooks, AI proxy).
- **Messaging:** FCM via `firebase_messaging` — free cross-platform push, integrates with Crashlytics and Analytics.
- **Config:** Firebase Remote Config — free, integrates with A/B Testing and Analytics targeting.
- **Monitoring:** Firebase Performance (HTTP + custom traces), integrated with existing `firebase_performance` setup.
- **Crashlytics:** Already provided by the brick — no extra Firebase setup required.

**Auth story:** `firebase_auth` issues JWTs that Firestore Security Rules validate natively. Use `authStateChanges()` as your auth state stream; store nothing token-related yourself — the SDK handles it. Set `FirebaseCrashlytics.instance.setUserIdentifier(uid)` post-login (UID only, never email).

**Cost:** Spark (free) tier is sufficient for most MVPs and small apps — 1 GiB Firestore storage, 10 GiB/month egress, 125K Cloud Function invocations/month. Blaze (pay-as-you-go) is required for Cloud Functions in production but the free tier applies first. For most indie apps the monthly bill stays under $5.

**Gotchas:**
- Firestore Security Rules are your access control layer — misconfigured rules exposing all documents is a common and serious mistake. Always test rules with the Rules Simulator before going live.
- Firestore charges per document read/write. Fan-out writes (e.g., updating every follower's feed) can run up costs quickly at scale. Design data models for the read pattern, not normalization.
- Firebase vendor lock-in is real but manageable: abstract Firestore behind a repository interface so swapping the backend later is a data-layer change, not an app-wide refactor.
- Firebase project is shared by dev/staging/prod by default — create separate Firebase projects for each environment to avoid prod data pollution from dev builds.

---

## Supabase

**Best for:** Apps with relational data, complex queries, or teams already comfortable with SQL and PostgreSQL. Supabase provides managed Postgres + Row Level Security (RLS), a real-time subscription layer, S3-compatible storage, and serverless Edge Functions.

**Services included:**
- **Database:** Postgres with RLS — full SQL, foreign keys, indexes, views, and migrations tracked via Supabase CLI.
- **Auth:** Built-in auth (email/password, OAuth, magic link, phone OTP) with JWTs that Postgres RLS policies validate natively. `supabase_flutter` exposes `onAuthStateChange` stream.
- **Realtime:** Supabase Realtime — subscribe to Postgres `INSERT`/`UPDATE`/`DELETE` changes as a stream. Lower latency than polling; higher latency than Firestore for global distribution.
- **Storage:** S3-compatible object storage with per-bucket RLS policies.
- **Edge Functions:** Deno-based serverless functions for server-side logic (API proxies, webhooks, secrets).

**Package:** `supabase_flutter` — covers auth, database queries, realtime, and storage in one SDK.

**Auth story:** Supabase auth issues JWTs; store the session token via the SDK (it persists in `shared_preferences` by default — consider storing the refresh token in `flutter_secure_storage` for sensitive apps). RLS policies reference `auth.uid()` to scope data per user.

**Cost:** Free tier: 500 MB Postgres storage, 2 GB egress, 50,000 Edge Function invocations/month. Pro tier: $25/month for production-grade limits. Predictable pricing — no per-document read charges, unlike Firestore.

**When to choose over Firebase:**
- You have relational data with many-to-many relationships or complex joins.
- Your team prefers SQL over NoSQL document modeling.
- You want lower cost at scale for read-heavy workloads (no per-read charge).
- You need full-text search without adding Algolia/Typesense.

**Gotchas:**
- RLS policies are powerful but easy to get wrong silently — a missing policy means no rows are returned rather than an error. Test policies thoroughly.
- Supabase Realtime is Postgres-backed, so very high-frequency writes (chat, live cursors) can strain the WAL. Consider Firestore or a dedicated message broker for extreme real-time needs.
- The brick does not pre-wire Supabase — you will need to initialize `Supabase.initialize()` in `bootstrap.dart` and replace the Firebase crashlytics + analytics setup with Sentry and a Supabase-compatible analytics solution, or keep Firebase for those services specifically.
- No built-in equivalent of Firebase Remote Config — pair with a simple Postgres config table or use LaunchDarkly.

---

## Custom REST / GraphQL

**Best for:** Apps where you already own and operate the server, or where compliance/data residency requirements prohibit BaaS solutions. Also the right choice when the business logic is too complex for serverless functions and belongs in a dedicated service.

**Services:** Your server (any language/framework). The Flutter app is a pure API client — no SDK from the backend vendor.

**HTTP client stack:**
- `dio` — feature-rich HTTP client with interceptors (logging, auth token injection, retry, performance monitoring). Use `talker_dio_logger` to route Dio logs through the brick's talker instance.
- `retrofit` (code-gen REST client) — define API interfaces as abstract classes; `retrofit_generator` generates the implementation. Strong typing, no boilerplate request/response mapping.
- `ferry` (GraphQL) — normalized cache, typed operations from `.graphql` files, streaming subscriptions. Use when your server exposes a GraphQL API.

**Auth story:** Server issues JWTs (or uses OAuth 2.0 + PKCE for a third-party IdP). Store access token in `flutter_secure_storage` (brick-provided). Implement a Dio interceptor that: (1) injects the `Authorization: Bearer <token>` header, (2) handles 401 responses by calling the refresh endpoint, (3) retries the original request on success, (4) signs the user out on refresh failure.

**Gotchas:**
- You own the operational burden: server uptime, scaling, security patches, certificate rotation. Firebase and Supabase handle this for you.
- CORS configuration is a common stumbling block during development — configure it correctly for both dev and prod origins early.
- Version your API from day one (`/api/v1/...`). Mobile clients cannot be force-updated; old API versions must remain functional after you ship breaking changes.
- Custom backends pair well with `crash-reporting` (Sentry works better for non-Firebase stacks than Crashlytics), but you can keep Crashlytics for the Flutter client and instrument the server separately.

**When to choose:**
- Existing server the business owns and operates.
- Compliance requirements (data residency, SOC 2, HIPAA) that BaaS providers don't meet for your tier.
- Business logic that is too complex for Firebase Cloud Functions or Supabase Edge Functions and belongs in a long-running service.

---

## Local-only (no backend)

**Best for:** Utility tools, calculators, converters, personal trackers, and any app where data is inherently device-local and accounts add no value. No backend means no server costs, no auth complexity, and no network dependency.

**Services:** None. All data lives in `hive_ce` (brick-provided), with file system access via `path_provider` for exports.

**Auth story:** None required. If you later add optional backup/sync, add `authentication` + a backend at that point.

**Cost:** $0 server costs. The only costs are App Store / Play Store developer account fees.

**Data persistence stack (all brick-provided):**
- `hive_ce` — primary structured storage (fast, pure Dart, no native dependency).
- `flutter_secure_storage` — sensitive values (PIN, sensitive preferences).
- `shared_preferences` — non-sensitive preferences (theme, onboarding flag).

**Upgrade path:** When users request sync or accounts, layer Firebase Auth + Firestore on top without rewriting the local data layer. Keep `hive_ce` as the local cache/offline store; Firestore becomes the sync layer. The Riverpod repository pattern (abstract interface + concrete implementation) makes this swap a data-layer change.

**Gotchas:**
- No account recovery means users lose data if they uninstall or change devices. Make this explicit in the app description and UI — set user expectations.
- If you later add cloud sync, migrating existing local Hive data to Firestore requires a one-time migration path. Plan the Hive schema as if you might need to serialize it to JSON eventually.
- Backup/export functionality (e.g., export to JSON/CSV) can partially address the data loss concern and improves user trust.

---

## How to choose

| Signal | Backend |
|---|---|
| Need real-time data + quick start + Firebase already in brick | Firebase |
| Relational data / SQL / complex queries / RLS | Supabase |
| Existing server / full control / compliance requirements | Custom REST/GraphQL |
| No accounts, no sync, local utility / tool | Local-only |
| Need both low-cost structured storage + optional future sync | Local-only → Firebase upgrade path |
| India-market payments (Cashfree) requiring server | Firebase Cloud Functions or Custom (either works) |
| AI integration requiring API proxy + rate limiting | Firebase Cloud Functions or Custom |
