---
name: flutter-app-planner
description: Use when starting a new Flutter app from this template — interviews the developer about the app, selects ingredients from the recipe book via the decision matrix, and writes a tailored base-product-plan.md + ingredient-checklist.md. Plan only; never writes feature code.
---

# Flutter App Planner

Plan a new app from the recipe book in `docs/app-recipe-book/`. **Plan only —
never scaffold or write feature code.**

## Flow

1. **Interview.** Ask the questions in `docs/app-recipe-book/claude-starter-prompt.md`,
   one cluster at a time. (Embedded below as a fallback — use this if the file
   is not open in the conversation.)
2. **Decide.** Apply `docs/app-recipe-book/decision-matrix.md`: start from the
   9 must-haves in `docs/app-recipe-book/production-foundation.md`, add the
   app-type base bundle, apply per-answer signals, then resolve conflict rules.
   All ingredient slugs come from `docs/app-recipe-book/ingredient-catalog.md`.
3. **Emit two files** into the target project (ask the developer for the path;
   default = the new project root):
   - `base-product-plan.md` — app-type recipe, backend, monetization, analytics
     plan, security/testing/release scope, suggested folder structure.
   - `ingredient-checklist.md` — every selected ingredient with tier, package,
     setup notes (pulled from `ingredient-catalog.md`), and brick-provided flag.
4. **Stop.** Hand back to the developer. Do not generate the app.

## Embedded interview (fallback)

> Use these questions verbatim when `docs/app-recipe-book/claude-starter-prompt.md`
> is not available in context. Ask clusters 1–4 first; they determine 80% of
> the ingredient set. Clusters 5–13 are refinements.

1. **App type?**
   Which of the four types best describes this app?
   - `Utility / tools` — single-purpose tool, immediate value, lean UI
   - `Content / feed` — content discovery and consumption loop
   - `Productivity / notes` — user creates and organizes their own content
   - `Subscription / SaaS / AI` — recurring subscription, LLM features, or
     usage-based SaaS model

2. **User accounts?**
   Do users need to create an account or sign in?
   `yes` → adds `authentication`
   `no` → app is fully anonymous / local

3. **Monetization model?**
   How does this app make money? (pick one or more)
   - `none` — free, no monetization planned yet
   - `digital subscription or in-app unlock` → adds `payments-revenuecat`
     *(App Store / Play Store IAP — required for digital goods)*
   - `direct payments, India market (physical goods / services)` → adds
     `payments-cashfree` *(server required; do NOT use for digital goods)*
   - `ad-supported free app` → adds `ads`

4. **Works offline?**
   Can users create or access content when there is no network connection?
   `yes` → adds `offline-support` + `local-database`
   `no` → network is required for core features

5. **Cloud sync across devices?**
   Should user data sync across phones, tablets, or after a reinstall?
   `yes` → adds `cloud-sync` *(authentication is a prerequisite — will be
   added if not already selected)*
   `no` → data is local to the device

6. **Real-time data?**
   Does the app need live-updating data — chat messages, live scores,
   collaborative editing, presence indicators?
   `yes` → informs backend choice (Firestore streams or Supabase Realtime;
   see `docs/app-recipe-book/backend-recipes.md`); no new ingredient slug
   `no` → request/response model is sufficient

7. **AI features?**
   Does the app use a large language model, generative AI, smart search, or
   other ML inference?
   `yes` → adds `ai-integration` + `rate-limiting` *(mandatory pairing — AI
   API costs must be guarded server-side)*
   `no` → no AI in scope

8. **Gradual rollout / kill-switch?**
   Do you need to enable features for a percentage of users, or disable a
   feature instantly without a store release?
   `yes` → adds `feature-flags` + `remote-config`
   `no` → all users get all features simultaneously

9. **Growth: referrals or A/B tests?**
   Does the app need a referral program or formal A/B experimentation?
   `yes` → adds `referral-system` + `experimentation-ab` *(deep-links will
   be added as a prerequisite for referrals if not already selected)*
   `no` → no growth infrastructure in scope at this stage

10. **Push notifications?**
    Does the app need to re-engage users via push — reminders, transactional
    alerts, new-content nudges?
    `yes` → adds `push-notifications`
    `no` → no push in scope

11. **Admin / content management?**
    Do non-developers need a web interface to manage content, users, or
    operations — beyond what Firebase Console provides?
    `yes` → adds `admin-panel-cms` *(consider Retool first before building
    custom)*
    `no` → developers manage via Firebase Console or the app itself

12. **Backend preference?**
    Which backend are you starting with?
    - `Firebase` *(default — Crashlytics already in the brick; lean setup)*
    - `Supabase` *(relational / SQL / RLS; Postgres-first teams)*
    - `Custom REST / GraphQL` *(existing server; full control)*
    - `Local-only` *(no backend, no sync — valid for utility and offline-first
      productivity apps)*

    If unsure: Firebase is the default. See `docs/app-recipe-book/backend-recipes.md`.

13. **Target markets / regulatory scope?**
    Are there specific regulatory requirements to account for?
    - India market with direct payments → confirm Cashfree server setup
    - EU / GDPR → explicit consent UI, data deletion endpoint required
    - Children (COPPA / GDPR-K) → no personalized analytics or ads
    - Financial / health data → consider `security-hardening-advanced`

### Tips for the interviewer (Claude)

- Ask clusters 1–4 first (type, accounts, monetization, offline). These four
  answers determine 80% of the ingredient set.
- Clusters 5–13 are refinements. If the developer doesn't know an answer, use
  the conservative default: no sync, no real-time, no AI, Firebase, no push.
- The decision matrix handles the rest deterministically. Do not improvise
  ingredient selections outside the matrix rows.
- If the developer selects "digital subscription" and also wants "direct
  payments (Cashfree)", flag the conflict rule: Cashfree is for physical goods
  / services only — it cannot be used for digital in-app content without
  violating App Store / Play policies.

## Output contract

After completing the interview and applying `decision-matrix.md`, emit exactly
two files into the target project directory.

### File 1: `base-product-plan.md`

A narrative product plan covering: app type + recipe, backend + rationale,
monetization approach, analytics plan (core events + type-specific), security /
privacy scope, testing scope, release checklist items, and suggested folder
structure (`lib/features/...` tree).

### File 2: `ingredient-checklist.md`

One row per selected ingredient (must-haves + base bundle + signal additions):

| Ingredient | Tier | Package / service | Brick-provided | Setup notes summary |
|---|---|---|---|---|
| crash-reporting | must-have | firebase_crashlytics | yes | Run `bash tool/setup_firebase.sh` |
| ... | ... | ... | ... | ... |

Pull tier, package, brick-provided flag, and setup notes summary directly from
`ingredient-catalog.md` for each selected slug.

### Stop rule

After writing both files, stop. State what was written and where. Do **NOT**:
- Scaffold any feature code or create any `lib/` files
- Generate `brick.yaml` variable / hook entries
- Run `mason make` or any build tooling
- Make further product decisions not grounded in the interview answers

**Plan only — the developer reads the plan, decides what to adjust, and then
builds.**

## Reference docs

All recipe-book docs live under `docs/app-recipe-book/` in this repo:

- `ingredient-catalog.md` — all 29 ingredient entries, classified and documented
- `decision-matrix.md` — deterministic engine: app type + answers → ingredient set
- `production-foundation.md` — the 9 must-have "Solid default" baseline
- `app-type-recipes.md` — the 4 concrete app-type recipes
- `backend-recipes.md` — Firebase / Supabase / custom / local-only
- `monetization-recipes.md` — RevenueCat vs Cashfree vs ads
- `analytics-events.md` — core + per-app-type event taxonomy
- `security-checklist.md` — secrets, storage, transport, auth, payments & PII
- `testing-strategy.md` — test pyramid per readiness tier
- `release-checklist.md` — store metadata, privacy / consent, CI/CD gates
- `template-integration-guide.md` — what the brick already provides vs. add-ons
- `claude-starter-prompt.md` — the full interview script with output contract
- `README.md` — index, how-to-use, how-to-extend
