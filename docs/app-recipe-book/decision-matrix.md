# Decision Matrix

Deterministic: same answers → same ingredient set. Start from the must-have
baseline ([production-foundation.md](production-foundation.md)), add the
app-type base bundle below, then layer per-answer signals on top. Resolve
conflict rules last.

This is the engine the `/flutter-app-planner` skill runs through after the
[claude-starter-prompt.md](claude-starter-prompt.md) interview is complete.

---

## Base bundle by app type (added on top of the 9 must-haves)

The nine must-haves — crash-reporting, analytics, ci-cd, automated-testing,
store-readiness, privacy-basics, secure-storage, observability-talker,
theming-settings — are present for every app type. The table below lists
only what is **added** on top of that baseline.

| App type | Adds (on top of 9 must-haves) |
|---|---|
| Utility / tools | *(nothing required — ads or one-time unlock are optional signals below)* |
| Content / feed | deep-links, remote-config, performance-monitoring |
| Productivity / notes | local-database, offline-support, onboarding |
| Subscription / SaaS / AI | authentication, payments-revenuecat, remote-config, onboarding |

> **Rationale:**
> - **Utility / tools** apps are the leanest of the four. The 9 must-haves are
>   sufficient to ship and support a solid utility. Any monetization or
>   engagement layer is a per-signal decision.
> - **Content / feed** apps drive discoverability via links, benefit from
>   server-side config to tune feed algorithms without store releases, and need
>   performance monitoring because image-heavy lists reveal latency problems
>   invisible in the emulator.
> - **Productivity / notes** apps are offline-first by nature. Users write
>   notes on the subway; losing that data is unforgivable. The base bundle
>   gives them persistent local storage, offline writes, and an onboarding flow
>   that frames the offline-first value proposition.
> - **Subscription / SaaS / AI** apps require accounts (entitlements follow the
>   user), store IAP (required by app-store policy for digital goods), remote
>   config (to tune pricing and trial lengths without a release), and onboarding
>   (paywall placement and value communication are the highest-ROI screen in
>   this app type).

---

## Per-answer signals

Each row maps one interview answer to the ingredient(s) that answer activates.
Apply all matching rows. The union of (must-haves + base bundle + signal rows)
minus (conflict rule exclusions) is the final ingredient set.

| Interview answer | Add ingredients | Notes |
|---|---|---|
| Has user accounts? → yes | authentication | Required for cross-device sync, entitlements, social features |
| Sells digital subscription or in-app unlock? → yes | payments-revenuecat, store-readiness | App Store / Play Store policy mandates store IAP for digital goods |
| Takes direct payments — physical goods / services, India market? → yes | payments-cashfree | Server required; never for digital goods (see conflict rules) |
| Works offline? → yes | offline-support, local-database | Queue writes locally; flush on reconnect |
| Needs cloud sync across devices? → yes | cloud-sync | Requires authentication as a prerequisite |
| Real-time data (chat, live scores, collaboration)? → yes | *(backend choice: Firestore streams or Supabase Realtime — see [backend-recipes.md](backend-recipes.md))* | No new ingredient slug; backend selection drives architecture |
| Uses AI features (LLM, generative, smart search)? → yes | ai-integration, rate-limiting | rate-limiting is mandatory alongside ai-integration (cost guard) |
| Needs gradual rollout / kill-switch for features? → yes | feature-flags, remote-config | remote-config is the typical backing store for simple boolean flags |
| Growth: referrals or A/B tests? → yes | referral-system, experimentation-ab | deep-links is a prerequisite for referral-system |
| Ad-supported free app? → yes | ads | Activates privacy-basics obligations: ATT (iOS) + UMP consent |
| Admin / content management needed by non-developers? → yes | admin-panel-cms | Avoid unless Firebase Console / Retool cannot meet the need |
| Push notifications (re-engagement, transactional)? → yes | push-notifications | Request permission at value moment, not on first launch |
| Multiple languages / non-English market (e.g. India, EU)? → yes | localization | Brick-provided via slang — low cost; route strings through it from day one |

> **Prerequisites not enforced automatically:**
> - cloud-sync → requires authentication (add it if not already selected)
> - referral-system → requires deep-links (add it if not already selected)
> - ads → strengthens privacy-basics obligations (already in must-haves, but
>   ATT + UMP consent flow must be explicitly implemented)
> - ai-integration → always pair with rate-limiting

---

## Conflict rules

These rules override any combination of signals. Apply them after assembling
the union of must-haves + base bundle + signal rows.

| Condition | Rule |
|---|---|
| Digital goods / subscriptions selected | Use **payments-revenuecat** (store IAP). **Do NOT include payments-cashfree** — using a third-party payment gateway for digital content violates App Store and Google Play policies and risks removal. |
| Local-only backend selected (no server, no sync) | **Drop cloud-sync** from the ingredient set. Keep offline-support and local-database — they function without a backend. Also drop authentication unless the app has a reason to auth against a local identity provider. |
| ads selected | Must explicitly implement the ATT prompt (iOS 14.5+) and Google UMP consent flow — these are not automatic even though privacy-basics is in the must-have set. |
| ai-integration selected | **Always also include rate-limiting** — AI API costs can spike to hundreds of dollars from a handful of users. This is a hard pairing, not optional. (`rate-limiting` is tiered `avoid-unless-needed` in the catalog — that means "don't add it gratuitously," and AI is precisely the case where it *is* needed.) |
| referral-system selected | **Always also include deep-links** — referral attribution requires universal/app links to survive a fresh install. |

---

## How the skill applies this matrix

1. Confirm app type → look up base bundle row.
2. Start ingredient set = `{9 must-haves} ∪ {base bundle}`.
3. For each interview answer, look up the signal row and add the listed slugs.
4. Add any prerequisites triggered by the additions (cloud-sync → authentication,
   referral-system → deep-links, ai-integration → rate-limiting).
5. Apply conflict rules — remove or replace as directed.
6. Emit the final set as `ingredient-checklist.md`.

Reference: [ingredient-catalog.md](ingredient-catalog.md) has the full entry
(classification, package, setup notes, common mistakes) for every slug above.
