# App Building Recipe Book Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an in-repo recipe book (`docs/app-recipe-book/`) plus a committed `/flutter-app-planner` Claude skill that interviews a developer, applies a decision matrix, and emits a tailored `base-product-plan.md` + `ingredient-checklist.md` — plan only, no code generation.

**Architecture:** 13 markdown reference docs under `docs/app-recipe-book/` form the knowledge base; a single skill at `.claude/skills/flutter-app-planner/SKILL.md` consumes them via interview → decision-matrix → emit. The `ingredient-catalog.md` is the backbone every other doc references; `decision-matrix.md` is the deterministic selection engine. Everything lives in the repo so it travels to any developer who clones it.

**Tech Stack:** Markdown docs; Claude Code skill (SKILL.md with YAML frontmatter). Target apps are Flutter (Riverpod 3 / auto_route 11 / flex_color_scheme 8 / hive_ce / talker), generated from the `riverpod_simple_architecture` Mason brick.

## Global Constraints

- **Plan-only output.** The skill emits `base-product-plan.md` + `ingredient-checklist.md` and stops. No feature code, no scaffolding, no `brick.yaml` var/flag mapping manifest.
- **Portability.** All artifacts live inside the repo (`docs/app-recipe-book/` and `.claude/skills/`). No dependency on a personal `~/.claude`.
- **Four app types only:** Utility/tools, Content/feed, Productivity/notes, Subscription·SaaS·AI.
- **Lean defaults:** backend default = Firebase; analytics default = Firebase; both documented as per-app decisions (also Supabase / custom / local-only; PostHog / Mixpanel·Amplitude).
- **Readiness bar = "Solid default."** Must-have baseline: crash reporting, analytics, CI/CD, automated testing, store-readiness & metadata, privacy basics, secure storage, error logging/observability (talker), theming & settings.
- **Payments are two distinct ingredients:** store IAP/subscriptions → **RevenueCat**; direct payment gateway (India) → **Cashfree** (server-side, KYC/webhook).
- **Classification tiers (exactly one per ingredient):** `must-have` · `recommended` · `optional` · `avoid-unless-needed`.
- **Brick-provided ingredients must be marked as already available** wherever they appear (Crashlytics, talker, secure storage, theming, settings/about, local DB via hive_ce, localization via slang).
- **Every catalog entry documents:** why it matters · when to include · when NOT to · suggested package(s)/service(s) · setup notes · common mistakes.

### Canonical ingredient classification (authoritative — use verbatim)

`must-have`: crash-reporting, analytics, ci-cd, automated-testing, store-readiness, privacy-basics, secure-storage, observability-talker, theming-settings.

`recommended`: authentication, onboarding, deep-links, remote-config, performance-monitoring, local-database.

`optional`: payments-revenuecat, payments-cashfree, push-notifications, offline-support, cloud-sync, feature-flags, referral-system, ai-integration, experimentation-ab, ads.

`avoid-unless-needed`: admin-panel-cms, rate-limiting, background-jobs, security-hardening-advanced.

> Note: `secure-storage`, `observability-talker`, `theming-settings`, `local-database`, and `crash-reporting` are **brick-provided** — mark accordingly.

---

## File Structure

Created under `docs/app-recipe-book/`:

| File | Responsibility | Task |
|---|---|---|
| `ingredient-catalog.md` | Every ingredient, classified, with the 6 documented fields | 1 |
| `production-foundation.md` | The must-have "Solid default" baseline + rationale | 2 |
| `template-integration-guide.md` | Which ingredients the brick already provides; template-improvement notes | 3 |
| `backend-recipes.md` | Firebase / Supabase / custom / local-only — pick-per-app | 4 |
| `monetization-recipes.md` | RevenueCat vs Cashfree vs ads | 5 |
| `analytics-events.md` | Standard event taxonomy + per-app-type events | 6 |
| `security-checklist.md` | Secrets, storage, transport, auth, payment/PII | 7 |
| `testing-strategy.md` | What to test per readiness tier | 8 |
| `release-checklist.md` | Store metadata, privacy/consent, CI/CD gates | 8 |
| `decision-matrix.md` | (app type + answers) → ingredient set; deterministic engine | 9 |
| `app-type-recipes.md` | The 4 concrete recipes | 10 |
| `claude-starter-prompt.md` | The interview script | 11 |
| `README.md` | Index, how-to, how-to-extend | 13 |

Created under `.claude/skills/`:

| File | Responsibility | Task |
|---|---|---|
| `flutter-app-planner/SKILL.md` | Interview → matrix → emit; embeds starter prompt | 12 |

**Verification note (applies to every doc task):** "acceptance checks" are `grep`/structure assertions, not unit tests. Run them from the repo root.

---

### Task 1: Ingredient catalog (backbone)

**Files:**
- Create: `docs/app-recipe-book/ingredient-catalog.md`

**Interfaces:**
- Produces: the canonical ingredient slugs (kebab-case, listed in Global Constraints) and their classification tags. Every later doc references these exact slugs.

- [ ] **Step 1: Define the acceptance check**

Each of the 25 ingredient slugs from "Canonical ingredient classification" must appear as a level-2 heading `## <slug>` and carry a `**Classification:** <tier>` line plus the six required field labels.

- [ ] **Step 2: Write the doc**

Structure:
```markdown
# Ingredient Catalog

> Every ingredient Claude may select for a new app. One entry per ingredient.
> Tiers: must-have · recommended · optional · avoid-unless-needed.
> "Brick-provided" means the riverpod_simple_architecture brick already ships it.

## crash-reporting
**Classification:** must-have  ·  **Brick-provided:** yes (Firebase Crashlytics)
- **Why it matters:** <prose>
- **When to include:** <prose>
- **When NOT to:** <prose>
- **Suggested package/service:** firebase_crashlytics; alt Sentry (sentry_flutter)
- **Setup notes:** <prose; reference bricks/.../tool/setup_firebase.sh>
- **Common mistakes:** <prose>

## analytics
**Classification:** must-have  ·  **Brick-provided:** no
- ... (same 6 fields; default firebase_analytics, alt PostHog/Mixpanel)
```
Write one such entry for **every** slug in the Global Constraints list (all 25). Use the exact slug as the heading. Set `Brick-provided: yes` for crash-reporting, observability-talker, theming-settings, secure-storage, local-database; `no` otherwise. For payments-revenuecat use `purchases_flutter`; for payments-cashfree note `flutter_cashfree_pg_sdk` + a server for order creation/webhooks.

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && \
for s in crash-reporting analytics ci-cd automated-testing store-readiness privacy-basics secure-storage observability-talker theming-settings authentication onboarding deep-links remote-config performance-monitoring local-database payments-revenuecat payments-cashfree push-notifications offline-support cloud-sync feature-flags referral-system ai-integration experimentation-ab ads admin-panel-cms rate-limiting background-jobs security-hardening-advanced; do \
  grep -q "^## $s$" ingredient-catalog.md || echo "MISSING heading: $s"; done; \
echo "Classification lines: $(grep -c '\*\*Classification:\*\*' ingredient-catalog.md) (expect 29)"
```
Expected: no `MISSING heading` lines; `Classification lines: 29`.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/ingredient-catalog.md
git commit -m "docs(recipe-book): add ingredient catalog (classified backbone)"
```

---

### Task 2: Production foundation (Solid default baseline)

**Files:**
- Create: `docs/app-recipe-book/production-foundation.md`

**Interfaces:**
- Consumes: the 9 `must-have` slugs from Task 1.
- Produces: the canonical "every app gets these" list referenced by decision-matrix and app-type recipes.

- [ ] **Step 1: Define the acceptance check**

The doc lists all 9 must-have ingredients, each linked to its catalog entry (`[crash-reporting](ingredient-catalog.md#crash-reporting)`), and states the rationale for "Solid default."

- [ ] **Step 2: Write the doc**

```markdown
# Production Foundation — the "Solid default" baseline

Every production app generated from this book includes these 9 ingredients by
default, regardless of app type. They are the floor for shippable, supportable
software. Items marked (brick) are already provided by the brick.

1. [crash-reporting](ingredient-catalog.md#crash-reporting) (brick)
2. [analytics](ingredient-catalog.md#analytics)
3. [ci-cd](ingredient-catalog.md#ci-cd)
4. [automated-testing](ingredient-catalog.md#automated-testing)
5. [store-readiness](ingredient-catalog.md#store-readiness)
6. [privacy-basics](ingredient-catalog.md#privacy-basics)
7. [secure-storage](ingredient-catalog.md#secure-storage) (brick)
8. [observability-talker](ingredient-catalog.md#observability-talker) (brick)
9. [theming-settings](ingredient-catalog.md#theming-settings) (brick)

## Why this is the default
<2-3 paragraphs: pragmatic production baseline, what each guards against,
why heavier modules are left optional.>
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && grep -c 'ingredient-catalog.md#' production-foundation.md
```
Expected: `9` (or more).

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/production-foundation.md
git commit -m "docs(recipe-book): add production foundation (Solid default)"
```

---

### Task 3: Template integration guide

**Files:**
- Create: `docs/app-recipe-book/template-integration-guide.md`

**Interfaces:**
- Consumes: catalog slugs (Task 1); brick facts.

- [ ] **Step 1: Define the acceptance check**

A table maps each brick-provided ingredient to where the brick provides it; a "template improvement recommendations" section exists.

- [ ] **Step 2: Write the doc**

```markdown
# Template Integration Guide

How recipe-book ingredients map onto the riverpod_simple_architecture brick.

## Already provided by the brick
| Ingredient | Provided by | Notes |
|---|---|---|
| crash-reporting | Firebase Crashlytics + wireCrashHandlers | run `bash tool/setup_firebase.sh` |
| observability-talker | talker logging | bootstrap-wired |
| secure-storage | flutter_secure_storage 10 | Android minSdk 23 |
| theming-settings | flex_color_scheme 8 + SettingsPage/AboutSection | /settings route |
| local-database | hive_ce | |
| localization | slang | |

## Add-on ingredients (not in the brick)
<bullet list: analytics, ci-cd, payments-*, push, etc. — "add these per the plan">

## Template improvement recommendations
<concrete suggestions: e.g., add analytics interface like CrashReporter,
add a CI workflow template, add a feature-flag/remote-config seam.>
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && grep -q "Already provided by the brick" template-integration-guide.md && grep -q "Template improvement recommendations" template-integration-guide.md && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/template-integration-guide.md
git commit -m "docs(recipe-book): add template integration guide"
```

---

### Task 4: Backend recipes

**Files:**
- Create: `docs/app-recipe-book/backend-recipes.md`

- [ ] **Step 1: Define the acceptance check**

Doc has a `## ` section for each of: Firebase (default), Supabase, Custom REST/GraphQL, Local-only; plus a "How to choose" decision block.

- [ ] **Step 2: Write the doc**

```markdown
# Backend Recipes

Backend is chosen per app. Firebase is the lean default (matches the brick's
Crashlytics work). Document covers fit, services, auth story, cost, and
gotchas for each.

## Firebase (default)
- **Best for:** <app types> ; **Services:** Auth, Firestore, Functions, FCM, Remote Config, Crashlytics
- **Auth:** firebase_auth ; **Realtime:** Firestore streams ; **Cost:** <notes> ; **Gotchas:** <notes>

## Supabase
- **Best for:** relational/SQL needs ; Postgres + RLS + Realtime + Storage + Edge Functions ; supabase_flutter ; gotchas

## Custom REST / GraphQL
- typed client (dio + retrofit / ferry) ; when you own the server ; auth via JWT ; gotchas

## Local-only (no backend)
- hive_ce (brick) ; when no sync/accounts needed ; upgrade path to a backend later

## How to choose
| Signal | Backend |
|---|---|
| Realtime + quick start | Firebase |
| Relational data / SQL / RLS | Supabase |
| Existing server / full control | Custom |
| No accounts, no sync | Local-only |
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && for h in Firebase Supabase "Custom REST" Local-only "How to choose"; do grep -q "$h" backend-recipes.md || echo "MISSING: $h"; done; echo done
```
Expected: no `MISSING` lines.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/backend-recipes.md
git commit -m "docs(recipe-book): add backend recipes"
```

---

### Task 5: Monetization recipes

**Files:**
- Create: `docs/app-recipe-book/monetization-recipes.md`

- [ ] **Step 1: Define the acceptance check**

Doc covers RevenueCat (store IAP/subscriptions), Cashfree (direct gateway, India, server-side), and Ads as separate sections, plus a "which to use" table; references catalog slugs `payments-revenuecat`, `payments-cashfree`, `ads`.

- [ ] **Step 2: Write the doc**

```markdown
# Monetization Recipes

Two payment paths are fundamentally different — do not conflate them.

## Store IAP & subscriptions — RevenueCat  (payments-revenuecat)
- **Use for:** digital goods/subscriptions inside the app (App Store / Play rules require store IAP)
- **Package:** purchases_flutter ; **Server:** optional (RevenueCat hosts receipts/entitlements)
- **Flow:** paywall → purchase → entitlement check ; **Gotchas:** store review, restore purchases, sandbox testing
- **Common mistakes:** rolling your own receipt validation; missing restore; gating with no offline grace

## Direct payment gateway — Cashfree  (payments-cashfree)
- **Use for:** real-world goods/services, India market, where store IAP does NOT apply
- **Package:** flutter_cashfree_pg_sdk ; **Server REQUIRED:** create order + verify webhook server-side
- **Flow:** server creates order → SDK collects payment → server verifies webhook → fulfill
- **Compliance:** KYC, PCI scope minimized via SDK, never trust client-confirmed payment
- **Common mistakes:** confirming fulfillment on client; using a gateway for digital goods (store rejection)

## Ads  (ads)
- **Use for:** free utility/content apps ; google_mobile_ads (AdMob)
- **Privacy:** ATT (iOS) + GDPR/UMP consent required before personalized ads

## Which to use
| What you sell | Path |
|---|---|
| Digital subscription / in-app unlock | RevenueCat (store IAP) |
| Physical goods / real-world service (India) | Cashfree |
| Free app, ad-supported | Ads |
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && for k in RevenueCat Cashfree "Server REQUIRED" AdMob "Which to use"; do grep -q "$k" monetization-recipes.md || echo "MISSING: $k"; done; echo done
```
Expected: no `MISSING` lines.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/monetization-recipes.md
git commit -m "docs(recipe-book): add monetization recipes (RevenueCat vs Cashfree vs ads)"
```

---

### Task 6: Analytics events taxonomy

**Files:**
- Create: `docs/app-recipe-book/analytics-events.md`

- [ ] **Step 1: Define the acceptance check**

Doc has a "Core events (all apps)" section and a per-app-type events section for each of the 4 app types; events use `snake_case` names.

- [ ] **Step 2: Write the doc**

```markdown
# Analytics Events

Naming: snake_case, verb_noun. Default sink: firebase_analytics (swap per backend).

## Core events (all apps)
| Event | When | Key params |
|---|---|---|
| app_open | cold/warm start | source |
| screen_view | route change | screen_name |
| sign_up / login / logout | auth lifecycle | method |
| error_shown | user-facing error | code |
| settings_changed | settings edit | key, value |

## Utility / tools
| tool_run | core action invoked | tool_name, result |

## Content / feed
| content_view, content_share, search_performed | ... | content_id, query |

## Productivity / notes
| item_created, item_completed, sync_completed | ... | item_type |

## Subscription / SaaS / AI
| paywall_view, purchase_started, purchase_completed, ai_request | ... | sku, model, tokens |
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && grep -q "Core events" analytics-events.md && for t in "Utility" "Content" "Productivity" "Subscription"; do grep -q "$t" analytics-events.md || echo "MISSING: $t"; done; echo done
```
Expected: no `MISSING` lines.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/analytics-events.md
git commit -m "docs(recipe-book): add analytics event taxonomy"
```

---

### Task 7: Security checklist

**Files:**
- Create: `docs/app-recipe-book/security-checklist.md`

- [ ] **Step 1: Define the acceptance check**

Doc has sections: Secrets, Storage, Transport, Auth, Payments & PII; each with concrete checklist items (`- [ ]`).

- [ ] **Step 2: Write the doc**

```markdown
# Security Checklist

## Secrets & keys
- [ ] No API keys in source / git history (use --dart-define / env, server-held secrets)
- [ ] Firebase config committed is OK; private service keys are NOT

## Storage
- [ ] Sensitive data in flutter_secure_storage (brick), not SharedPreferences
- [ ] Hive boxes with sensitive data encrypted

## Transport
- [ ] HTTPS only ; consider cert pinning only if threat model needs it (security-hardening-advanced)

## Auth
- [ ] Tokens in secure storage ; refresh handled ; logout clears all

## Payments & PII
- [ ] Never confirm payment/fulfillment on the client (see Cashfree recipe)
- [ ] Minimize PII collected; document it for privacy-basics
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && for h in Secrets Storage Transport Auth "Payments & PII"; do grep -q "$h" security-checklist.md || echo "MISSING: $h"; done; echo done
```
Expected: no `MISSING` lines.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/security-checklist.md
git commit -m "docs(recipe-book): add security checklist"
```

---

### Task 8: Testing strategy + release checklist

**Files:**
- Create: `docs/app-recipe-book/testing-strategy.md`
- Create: `docs/app-recipe-book/release-checklist.md`

- [ ] **Step 1: Define the acceptance check**

`testing-strategy.md` maps test scope to readiness tier and references the brick's `testNotifier` helper. `release-checklist.md` has store metadata, privacy/consent, and CI/CD gate sections.

- [ ] **Step 2: Write testing-strategy.md**

```markdown
# Testing Strategy

Default tier = Solid. Test pyramid for a brick-based app.

## Always (Solid default)
- [ ] Unit tests for notifiers via test/helpers/notifier_tester.dart (testNotifier)
- [ ] Widget tests for key screens
- [ ] `flutter analyze` clean in CI

## Add by ingredient
- Payments → purchase/restore flow tests (mock RevenueCat / Cashfree server)
- Offline/sync → conflict + queue tests
- AI → prompt/response contract + cost-guard tests

## What NOT to over-test
- Generated code (*.g.dart, router.gr.dart)
```

- [ ] **Step 3: Write release-checklist.md**

```markdown
# Release Checklist

## Store metadata
- [ ] App name, subtitle, description, keywords, screenshots, icon
- [ ] Org/bundle id, version+build set

## Privacy & consent
- [ ] Privacy policy URL (brick var privacy_url) live
- [ ] App Store privacy nutrition labels / Play Data Safety filled
- [ ] ATT / UMP consent if ads or tracking

## CI/CD gates
- [ ] analyze + test green ; build apk + ios --no-codesign pass
- [ ] Crashlytics dsym/symbols upload configured
```

- [ ] **Step 4: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && grep -q testNotifier testing-strategy.md && for h in "Store metadata" "Privacy & consent" "CI/CD gates"; do grep -q "$h" release-checklist.md || echo "MISSING: $h"; done; echo done
```
Expected: no `MISSING` lines.

- [ ] **Step 5: Commit**

```bash
git add docs/app-recipe-book/testing-strategy.md docs/app-recipe-book/release-checklist.md
git commit -m "docs(recipe-book): add testing strategy + release checklist"
```

---

### Task 9: Decision matrix (the engine)

**Files:**
- Create: `docs/app-recipe-book/decision-matrix.md`

**Interfaces:**
- Consumes: catalog slugs (Task 1), app types.
- Produces: the deterministic mapping the skill applies. Every ingredient named here MUST be a slug from Task 1.

- [ ] **Step 1: Define the acceptance check**

Doc has (a) a "base bundle per app type" table and (b) an "answer → ingredients" signal table. Every ingredient token used is a valid catalog slug.

- [ ] **Step 2: Write the doc**

```markdown
# Decision Matrix

Deterministic: same answers → same ingredient set. Start from the must-have
baseline (production-foundation.md), add the app-type base bundle, then apply
per-answer signals.

## Base bundle by app type (added on top of the 9 must-haves)
| App type | Adds |
|---|---|
| Utility / tools | (often nothing; ads or one-time unlock optional) |
| Content / feed | deep-links, remote-config, performance-monitoring |
| Productivity / notes | local-database, offline-support, onboarding |
| Subscription / SaaS / AI | authentication, payments-revenuecat, remote-config, onboarding |

## Per-answer signals
| Interview answer | Add ingredients |
|---|---|
| Has user accounts? → yes | authentication |
| Sells digital subscription/unlock? → yes | payments-revenuecat, store-readiness |
| Takes direct payments (India)? → yes | payments-cashfree |
| Works offline? → yes | offline-support, local-database |
| Needs cloud sync? → yes | cloud-sync |
| Real-time data? → yes | (backend: Firestore/Supabase Realtime — see backend-recipes) |
| Uses AI? → yes | ai-integration, rate-limiting |
| Needs gradual rollout / kill-switch? → yes | feature-flags, remote-config |
| Growth/referrals? → yes | referral-system, experimentation-ab |
| Ad-supported free app? → yes | ads |
| Admin/content management needed? → yes | admin-panel-cms |

## Conflict rules
- Digital goods → RevenueCat, NOT Cashfree (store policy).
- Local-only backend → drop cloud-sync; keep offline-support/local-database.
```

- [ ] **Step 3: Run the acceptance check (slug validity)**

Run from repo root:
```bash
cd docs/app-recipe-book && \
comm -23 \
  <(grep -oE '\b(authentication|onboarding|deep-links|remote-config|performance-monitoring|local-database|payments-revenuecat|payments-cashfree|push-notifications|offline-support|cloud-sync|feature-flags|referral-system|ai-integration|experimentation-ab|ads|admin-panel-cms|rate-limiting|background-jobs|security-hardening-advanced|crash-reporting|analytics|ci-cd|automated-testing|store-readiness|privacy-basics|secure-storage|observability-talker|theming-settings)\b' decision-matrix.md | sort -u) \
  <(grep -oE '^## [a-z-]+' ingredient-catalog.md | sed 's/^## //' | sort -u) \
| sed 's/^/UNKNOWN SLUG: /'; echo done
```
Expected: no `UNKNOWN SLUG` lines.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/decision-matrix.md
git commit -m "docs(recipe-book): add decision matrix (deterministic engine)"
```

---

### Task 10: App-type recipes

**Files:**
- Create: `docs/app-recipe-book/app-type-recipes.md`

**Interfaces:**
- Consumes: catalog, decision-matrix, backend/monetization/analytics docs.

- [ ] **Step 1: Define the acceptance check**

One `## ` section per app type (4 total), each containing all 9 sub-headings: Required modules, Optional modules, Backend fit, Key analytics events, Security concerns, Testing scope, Release checklist, Suggested folder structure, What the brick gives you.

- [ ] **Step 2: Write the doc**

For EACH of the 4 app types, write:
```markdown
## <App type>
- **Required modules:** <slugs from base bundle + must-haves>
- **Optional modules:** <slugs>
- **Backend fit:** <ref backend-recipes>
- **Key analytics events:** <ref analytics-events>
- **Security concerns:** <ref security-checklist items that apply>
- **Testing scope:** <ref testing-strategy>
- **Release checklist:** <ref release-checklist items that apply>
- **Suggested folder structure:** <lib/features/... tree>
- **What the brick gives you:** <list brick-provided items>
```
Use the four headings exactly: `## Utility / tools`, `## Content / feed`, `## Productivity / notes`, `## Subscription / SaaS / AI`.

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && echo "type sections: $(grep -cE '^## (Utility|Content|Productivity|Subscription)' app-type-recipes.md) (expect 4)"; echo "required-module bullets: $(grep -c 'Required modules' app-type-recipes.md) (expect 4)"
```
Expected: `type sections: 4`; `required-module bullets: 4`.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/app-type-recipes.md
git commit -m "docs(recipe-book): add the 4 app-type recipes"
```

---

### Task 11: Claude starter prompt (interview script)

**Files:**
- Create: `docs/app-recipe-book/claude-starter-prompt.md`

**Interfaces:**
- Produces: the interview question set, reused verbatim by the skill (Task 12). The answer keys MUST match the signal rows in decision-matrix.md.

- [ ] **Step 1: Define the acceptance check**

Doc lists numbered interview questions covering: app type (the 4), accounts, monetization (digital vs direct/India), offline, sync, realtime, AI, rollout/flags, growth, ads, admin — i.e. one question per decision-matrix signal.

- [ ] **Step 2: Write the doc**

```markdown
# Claude Starter Prompt — New App Interview

Ask these one cluster at a time. Then apply decision-matrix.md and emit
base-product-plan.md + ingredient-checklist.md. Do NOT write feature code.

1. **App type?** Utility/tools · Content/feed · Productivity/notes · Subscription·SaaS·AI
2. **User accounts?** yes/no  → authentication
3. **Monetization?** none · digital subscription/unlock (RevenueCat) · direct payments India (Cashfree) · ads
4. **Works offline?** yes/no
5. **Cloud sync across devices?** yes/no
6. **Real-time data?** yes/no
7. **AI features?** yes/no
8. **Need gradual rollout / kill-switch?** yes/no
9. **Growth: referrals / A-B tests?** yes/no
10. **Admin / content management?** yes/no
11. **Backend preference?** Firebase (default) · Supabase · custom · local-only

## Output contract
- Write `base-product-plan.md`: chosen app-type recipe, backend, monetization,
  analytics plan, security/testing/release scope, suggested folder structure.
- Write `ingredient-checklist.md`: each selected ingredient with tier, package,
  setup notes (pulled from ingredient-catalog.md), and "brick-provided" flag.
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
cd docs/app-recipe-book && echo "questions: $(grep -cE '^[0-9]+\. ' claude-starter-prompt.md) (expect >=11)"; grep -q "Output contract" claude-starter-prompt.md && echo "contract OK"
```
Expected: `questions: >=11`; `contract OK`.

- [ ] **Step 4: Commit**

```bash
git add docs/app-recipe-book/claude-starter-prompt.md
git commit -m "docs(recipe-book): add Claude starter prompt (interview script)"
```

---

### Task 12: The flutter-app-planner skill

**Files:**
- Create: `.claude/skills/flutter-app-planner/SKILL.md`

**Interfaces:**
- Consumes: all `docs/app-recipe-book/*.md`.
- Produces: invokable `/flutter-app-planner`.

- [ ] **Step 1: Define the acceptance check**

SKILL.md starts with valid YAML frontmatter (`name`, `description`), embeds the interview from claude-starter-prompt.md, references decision-matrix.md, and states the plan-only output contract + "no feature code" stop rule.

- [ ] **Step 2: Write the skill**

```markdown
---
name: flutter-app-planner
description: Use when starting a new Flutter app from this template — interviews the developer about the app, selects ingredients from the recipe book via the decision matrix, and writes a tailored base-product-plan.md + ingredient-checklist.md. Plan only; never writes feature code.
---

# Flutter App Planner

Plan a new app from the recipe book in `docs/app-recipe-book/`. **Plan only —
never scaffold or write feature code.**

## Flow
1. **Interview.** Ask the questions in `docs/app-recipe-book/claude-starter-prompt.md`,
   one cluster at a time. (Embedded below as a fallback.)
2. **Decide.** Apply `docs/app-recipe-book/decision-matrix.md`: start from the
   9 must-haves (production-foundation.md), add the app-type base bundle, apply
   per-answer signals, then resolve conflict rules.
3. **Emit two files** into the target project (ask for the path; default the new
   project root):
   - `base-product-plan.md` — app-type recipe, backend, monetization, analytics
     plan, security/testing/release scope, suggested folder structure.
   - `ingredient-checklist.md` — every selected ingredient with tier, package,
     setup notes (from ingredient-catalog.md), and brick-provided flag.
4. **Stop.** Hand back to the developer. Do not generate the app.

## Embedded interview (fallback)
<paste the numbered questions from claude-starter-prompt.md verbatim>

## Reference docs
- ingredient-catalog.md · decision-matrix.md · app-type-recipes.md ·
  backend-recipes.md · monetization-recipes.md · analytics-events.md ·
  security-checklist.md · testing-strategy.md · release-checklist.md ·
  template-integration-guide.md
```

- [ ] **Step 3: Run the acceptance check**

Run:
```bash
head -5 .claude/skills/flutter-app-planner/SKILL.md | grep -q '^name: flutter-app-planner' && grep -q "Plan only" .claude/skills/flutter-app-planner/SKILL.md && grep -q "decision-matrix.md" .claude/skills/flutter-app-planner/SKILL.md && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/flutter-app-planner/SKILL.md
git commit -m "feat(recipe-book): add /flutter-app-planner skill (interview -> plan)"
```

---

### Task 13: README index + full consistency verification

**Files:**
- Create: `docs/app-recipe-book/README.md`

- [ ] **Step 1: Define the acceptance check**

README links to all 12 other docs and to the skill; final cross-reference check confirms every ingredient slug referenced anywhere in the book exists in the catalog.

- [ ] **Step 2: Write the README**

```markdown
# App Building Recipe Book

A planning system for new Flutter apps built from the riverpod_simple_architecture
brick. Claude interviews you, picks ingredients via a decision matrix, and writes
a base product plan — it does NOT build the app.

## How to use
Run `/flutter-app-planner` (committed skill). Or paste claude-starter-prompt.md.

## Contents
- [production-foundation.md](production-foundation.md) — the Solid default
- [ingredient-catalog.md](ingredient-catalog.md) — all ingredients, classified
- [decision-matrix.md](decision-matrix.md) — the selection engine
- [app-type-recipes.md](app-type-recipes.md) — the 4 recipes
- [backend-recipes.md](backend-recipes.md)
- [monetization-recipes.md](monetization-recipes.md)
- [analytics-events.md](analytics-events.md)
- [security-checklist.md](security-checklist.md)
- [testing-strategy.md](testing-strategy.md)
- [release-checklist.md](release-checklist.md)
- [template-integration-guide.md](template-integration-guide.md)
- [claude-starter-prompt.md](claude-starter-prompt.md)

## How to extend
- New ingredient → add a classified entry to ingredient-catalog.md, then wire it
  into decision-matrix.md and any relevant app-type recipe.
- New app type → add a recipe section + a base-bundle row in decision-matrix.md.
```

- [ ] **Step 3: Run README link check**

Run:
```bash
cd docs/app-recipe-book && miss=0; for f in production-foundation ingredient-catalog decision-matrix app-type-recipes backend-recipes monetization-recipes analytics-events security-checklist testing-strategy release-checklist template-integration-guide claude-starter-prompt; do grep -q "$f.md" README.md || { echo "README missing link: $f"; miss=1; }; done; [ $miss -eq 0 ] && echo "links OK"
```
Expected: `links OK`.

- [ ] **Step 4: Run full cross-reference integrity check**

Run from repo root — confirms every slug used across all recipe docs exists as a catalog heading:
```bash
cd docs/app-recipe-book && \
catalog=$(grep -oE '^## [a-z-]+' ingredient-catalog.md | sed 's/^## //' | sort -u); \
used=$(grep -hoE '\b(authentication|onboarding|deep-links|remote-config|performance-monitoring|local-database|payments-revenuecat|payments-cashfree|push-notifications|offline-support|cloud-sync|feature-flags|referral-system|ai-integration|experimentation-ab|ads|admin-panel-cms|rate-limiting|background-jobs|security-hardening-advanced|crash-reporting|analytics|ci-cd|automated-testing|store-readiness|privacy-basics|secure-storage|observability-talker|theming-settings)\b' decision-matrix.md app-type-recipes.md production-foundation.md | sort -u); \
comm -23 <(echo "$used") <(echo "$catalog") | sed 's/^/ORPHAN SLUG: /'; echo "check done"
```
Expected: no `ORPHAN SLUG` lines; `check done`.

- [ ] **Step 5: Commit**

```bash
git add docs/app-recipe-book/README.md
git commit -m "docs(recipe-book): add README index + finalize cross-references"
```

---

## Self-Review (completed during planning)

**Spec coverage:** every spec section maps to a task — mechanism/skill §3.1→T12; file layout §3.2→T1-T13; classification §4→T1 (tiers locked in Global Constraints); Solid default §4.1→T2; decision matrix §5→T9; app-type recipes §6→T10; backend/monetization/analytics/security/testing/release→T4-T8; portability/plan-only→Global Constraints + T12 stop rule.

**Placeholder scan:** doc-body `<prose>`/`<slugs>` markers are deliberate authoring slots (the engineer fills app-specific text), not plan placeholders — each task pins exact headings, exact slugs, and a grep acceptance check so there are no open taste decisions.

**Type consistency:** ingredient slugs are defined once in Global Constraints + Task 1 and reused verbatim; Tasks 9/13 include slug-validity greps that fail loudly on any mismatch.
