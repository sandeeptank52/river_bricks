# Worked Example — planner output

This is a **complete example** of what `/flutter-app-planner` emits. It is not a
template to fill in by hand — it shows the shape and depth of the two files the
planner writes into a new project, so you know what to expect.

The example app: **"Lumen"**, an AI journaling app sold as a monthly
subscription, launching in the India + global market.

> The two sections below (`base-product-plan.md` and `ingredient-checklist.md`)
> are the two separate files the planner writes. They are shown together here for
> reference.

---
---

# 📄 base-product-plan.md

## 1. Product summary

**Lumen** is a private journaling app. Users write daily entries; an AI assistant
(Claude, server-proxied) offers reflective prompts, weekly summaries, and mood
insights. Free tier: 1 AI reflection/week. **Lumen Plus** (monthly/annual
subscription via store IAP): unlimited AI, cloud sync, and themes.

- **App type:** Subscription / SaaS / AI
- **Backend:** Firebase (Auth, Firestore, Functions, FCM, Remote Config, Crashlytics)
- **AI:** Claude via a Cloud Function proxy (no API key on device)
- **Markets:** Global + India → English + Hindi at launch
- **Monetization:** store IAP subscription via **RevenueCat** (digital goods →
  store IAP is mandatory; **Cashfree is explicitly excluded** by the conflict rule)

## 2. Interview answers → derivation

| Question | Answer | Effect |
|---|---|---|
| App type | Subscription / SaaS / AI | base bundle: authentication, payments-revenuecat, remote-config, onboarding |
| User accounts? | Yes | authentication |
| Monetization? | Digital subscription | payments-revenuecat + store-readiness |
| Direct India payments? | No (digital) | **payments-cashfree excluded** (conflict rule) |
| Works offline? | Yes | offline-support, local-database |
| Cloud sync? | Yes | cloud-sync (needs authentication ✓) |
| Real-time? | No | — |
| AI features? | Yes | ai-integration, rate-limiting |
| Rollout / kill-switch? | Yes | feature-flags, remote-config ✓ |
| Growth: referrals / A-B? | Yes | referral-system, experimentation-ab (+ deep-links prereq) |
| Push? | Yes | push-notifications |
| Admin / CMS? | No | — |
| Backend | Firebase | — |
| Multi-language (India)? | Yes | localization |

## 3. Architecture decisions

- **State:** Riverpod 3 notifiers (brick default). Entry list = `AsyncNotifier`
  backed by Hive (local) + Firestore (sync).
- **AI proxy:** `journalReflect` Cloud Function calls Anthropic with the server-held
  key, enforces the per-user rate limit, streams SSE back to the app.
- **Sync model:** local-first. Writes hit Hive immediately; a sync notifier flushes
  to Firestore on reconnect (`connectivity_plus`). Last-write-wins per entry.
- **Entitlements:** RevenueCat `CustomerInfo.entitlements.active['plus']`, checked
  reactively — never a local flag set at purchase time.

## 4. Key flows
1. Onboarding (3 screens, localized) → optional sign-in (anonymous auth allowed).
2. Write entry (works fully offline) → AI reflect (Plus-gated; paywall if free).
3. Paywall (RevenueCat) → purchase → entitlement unlocks AI + sync.
4. Referral: shared deep link → attribution → reward both users.

## 5. Analytics plan (key events)
`app_open`, `screen_view`, `sign_up`, `entry_created`, `ai_reflect_requested`,
`paywall_view`, `purchase_started`, `purchase_completed`, `referral_shared`,
`sync_completed`, `error_shown`. User-id = Firebase UID (never email/PII).

## 6. Security & privacy scope
- LLM key server-only; all AI proxied. Per-user rate limit + cost guard in the Function.
- Entries with sensitive content → Hive box encrypted with `HiveAesCipher`, AES key
  in `flutter_secure_storage`.
- **In-app account deletion** (Apple 5.1.1(v)) — deletes Auth account + Firestore docs.
- Privacy Nutrition Labels / Play Data Safety match actual collection.
- No tokens client-side if a web build is ever added (secure-storage is not secure on web).

## 7. Testing scope
- Notifier unit tests (`testNotifier`): entry CRUD, sync queue, entitlement gating.
- Widget tests: paywall, write screen, onboarding.
- Mocked purchase restore flow; mocked AI proxy (cost-guard path).
- `flutter analyze` + `dart format` clean in CI.

## 8. Release scope
Store metadata (EN + HI), screenshots, privacy policy URL live, ATT not needed
(no ads), Crashlytics symbols upload, TestFlight + Play internal track via CI.

## 9. Suggested build phases
- **MVP:** must-haves + authentication, onboarding, local-database, offline-support,
  ai-integration (+rate-limiting), payments-revenuecat, localization.
- **Fast-follow:** cloud-sync, push-notifications, remote-config, feature-flags.
- **Later:** referral-system (+deep-links), experimentation-ab.

## 10. Suggested folder structure
```
lib/
  features/
    journal/      (entry list, editor, local+sync notifiers)
    ai/           (reflect client, streaming UI)
    paywall/      (RevenueCat offerings, purchase flow)
    auth/
    onboarding/
    referral/
  shared/
    sync/         (connectivity + flush queue)
    observability/ (crash + talker, brick)
```

---
---

# ✅ ingredient-checklist.md

Tiers: ⬛ must-have · 🟦 recommended · 🟨 optional. (brick) = already provided.

| Ingredient | Tier | Package / service | Brick | Phase | Note |
|---|---|---|---|---|---|
| crash-reporting | ⬛ | firebase_crashlytics | ✓ | MVP | `bash tool/setup_firebase.sh` in the generated app |
| analytics | ⬛ | firebase_analytics | — | MVP | events per §5 |
| ci-cd | ⬛ | GitHub Actions | — | MVP | analyze+test+build gates |
| automated-testing | ⬛ | flutter_test + testNotifier | ✓ helper | MVP | notifier + widget tests |
| store-readiness | ⬛ | flutter_launcher_icons + fastlane | — | MVP | EN+HI metadata |
| privacy-basics | ⬛ | hosted policy + labels | — | MVP | + account deletion |
| secure-storage | ⬛ | flutter_secure_storage | ✓ | MVP | AES key for entry box |
| observability-talker | ⬛ | talker_flutter | ✓ | MVP | bootstrap-wired |
| theming-settings | ⬛ | flex_color_scheme | ✓ | MVP | /settings route |
| authentication | 🟦 | firebase_auth | — | MVP | anonymous → upgrade |
| localization | 🟦 | slang (+slang_build_runner) | ✓ | MVP | EN + HI |
| onboarding | 🟦 | introduction_screen | — | MVP | 3 localized screens |
| local-database | 🟦 | hive_ce | ✓ | MVP | local-first entries |
| ai-integration | 🟨 | anthropic_sdk_dart (server proxy) | — | MVP | Cloud Function, SSE |
| rate-limiting | 🟨 | Cloud Functions + Firestore counter | — | MVP | per-user cost guard |
| payments-revenuecat | 🟨 | purchases_flutter | — | MVP | `plus` entitlement |
| cloud-sync | 🟨 | Firestore | — | fast-follow | last-write-wins |
| push-notifications | 🟨 | firebase_messaging | — | fast-follow | daily reminder |
| remote-config | 🟦 | firebase_remote_config | — | fast-follow | tune limits/trials |
| feature-flags | 🟨 | firebase_remote_config | — | fast-follow | gate new AI modes |
| deep-links | 🟦 | app_links | — | later | referral attribution |
| referral-system | 🟨 | flutter_branch_sdk / app_links | — | later | needs deep-links |
| experimentation-ab | 🟨 | Firebase A/B Testing | — | later | paywall tests |

**Excluded by conflict rule:** `payments-cashfree` — Lumen sells a *digital*
subscription, so store IAP (RevenueCat) is mandatory and a third-party gateway
would violate App Store / Play policy.
