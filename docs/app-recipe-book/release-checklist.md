# Release Checklist

A pre-submission checklist for every production release. Work through these sections top-to-bottom before submitting to App Store Connect or Google Play Console. Items marked with a condition `(if X)` apply only when that ingredient is included.

---

## Store metadata

### Both stores
- [ ] App name matches the registered trademark / brand — consistent across iOS and Android.
- [ ] Short description / subtitle: under 30 characters (iOS), 80 characters (Android) — compelling, no keyword stuffing.
- [ ] Full description: written for humans, not search crawlers. Lead with the core value proposition. Include a feature list. Keep it under 4,000 characters.
- [ ] Keywords: iOS only — 100-character field, comma-separated, no spaces around commas, no repetition of words already in the title/subtitle.
- [ ] Screenshots: required for every supported device size — iPhone 6.9", iPhone 6.5", iPad Pro 12.9" for iOS; phone + 7" tablet for Android at minimum. Screenshots must show real app UI, not marketing imagery only.
- [ ] App Preview video (iOS) / promotional video (Android): optional but strongly recommended for complex apps. 15–30 seconds. Recorded on a real device.
- [ ] App icon: 1024×1024 source PNG (no transparency on iOS, no rounded corners — the store adds them). Generate all sizes via `flutter_launcher_icons`.
- [ ] Category: Primary and secondary categories selected appropriately. Miscategorization can reduce discoverability.
- [ ] Age rating / content rating: complete both the App Store age rating questionnaire and the Google Play content rating questionnaire accurately. Inaccurate ratings cause rejection.

### iOS-specific
- [ ] Bundle ID (`com.company.appname`) matches across Xcode, App Store Connect, Firebase, and any associated domains.
- [ ] Version and build number set: `CFBundleShortVersionString` (e.g., `1.2.0`) and `CFBundleVersion` (monotonically increasing integer or semver build number).
- [ ] App Store Connect app record created and the Xcode scheme's bundle ID matches.
- [ ] TestFlight external testing approved before public release — at least one external beta cycle for major releases.
- [ ] Promotional text (up to 170 characters above the description) updated with this release's highlight — it can be changed without a new app review.

### Android-specific
- [ ] `versionName` and `versionCode` set in `build.gradle` — `versionCode` must be strictly increasing with every upload.
- [ ] Signing configuration set for release build type using a keystore stored outside the repo. Keystore password in CI secrets.
- [ ] Target SDK version set to the current Android API level requirement (Google Play enforces a minimum target SDK deadline each year — check the current requirement).
- [ ] App size optimized — use `flutter build appbundle` (not APK) for Play Store uploads; AAB enables per-device delivery, reducing download size.

---

## Privacy & consent

- [ ] Privacy policy URL is live and accessible from a public URL — this is the same URL stored in the brick's `privacy_url` build variable and shown in `SettingsPage`'s `AboutSection`.
- [ ] Privacy policy accurately describes: what data is collected, why, how it is stored, how long it is retained, whether it is shared with third parties, and how users can request deletion.
- [ ] **App Store Privacy Nutrition Labels** filled accurately in App Store Connect under "App Privacy" — every data type collected (analytics, crash data, user IDs, etc.) must be declared. Mismatch between declaration and actual collection is grounds for rejection and potential enforcement action.
- [ ] **Google Play Data Safety** form filled accurately — declare all data types collected and whether they are shared with third parties. Identical accuracy requirement.
- [ ] `(if ads)` ATT prompt (`app_tracking_transparency`) is shown before AdMob initializes with personalized ads on iOS. `NSUserTrackingUsageDescription` key added to `Info.plist` with a clear, honest description.
- [ ] `(if ads)` Google UMP consent form shown before personalized ads for GDPR/EEA users. UMP integration tested with a VPN to a European country.
- [ ] `(if analytics with third-party tools)` Third-party analytics SDKs declared in App Store Privacy Labels and Play Data Safety.
- [ ] `(if authentication)` In-app account deletion implemented. **Apple Guideline 5.1.1(v) makes this a hard rejection**: an app that supports account creation must let the user *initiate* deletion from within the app (a web link alone is not sufficient on iOS). Deletion must remove the Auth account + associated data (Firebase: delete the Firestore user document + `FirebaseAuth` account). Document it in the privacy policy.
- [ ] `(if push-notifications)` `NSUserNotificationUsageDescription` added to `Info.plist` (iOS). Push Notifications entitlement enabled in Xcode Signing & Capabilities.
- [ ] `(if camera / location / microphone)` All `NS*UsageDescription` keys added to `Info.plist` with honest, specific descriptions. System permission prompts are triggered only after in-context rationale is shown.

---

## CI/CD gates

All of the following must pass as automated CI gates — human review should not be the last line of defense for these.

- [ ] `flutter analyze` exits with code 0 — no errors, no warnings. Configured as a required status check on the main branch.
- [ ] `dart format --set-exit-if-changed .` exits with code 0 — no unformatted files.
- [ ] `flutter test` exits with code 0 — all unit and widget tests pass.
- [ ] `flutter build apk --release --no-codesign` exits with code 0 — the Android release build compiles cleanly.
- [ ] `flutter build ios --release --no-codesign` exits with code 0 — the iOS release build compiles cleanly (run on macOS CI runner).
- [ ] `flutter build appbundle --release` exits with code 0 — the Play Store bundle builds cleanly (can share the macOS runner).
- [ ] **Crashlytics dSYM/symbols upload configured** — for iOS, the Crashlytics Xcode build phase is in place (added by `setup_firebase.sh`); for Android, the `firebaseCrashlyticsMappingFileUploadEnabled true` flag is set in `build.gradle`. Symbolicated crash reports are confirmed in the Firebase Console after a test crash on a release build.
- [ ] `(if ci-cd ingredient)` Deployment lane (TestFlight / Play internal track) triggered automatically on merge to `main` or on a tagged commit, using credentials stored in CI secrets.
- [ ] `(if ci-cd ingredient)` Slack / email notification sent on pipeline failure — no silent CI failures.
- [ ] Build artifacts (APK, IPA, appbundle) are archived as CI artifacts for the release commit — allows rollback investigation without rebuilding.
- [ ] Release notes / changelog updated for this version before submission.
- [ ] Git tag created for the release commit (`vMAJOR.MINOR.PATCH`) so the build is traceable from the app version to the exact source state.
