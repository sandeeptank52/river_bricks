# Monetization Recipes

Two payment paths are fundamentally different — do not conflate them. Store IAP (RevenueCat) and direct gateway (Cashfree) serve entirely distinct use cases and are mutually exclusive for any given transaction type. Mixing them up causes app store rejection. Ads are a third, orthogonal strategy.

> **Rule:** Digital goods and subscriptions sold inside a consumer app **must** go through store IAP. Real-world goods and services **must not** — they bypass the store entirely. Violating this rule results in app removal.

---

## Store IAP & subscriptions — RevenueCat  (payments-revenuecat)

**Use for:** Any digital content or capability sold inside the app — subscriptions (weekly, monthly, annual), lifetime unlocks, consumable credits, or premium feature tiers. App Store and Google Play require that all such transactions use their native IAP systems. RevenueCat wraps both stores' IAP SDKs into a single, consistent API and hosts receipt validation and entitlement management on its servers.

**Package:** `purchases_flutter` (RevenueCat's official Flutter SDK).

**Server:** Optional for basic flows — RevenueCat's servers handle receipt validation and entitlement checks. A server webhook is recommended for fulfillment events (subscription renewals, cancellations, refunds) but not required to start.

**Flow:**
1. Define products in App Store Connect (subscriptions/IAP) and Google Play Console (subscriptions/in-app products) — this must happen before you can test.
2. Mirror those product identifiers in the RevenueCat dashboard as Offerings/Packages.
3. At app start, call `Purchases.configure(PurchasesConfiguration(apiKey))` in `bootstrap.dart`. After authentication, set `await Purchases.logIn(firebaseUid)` so entitlements follow the user across device reinstalls and platforms.
4. Show paywall: fetch the current Offering from `Purchases.getOfferings()` and display your custom paywall UI.
5. On purchase: call `Purchases.purchasePackage(package)`. The SDK handles the store sheet, receipt collection, and server-side validation.
6. Check entitlement: `CustomerInfo.entitlements.active['premium']?.isActive ?? false`. Refresh `CustomerInfo` on app foreground.
7. Implement **restore purchases** — required by store guidelines. Wire a "Restore" button to `Purchases.restorePurchases()`.

**Gotchas:**
- Store review delays mean product setup in App Store Connect / Google Play Console can take 24–48 hours before products are reviewable. Do this first, before writing code.
- Sandbox testing behaves differently from production: subscriptions renew in minutes, not days; cancellation is immediate; some receipt edge cases don't reproduce in sandbox. Test the full flow with a real purchase before launch.
- RevenueCat's entitlement check must be done against `CustomerInfo` from the SDK — never trust a local flag or a client-side success callback alone. `CustomerInfo` is server-validated.
- Android requires Google Play Billing Library 5+ and a linked Google Cloud project. RevenueCat handles the library dependency, but the Play Console billing setup must be correct.

**Common mistakes:**
- Rolling your own receipt validation against Apple/Google APIs — RevenueCat exists specifically so you don't do this. The Apple S2S receipt validation API is being deprecated; StoreKit 2 transaction verification is complex. Use RevenueCat.
- Missing the restore purchases button — App Store review will reject apps without a visible restore mechanism for paid features.
- Gating all app value behind a paywall with no offline grace period — if RevenueCat's servers are unreachable, `CustomerInfo` may be stale. Cache the last known entitlement state and provide a short grace window (RevenueCat does this automatically for subscribers).
- Using production API keys in development — sandbox purchases with production keys pollute your subscription data and can cause accounting issues.

---

## Direct payment gateway — Cashfree  (payments-cashfree)

**Use for:** Real-world goods and services in the Indian market where store IAP rules do NOT apply — food delivery, e-commerce, utility bills, ticket booking, marketplace payouts, B2B invoicing, subscription services for physical goods. Cashfree is a RBI-regulated payment aggregator with broad support for UPI, cards, net banking, wallets, and EMI.

**Package:** `flutter_cashfree_pg_sdk` (client SDK for payment collection — handles the payment sheet UI, UPI intent flows, and card entry).

**Server REQUIRED:** A backend server is mandatory for this payment path. You cannot safely create orders or verify payments without one. The server must:
1. Create a Cashfree order via the Orders API (using your `APP_ID` and `SECRET_KEY`, which must never leave the server).
2. Return the `payment_session_id` to the Flutter client.
3. Receive and verify Cashfree's payment webhook using the HMAC-SHA256 signature.
4. Fulfill the transaction server-side after webhook verification.

**Flow:**
1. User taps "Pay" → Flutter calls your server's order-creation endpoint with order details (amount, currency, customer info).
2. Server creates order via `POST https://api.cashfree.com/pg/orders` → returns `payment_session_id` to Flutter.
3. Flutter calls `CFPaymentGatewayService.doPayment(CFDropCheckoutPayment)` with the `payment_session_id` and a `CFTheme` matching your app.
4. User completes payment in the Cashfree payment sheet (UPI, card, netbanking, etc.).
5. Cashfree calls your server webhook with the payment result.
6. **Server verifies webhook signature** (HMAC-SHA256 of `orderId + orderAmount + referenceId + txStatus + paymentMode + txMsg + txTime` with your `SECRET_KEY`).
7. Only after successful signature verification does the server mark the order as fulfilled and return confirmation to the Flutter client.

**Compliance:**
- **KYC:** Cashfree requires business KYC (PAN, GST, bank account) before you can go live. Initiate KYC early — it can take 3–5 business days.
- **PCI scope:** Minimized because the SDK handles card collection — you never see raw card numbers. Your server is not in scope for PCI-DSS if you use the hosted payment sheet.
- **Never confirm fulfillment on client:** The client-side success callback from `CFPaymentGatewayService` is NOT a reliable signal. It can be intercepted or spoofed. Always wait for and verify the webhook before fulfilling.
- **Idempotency:** Cashfree retries webhooks on failure (up to 5 times). Your server's fulfillment logic must be idempotent — processing the same webhook twice must not create duplicate orders.

**Gotchas:**
- Cashfree test/sandbox and production use separate `APP_ID` / `SECRET_KEY` pairs and separate API endpoints (`sandbox.cashfree.com` vs `api.cashfree.com`). Use an environment flag to switch.
- UPI intent flows (GPay, PhonePe) require the payment app to be installed on the device and have slightly different deep-link handling. Test on a real Android device with UPI apps installed.
- iOS has stricter UPI support — UPI is primarily an Android flow. Card and wallet payments work on iOS.

**Common mistakes:**
- Fulfilling orders based on the client-side success callback — this is the single most dangerous mistake. Always verify the webhook server-side.
- Storing `APP_ID` or `SECRET_KEY` in the Flutter app (`--dart-define` or any client-visible location) — these must live only on your server. Exposure means anyone can create orders on your Cashfree account.
- Not handling webhook retries idempotently — duplicate fulfillment (double shipping, double crediting) is a real operational risk.
- Testing with production credentials — use the sandbox environment for all development and QA; production keys should only be in your production server's environment variables.

---

## Ads  (ads)

**Use for:** Free utility or content apps with sufficient daily active users to generate meaningful ad revenue. AdMob (Google) is the dominant Flutter-compatible ad network, offering banner, interstitial, rewarded, app-open, and native ad formats. Rewarded ads (watch an ad to unlock a feature or extra credits) add value without forcing monetization friction.

**Package:** `google_mobile_ads` (AdMob — includes Google's UMP consent SDK for GDPR compliance).

**Privacy prerequisites (mandatory before showing personalized ads):**
- **ATT (iOS 14.5+):** Request App Tracking Transparency permission via `app_tracking_transparency` **before** initializing the AdMob SDK with personalized ads enabled. Missing this causes App Store rejection and potential policy violations.
- **UMP consent (Android + iOS for GDPR/EEA users):** Use the Google UMP SDK (bundled in `google_mobile_ads`) to show a GDPR consent form before serving personalized ads to European users. Required for GDPR compliance.

**Setup:**
1. Register the app in AdMob Console and get an `App ID` (distinct from your ad unit IDs).
2. Add `App ID` to `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) and `Info.plist` (`GADApplicationIdentifier`). Missing this causes a crash on startup.
3. Use test ad unit IDs (`ca-app-pub-3940256099942544/...`) during development — using production unit IDs in dev risks AdMob account suspension.
4. Request ATT and UMP consent at an appropriate moment (before first ad load), then call `MobileAds.instance.initialize()`.
5. Load and show ads from the ad unit IDs defined in your AdMob Console.

**Ad format guidance:**
- **Banner:** Low revenue, always visible, high impression volume. Place at screen bottom, away from interactive controls — accidental taps violate AdMob policy.
- **Interstitial:** Higher revenue, shown at natural transition points (between levels, after completing a task). Do not interrupt the user mid-flow.
- **Rewarded:** Best UX; highest user acceptance; unlocks a temporary benefit (extra storage, ad-free hour). Users opt in — low annoyance.
- **App-open:** Shown on cold start. Revenue is good but be careful — a slow ad load blocks the splash screen. Set a timeout.

**Common mistakes:**
- Not requesting ATT before initializing AdMob with personalized ads on iOS — policy violation and potential account suspension.
- Using production ad unit IDs during development — AdMob detects suspicious traffic patterns and may suspend your account.
- Placing banners too close to interactive elements — AdMob policy prohibits ads designed to elicit accidental clicks.
- Showing interstitials too frequently (every 30 seconds) — destroys user experience and increases uninstall rate. Space them at natural breakpoints.

---

## Which to use

| What you're selling | Path | Package |
|---|---|---|
| Digital subscription (monthly/annual/lifetime) | RevenueCat (store IAP) | `purchases_flutter` |
| One-time in-app unlock or consumable credits | RevenueCat (store IAP) | `purchases_flutter` |
| Physical goods / real-world service (India) | Cashfree (direct gateway) | `flutter_cashfree_pg_sdk` + server |
| Utility bill, ticket, marketplace, B2B invoice (India) | Cashfree (direct gateway) | `flutter_cashfree_pg_sdk` + server |
| Free app, ad-supported | Ads (AdMob) | `google_mobile_ads` |
| Hybrid: free tier with ads + paid upgrade | Ads + RevenueCat (remove ads entitlement) | both |
| No monetization (internal tool, open source) | None | — |

> **Critical:** Never use Cashfree for digital in-app goods — this violates App Store and Play Store payment policies. Never use RevenueCat for real-world services — it is not designed for that and creates tax/regulatory complications. When in doubt: if the good is intangible and delivered inside the app, it is store IAP territory.
