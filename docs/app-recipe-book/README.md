# App Building Recipe Book

A planning system for new Flutter apps built from the
`riverpod_simple_architecture` Mason brick. Claude interviews you, picks
ingredients via a decision matrix, and writes a base product plan — it does
**NOT** build the app.

> _Last reviewed: 2026-06. Package recommendations are a snapshot — verify versions on pub.dev before relying on them._

## How to use

Run `/flutter-app-planner` (the committed Claude Code skill at
`.claude/skills/flutter-app-planner/SKILL.md`). Or open
[claude-starter-prompt.md](claude-starter-prompt.md) and paste it directly
into a Claude conversation.

Claude will ask 13 interview questions one cluster at a time, apply the
[decision-matrix.md](decision-matrix.md) to derive your ingredient set, then
emit two files into your new project directory:

- `base-product-plan.md` — the full product plan
- `ingredient-checklist.md` — every selected ingredient with package, tier,
  brick-provided flag, and setup notes

After the files are written, Claude stops. You read, adjust, and then build.
See [example-plan.md](example-plan.md) for a complete worked example of both
output files (a subscription AI app), so you know exactly what to expect.

## Contents

- [production-foundation.md](production-foundation.md) — the "Solid default" baseline: 9 must-have ingredients every production app gets
- [ingredient-catalog.md](ingredient-catalog.md) — all 30 ingredients, classified (must-have · recommended · optional · avoid-unless-needed) with the 6 documented fields each
- [example-plan.md](example-plan.md) — a fully worked example output (base product plan + ingredient checklist) for a subscription AI app
- [decision-matrix.md](decision-matrix.md) — the deterministic selection engine: app type + interview answers → ingredient set
- [app-type-recipes.md](app-type-recipes.md) — the 4 concrete app-type recipes (Utility/tools, Content/feed, Productivity/notes, Subscription/SaaS/AI)
- [backend-recipes.md](backend-recipes.md) — Firebase / Supabase / Custom REST / Local-only — pick per app
- [monetization-recipes.md](monetization-recipes.md) — RevenueCat (store IAP) vs Cashfree (direct, India) vs Ads
- [analytics-events.md](analytics-events.md) — core event taxonomy + per-app-type events
- [security-checklist.md](security-checklist.md) — Secrets, Storage, Transport, Auth, Payments & PII
- [testing-strategy.md](testing-strategy.md) — test pyramid per readiness tier, referencing the brick's testNotifier helper
- [release-checklist.md](release-checklist.md) — store metadata, privacy/consent, CI/CD gates
- [template-integration-guide.md](template-integration-guide.md) — what the brick already provides vs. add-on ingredients
- [claude-starter-prompt.md](claude-starter-prompt.md) — the full interview script + output contract

## How to extend

### Adding a new ingredient

1. Add a classified entry to [ingredient-catalog.md](ingredient-catalog.md)
   using the exact kebab-case slug as a `## <slug>` heading and fill in all
   six required fields (why it matters, when to include, when NOT to,
   suggested package/service, setup notes, common mistakes).
2. Wire the slug into [decision-matrix.md](decision-matrix.md) — add a row to
   the "Per-answer signals" table with the interview question that triggers it.
3. Add the ingredient to any relevant app-type recipe in
   [app-type-recipes.md](app-type-recipes.md) under "Required modules" or
   "Optional modules" as appropriate.

### Adding a new app type

1. Add a new recipe section in [app-type-recipes.md](app-type-recipes.md)
   using the same nine sub-headings (Required modules, Optional modules,
   Backend fit, Key analytics events, Security concerns, Testing scope,
   Release checklist, Suggested folder structure, What the brick gives you).
2. Add a new row to the "Base bundle by app type" table in
   [decision-matrix.md](decision-matrix.md) listing the ingredients added
   on top of the 9 must-haves.
3. Update question 1 of [claude-starter-prompt.md](claude-starter-prompt.md)
   and the embedded interview in `.claude/skills/flutter-app-planner/SKILL.md`
   to include the new type.
