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

The nine ingredients above represent the minimum viable production posture — the
point at which you can ship to real users, support them when things go wrong, and
iterate with confidence. Crash reporting and observability (talker) are your eyes
in production: without them you cannot distinguish a real outage from a user
misunderstanding. Analytics closes the feedback loop between what you shipped and
what users actually do, while CI/CD ensures that every change passes a quality
gate before it reaches them. Together these three form the operational backbone
that makes everything else sustainable.

Secure storage, theming/settings, and privacy basics are the technical floor that
store reviewers and privacy regulations enforce regardless of your app's purpose.
`flutter_secure_storage` protects tokens and credentials from extraction on
compromised devices. The settings page (brick-provided via `flex_color_scheme` +
`SettingsPage`) gives users a canonical place to find theme controls, the privacy
policy URL, and app metadata — all fields that App Store and Play Store review
teams check. Privacy basics (ATT prompt, privacy policy, data safety declaration)
are no longer optional; both stores reject apps that omit them. Including all
three from day one avoids the scramble to add them under submission-deadline
pressure.

Automated testing and store readiness are included because they protect your
ability to move fast in the long run. Automated tests (backed by the brick's
`testNotifier` helper) catch regressions before they reach users; without them,
every sprint becomes slower as accumulated fear of breakage slows refactoring.
Store readiness — correct bundle IDs, icons, version scheme, signing — is a
one-time investment that saves repeated rejection cycles. Heavier ingredients
(authentication, payments, AI, push notifications, offline sync) are deliberately
left optional: they add significant complexity and each carries real tradeoffs
that depend on the app type, business model, and target market. The production
foundation gives you a stable, supportable base on top of which those decisions
can be made deliberately.
