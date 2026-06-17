# App Building Recipe Book — Design

**Date:** 2026-06-17
**Status:** Approved (design); pending spec review
**Repo:** `river_bricks` (Mason brick `bricks/riverpod_simple_architecture`)

## 1. Purpose

When starting a new Flutter app, Claude Code should **interview the developer about the
app, then select the right ingredients (modules/services) from a reusable recipe book and
emit a tailored base product plan** — *before* any code is written.

This is a **planning + documentation system**, not a code generator. It produces decisions
and a plan; building the app is a separate step done with the existing brick plus the
chosen add-on ingredients.

### Goals
- Turn "what kind of app is this?" into a deterministic, auditable ingredient selection.
- Document every ingredient once (why / when / when-not / packages / setup / mistakes).
- Ship a baseline ("Solid default") that every production app gets automatically.
- Be **portable** — everything lives in the repo and travels to any developer who clones it.

### Non-goals
- Not generating or modifying feature code (output is plan + checklist only).
- Not mapping decisions to specific `brick.yaml` vars/flags (kept separate; the book may
  *reference* existing brick features in prose, but does not produce a config manifest).
- Not scaffolding the app or running mason.

## 2. Decisions (from brainstorming)

| Topic | Decision |
|---|---|
| App types in scope | Utility/tools, Content/feed, Productivity/notes, Subscription/SaaS/AI |
| Backend | Documented as a per-app decision (Firebase / Supabase / custom / local-only); **Firebase is the lean default** given existing Crashlytics work |
| Analytics/observability | Documented per-app (Firebase / PostHog / Mixpanel-Amplitude); **Firebase is the lean default** |
| Readiness bar | **Solid default** — crash + analytics + CI/CD + testing + store-readiness + privacy basics baked in; heavier modules optional |
| Monetization | Store IAP/subscriptions (**RevenueCat**) and direct payment gateway (**Cashfree**, India-market, server-side) treated as **distinct** ingredients; ads optional |
| Output | **Plan only** — `base-product-plan.md` + `ingredient-checklist.md` |
| Portability | Hard requirement — in-repo docs + in-repo committed Claude skill |

## 3. Architecture

Two parts: the **mechanism** (how Claude consumes the book) and the **content** (the book).

### 3.1 Mechanism — in-repo skill + docs

A committed Claude skill at `.claude/skills/flutter-app-planner/SKILL.md`, backed by the
docs under `docs/app-recipe-book/`. Because it lives in the repo, any developer who clones
`river_bricks` gets `/flutter-app-planner` for free — no global `~/.claude` setup.

**Flow:**
1. **Interview** — ask the questions from `claude-starter-prompt.md`, one cluster at a time.
2. **Decide** — apply `decision-matrix.md` to the answers to produce the ingredient set.
3. **Emit** — write two files into the target project (path chosen at runtime, default the
   new project root or a `planning/` dir):
   - `base-product-plan.md` — tailored plan (chosen app-type recipe, backend, monetization,
     analytics plan, security/testing/release scope, suggested folder structure).
   - `ingredient-checklist.md` — every selected ingredient with its classification, the
     package/service to use, and setup notes pulled from `ingredient-catalog.md`.
4. **Stop.** No feature code. The developer (or a later Claude session) builds from the plan.

The skill **embeds the starter-prompt** so the same interview can be pasted into any chat as
a fallback when the skill isn't loaded.

**Rejected alternatives:** copy-paste-prompt-only (manual, not integrated); mason
hook/brick-var interview (mason prompts can't reason or branch).

### 3.2 Content — file layout

Under `docs/app-recipe-book/`:

| File | Purpose |
|---|---|
| `README.md` | What the book is, how to invoke the planner, index of all files, how to extend it |
| `production-foundation.md` | The "Solid default" baseline every app gets, with rationale |
| `ingredient-catalog.md` | **All** ingredients, each classified + why/when/when-not/packages/setup/mistakes |
| `decision-matrix.md` | (app type + interview answers) → ingredient set; the deterministic core |
| `app-type-recipes.md` | The 4 concrete recipes |
| `backend-recipes.md` | Firebase / Supabase / custom / local-only — pick-per-app guidance |
| `monetization-recipes.md` | Store IAP (RevenueCat) vs direct gateway (Cashfree) vs ads |
| `analytics-events.md` | Standard event taxonomy + per-app-type events |
| `security-checklist.md` | Secrets, storage, transport, auth, payment/PII handling |
| `testing-strategy.md` | What to test per readiness tier |
| `release-checklist.md` | Store metadata, privacy/consent, CI/CD gates |
| `claude-starter-prompt.md` | The interview script (also embedded in the skill) |
| `template-integration-guide.md` | Which ingredients the brick already provides vs. add-on, and template-improvement recommendations |

## 4. Ingredient classification

Every ingredient is tagged exactly one of:

- `must-have` — every production app gets it (part of the Solid default).
- `recommended` — most apps should have it; include unless there's a reason not to.
- `optional` — include only when the app type / answers call for it.
- `avoid-unless-needed` — adds cost/complexity; only with explicit justification.

Each catalog entry documents: **why it matters · when to include · when NOT to · suggested
Flutter package(s)/service(s) · setup notes · common mistakes**.

### 4.1 The Solid-default baseline (`must-have`)

Crash reporting · analytics · CI/CD · automated testing · store-readiness & metadata ·
privacy basics (policy + consent where required) · secure storage · error logging /
observability (talker) · theming & settings.

Several of these the brick already ships (Crashlytics, settings/about, talker, theming,
secure storage) — `template-integration-guide.md` records the mapping so the checklist can
mark them "already provided."

### 4.2 Optional / matrix-driven ingredients

Authentication · payments (RevenueCat / Cashfree) · push notifications · offline support ·
cloud sync · local database · deep links · remote config · feature flags · onboarding ·
referral system · AI integration · background jobs · experimentation/A-B · admin panel /
CMS · rate limiting · performance monitoring · advanced security hardening · ads.

## 5. Decision matrix

A table (or set of tables) keyed on interview signals so selection is deterministic, e.g.:

| Signal (from interview) | Implied ingredients |
|---|---|
| Has user accounts? | auth, secure storage (already), session handling |
| Sells subscriptions / unlocks? | RevenueCat, paywall, store-readiness for IAP |
| Takes direct payments (India)? | Cashfree, server-side order/webhook flow, PCI/PII care |
| Works offline? | local DB (hive_ce — already), offline queue; optional cloud sync |
| Real-time data? | streams/realtime backend (Firestore/Supabase Realtime) |
| Uses AI? | AI integration recipe, cost/rate limiting, prompt-safety |
| Content-heavy / editorial? | CMS/remote content, caching, deep links |
| Needs gradual rollout / kill-switch? | remote config, feature flags |
| Growth-focused? | referral, experimentation, onboarding |

App type sets the starting bundle; individual answers add/remove ingredients on top.

## 6. App-type recipes (each)

For each of the 4 types, document: **required modules · optional modules · backend fit ·
key analytics events · security concerns · testing scope · release checklist · suggested
folder/file structure · "what the brick already gives you."**

1. **Utility / tools** — often local-only; minimal backend; ads or one-time unlock common.
2. **Content / feed** — CMS/API backend, caching, deep links; analytics-heavy.
3. **Productivity / notes** — offline-first, local DB, optional cloud sync; subscription common.
4. **Subscription / SaaS / AI** — auth + payments (RevenueCat ± Cashfree) + remote config +
   AI; the heaviest recipe.

## 7. Out of scope / future

- Brick-var/flag mapping manifest (a future "Plan + brick mapping" mode).
- Auto-scaffolding chosen ingredients into generated code.
- Additional app-type recipes (marketplace, social, finance, real-time/chat) — add later
  using the same recipe template.

## 8. Success criteria

- Running `/flutter-app-planner` interviews the developer and writes a coherent,
  app-specific `base-product-plan.md` + `ingredient-checklist.md`.
- Every ingredient referenced in output is defined and classified in `ingredient-catalog.md`.
- The decision matrix yields the same ingredient set for the same answers (deterministic).
- A second developer can clone the repo and use the planner with no extra setup.
- The Solid-default baseline appears in every generated plan, with brick-provided items
  marked as already available.
