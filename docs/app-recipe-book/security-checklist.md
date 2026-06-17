# Security Checklist

A concrete, actionable checklist organized by domain. Each item is a hard requirement unless explicitly marked as conditional. Reference the relevant recipe-book ingredients where additional context is documented.

> **Scope:** This checklist covers the Flutter client and its immediate server-side touch points (Cloud Functions, payment webhooks). It does not cover full server-side application security (that belongs in your backend's own runbook). Items that apply only when a specific ingredient is included are marked with a condition in parentheses.

---

## Secrets & keys

- [ ] No API keys, tokens, or secrets committed to git — check with `git log -S 'secret_key'` and a pre-commit hook (consider `detect-secrets` or `git-guardian`).
- [ ] No API keys in `--dart-define` values visible in the compiled binary — use `--dart-define-from-file` with a file excluded from git, or move secrets to your server.
- [ ] Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are committed — this is intentional and safe (they contain no private keys; access is controlled by Firebase Security Rules). Do NOT commit Firebase Admin SDK service account JSON files — those are private server credentials.
- [ ] Cashfree `APP_ID` and `SECRET_KEY` exist only in server environment variables — never in the Flutter app, never in `--dart-define`.
- [ ] LLM API keys (OpenAI, Anthropic, Gemini, etc.) exist only on the server — all AI requests are proxied through your backend (see `ai-integration` ingredient).
- [ ] RevenueCat public API key (used on the client) is not the same as any server-side webhook secret — treat them separately.
- [ ] `.env` files, `key.properties` (Android signing), and `AuthKey_*.p8` (APNs) are in `.gitignore` — verify with `git status` after adding.
- [ ] CI secrets (store signing credentials, API keys) are stored in your CI provider's secrets store (GitHub Actions secrets, Codemagic environment variables) — not hardcoded in CI YAML files.

---

## Storage

- [ ] Auth tokens (JWT access token, refresh token) stored in `flutter_secure_storage` (brick-provided) — not in `SharedPreferences`, `Hive` plain boxes, or in-memory only.
- [ ] Cashfree payment session IDs and order IDs are ephemeral — do not persist them in storage beyond the payment flow.
- [ ] Hive boxes containing sensitive data (encrypted notes, private user content) use `HiveAesCipher` with an AES key stored in `flutter_secure_storage`.
- [ ] Hive boxes containing only non-sensitive data (feed cache, public content) do not require encryption — avoid over-engineering.
- [ ] `SharedPreferences` is used only for non-sensitive preferences (theme choice, onboarding completion flag, locale) — verify no sensitive values are written there.
- [ ] App does not cache raw network responses containing PII to disk — if caching is needed, cache only non-sensitive fields or encrypt the cache.
- [ ] Logout clears: `flutter_secure_storage` (all keys written by the app), in-memory Riverpod state, Hive boxes containing user-specific data, and Crashlytics user identifier (`FirebaseCrashlytics.instance.setUserIdentifier('')`).
- [ ] `(if web target)` Do not rely on `flutter_secure_storage` on Flutter **web** — it falls back to `localStorage`/IndexedDB and is **not** secure (readable by any script, persisted in plaintext). On web, keep tokens out of the client entirely: use an httpOnly-cookie backend session. This is a silent footgun because the same API "works" on web without error.
- [ ] Android backup is configured appropriately — by default, `auto-backup` sends `SharedPreferences` and file storage to Google Drive. Exclude `flutter_secure_storage` data from backup (it is already excluded by the Keystore), but review `android:allowBackup` in `AndroidManifest.xml`.

---

## Transport

- [ ] All API calls use HTTPS — no `http://` endpoints in production. Verify by inspecting the `dio` base URL and any hardcoded URLs in the codebase.
- [ ] Cleartext traffic (`android:usesCleartextTraffic="true"`) is not enabled in the production `AndroidManifest.xml` — it may be enabled for `debug` builds to reach a local dev server, but must be absent from the release manifest.
- [ ] Certificate pinning (see `security-hardening-advanced`) is NOT enabled unless your threat model explicitly requires it — the operational risk (breaking on certificate rotation) outweighs the benefit for most consumer apps. Document the decision either way.
- [ ] Dio's `LogInterceptor` is disabled in production builds — it logs request/response bodies which may contain tokens or PII. Gate it behind `kDebugMode`.
- [ ] `talker_dio_logger` is configured to redact `Authorization` headers and response bodies containing PII — review its configuration before enabling in staging.
- [ ] Webhook endpoints (Cashfree payment webhooks, RevenueCat webhooks) validate the signature on every incoming request before processing. Cashfree: HMAC-SHA256 of the required fields. RevenueCat: `X-RevenueCat-Signature` header validation.

---

## Auth

- [ ] Tokens stored in `flutter_secure_storage` — not in `SharedPreferences` or plain Hive (see Storage section).
- [ ] Token refresh is handled automatically via `firebase_auth`'s `authStateChanges()` stream or via a Dio interceptor for custom backends — the app never uses an expired token silently.
- [ ] Logout invalidates the session server-side (Firebase: `FirebaseAuth.instance.signOut()` is sufficient; custom backend: call your `/logout` endpoint to revoke the refresh token).
- [ ] Logout clears all user state as described in the Storage section — no stale data bleeds between accounts after a sign-out → sign-in as a different user.
- [ ] Anonymous auth (Firebase) is used for pre-auth users where appropriate — it provides a stable UID for analytics and Crashlytics without requiring account creation, and can be upgraded to a real account later.
- [ ] Auth state is observed reactively (stream/provider), not checked once and cached — avoids using a stale auth state after token expiry or forced sign-out.
- [ ] Multi-factor authentication (MFA) is considered for apps where account compromise is high-risk (financial, health, B2B). Firebase Auth supports TOTP MFA.
- [ ] Password reset / account recovery flows are implemented if using email/password auth — App Store review expects them.

---

## Payments & PII

- [ ] **Never confirm payment fulfillment on the client** — both RevenueCat and Cashfree provide server-side verification. RevenueCat: check `CustomerInfo.entitlements.active` from the SDK (server-validated). Cashfree: verify the webhook signature on your server before fulfilling.
- [ ] Cashfree: order creation and fulfillment happen exclusively on the server — the Flutter client only receives a `payment_session_id` and calls the SDK payment sheet. See the `payments-cashfree` recipe.
- [ ] Cashfree: webhook handler is idempotent — processing the same `orderId` twice does not create a duplicate fulfillment event.
- [ ] RevenueCat: entitlement check is done against `CustomerInfo` fetched from RevenueCat (server-validated), not against a local flag that was set at purchase time.
- [ ] RevenueCat: sandbox credentials are used for all non-production testing — production API key is in production environment only.
- [ ] PII minimization: collect only the user data your app actually needs. Document collected data categories in the privacy policy and match them exactly to the App Store Privacy Nutrition Labels and Google Play Data Safety declaration.
- [ ] Data deletion: provide a mechanism for users to delete their account and associated data (required by most app stores for apps with user accounts, and by GDPR). Firebase: delete the Firestore user document + Auth account. Cashfree: consult their data retention policy.
- [ ] Payment card data never passes through your server or is stored anywhere — the Cashfree SDK handles card tokenization. Your server never sees raw card numbers.
- [ ] Analytics events do not contain PII (email, name, phone, precise address) — use Firebase UIDs or internal IDs as user identifiers in events. See `analytics-events.md`.
- [ ] Crashlytics user identifier is set to the Firebase UID (not email or username) — `FirebaseCrashlytics.instance.setUserIdentifier(uid)`. Cleared on logout.
