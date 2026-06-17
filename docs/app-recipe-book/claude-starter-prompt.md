# Claude Starter Prompt — New App Interview

Ask these questions one cluster at a time. After the developer answers all of
them, apply [decision-matrix.md](decision-matrix.md) to derive the ingredient
set, then emit `base-product-plan.md` and `ingredient-checklist.md`.

**Do NOT write feature code.** The output is a plan — two markdown files. Stop
after emitting the files and hand back to the developer.

---

## Interview questions

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
   see [backend-recipes.md](backend-recipes.md)); no new ingredient slug
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

    If unsure: Firebase is the default. See [backend-recipes.md](backend-recipes.md).

13. **Target markets / regulatory scope?**
    Are there specific regulatory requirements to account for?
    - India market with direct payments → confirm Cashfree server setup
    - EU / GDPR → explicit consent UI, data deletion endpoint required
    - Children (COPPA / GDPR-K) → no personalized analytics or ads
    - Financial / health data → consider `security-hardening-advanced`

---

## Tips for the interviewer (Claude)

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

---

## Output contract

After completing the interview and applying [decision-matrix.md](decision-matrix.md),
emit exactly two files into the target project directory (ask for the path;
default: the project root).

### File 1: `base-product-plan.md`

A narrative product plan covering:

- **App type** and the recipe it maps to
  (cross-link to [app-type-recipes.md](app-type-recipes.md))
- **Backend** chosen and rationale
  (cross-link to [backend-recipes.md](backend-recipes.md))
- **Monetization** approach
  (cross-link to [monetization-recipes.md](monetization-recipes.md))
- **Analytics plan** — core events + type-specific events to instrument
  (cross-link to [analytics-events.md](analytics-events.md))
- **Security / privacy scope** — which checklist sections apply
  (cross-link to [security-checklist.md](security-checklist.md))
- **Testing scope** — what to test and how
  (cross-link to [testing-strategy.md](testing-strategy.md))
- **Release checklist** — which items apply for this app
  (cross-link to [release-checklist.md](release-checklist.md))
- **Suggested folder structure** — `lib/features/...` tree for this specific
  app, derived from the app-type recipe's suggestion

### File 2: `ingredient-checklist.md`

One row per selected ingredient (must-haves + base bundle + signal additions),
with:

| Ingredient | Tier | Package / service | Brick-provided | Setup notes summary |
|---|---|---|---|---|
| crash-reporting | must-have | firebase_crashlytics | yes | Run `bash tool/setup_firebase.sh` |
| ... | ... | ... | ... | ... |

Pull the tier, package, brick-provided flag, and setup notes summary directly
from [ingredient-catalog.md](ingredient-catalog.md) for each selected slug.
Mark brick-provided items clearly so the developer knows what is already
wired vs. what they need to add.

### Stop rule

After writing both files, stop. State what was written and where. Do **NOT**:
- Scaffold any feature code or create any `lib/` files
- Generate `brick.yaml` variable / hook entries
- Run `mason make` or any build tooling
- Make further product decisions not grounded in the interview answers

The developer reads the plan, decides what to adjust, and then builds.
