# Testing Strategy

Default tier: **Solid** (matches the production-foundation.md baseline). The goal is a test suite that catches regressions quickly, runs in CI in under 5 minutes, and provides enough confidence to ship without a manual regression pass for routine changes.

The brick provides `test/helpers/notifier_tester.dart` with a `testNotifier` helper that handles Riverpod `AsyncNotifier`/`Notifier` setup with minimal boilerplate — all notifier tests should use it.

---

## Always (Solid default — required for every app)

### Unit tests — notifiers (highest ROI)

- [ ] Every Riverpod `AsyncNotifier` and `Notifier` has at least one unit test using `testNotifier` from `test/helpers/notifier_tester.dart`.
- [ ] Tests cover the happy path (correct state transitions), the error path (notifier handles exceptions and emits `AsyncError`), and any non-trivial business logic branch.
- [ ] External dependencies (repositories, HTTP clients, storage) are mocked using `mocktail` — notifier tests must not make real network calls or read real storage.
- [ ] Test files mirror the source structure: `lib/features/auth/auth_notifier.dart` → `test/features/auth/auth_notifier_test.dart`.

```dart
// Example using testNotifier (from test/helpers/notifier_tester.dart)
void main() {
  group('AuthNotifier', () {
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
    });

    test('login success emits authenticated state', () async {
      when(() => mockAuthRepo.signIn(any(), any()))
          .thenAnswer((_) async => fakeUser);

      await testNotifier(
        AuthNotifier.new,
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
        act: (notifier) => notifier.login('user@example.com', 'password'),
        expect: (state) => expect(state.value, equals(fakeUser)),
      );
    });

    test('login failure emits error', () async {
      when(() => mockAuthRepo.signIn(any(), any()))
          .thenThrow(AuthException('invalid_credentials'));

      await testNotifier(
        AuthNotifier.new,
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
        act: (notifier) => notifier.login('user@example.com', 'wrong'),
        expect: (state) => expect(state.hasError, isTrue),
      );
    });
  });
}
```

### Widget tests — key screens

- [ ] Widget tests for every screen that contains non-trivial conditional rendering: empty state, loading state, error state, and populated state.
- [ ] Widget tests use `ProviderScope` with overrides to inject fake providers — no real network or storage in widget tests.
- [ ] Widget tests verify user-facing text, key action buttons (tappable), and navigation outcomes (route pushed/popped).
- [ ] Use `pumpAndSettle` for animations; use `pump(Duration)` for async state transitions to avoid test timeouts.

### Static analysis

- [ ] `flutter analyze` produces zero errors and zero warnings. This is a CI gate — the pipeline fails if analyze is not clean.
- [ ] `dart format --set-exit-if-changed .` passes in CI — no unformatted code merged to main.
- [ ] Consider `very_good_analysis` or `flutter_lints` as the analysis options baseline; configure in `analysis_options.yaml`.

### CI integration

- [ ] `flutter test --coverage` runs on every PR. Consider a coverage gate (e.g., fail if coverage on `lib/features/` drops below 70%) using `lcov` and a coverage enforcement step.
- [ ] Test run time target: under 3 minutes for the full unit + widget suite in CI.
- [ ] Test results are published as CI artifacts so failures are visible without reading raw logs.

---

## Add by ingredient (include when the ingredient is selected)

### payments-revenuecat

- [ ] Test the purchase flow with a mocked `PurchasesFlutter` (use `mocktail` to mock the static interface or wrap it in a `PaymentService` abstraction).
- [ ] Test entitlement check: verify the app correctly gates features when `CustomerInfo.entitlements.active` is empty vs populated.
- [ ] Test restore purchases flow: mock `restorePurchases()` returning a `CustomerInfo` with active entitlements and verify the UI unlocks.
- [ ] Verify the paywall dismissal path does not leave the app in a broken state.

### payments-cashfree

- [ ] Test order creation: mock your server's order endpoint and verify the Flutter client correctly passes the `payment_session_id` to the SDK.
- [ ] Test payment success path: mock the SDK's success callback and verify the app shows a "processing" state (waiting for webhook — do not show "payment confirmed" on client callback alone).
- [ ] Test payment failure / cancellation path: verify graceful UI recovery and no duplicate order creation on retry.
- [ ] Integration test: end-to-end sandbox payment flow on a real Android device (UPI intent flows require a real device, not the simulator).

### offline-support

- [ ] Test the offline detection provider: mock `connectivity_plus` to return no connection and verify the app shows the offline indicator.
- [ ] Test the write queue: mock storage and verify that writes made while offline are enqueued, and flushed (in order) when connectivity returns.
- [ ] Test conflict behavior: verify the app's handling when a locally-queued write conflicts with a server state that changed while offline.

### cloud-sync

- [ ] Test sync-completed and sync-failed state transitions in the sync notifier using `testNotifier`.
- [ ] Test that the sync status indicator in the UI correctly reflects `syncing` / `synced` / `error` states.
- [ ] Test idempotency: running a sync twice with the same data should produce the same result without duplicate writes.

### ai-integration

- [ ] Test the AI service abstraction with a mocked HTTP client — verify request construction (headers, body, streaming flag).
- [ ] Test the rate-limit path: mock a 429 response from the server proxy and verify the UI shows an appropriate "try again later" message.
- [ ] Test streaming response parsing: verify that partial chunks are accumulated correctly and the UI updates incrementally.
- [ ] Contract test: if you control the server proxy, write a contract test that verifies the expected request/response schema has not drifted.
- [ ] Cost guard test: mock a user who has exceeded their daily token limit and verify they see the correct feature gate message.

### push-notifications

- [ ] Test cold-start deep link handling: mock `FirebaseMessaging.instance.getInitialMessage()` returning a message and verify the correct route is pushed.
- [ ] Test notification tap while app is in background: mock the `onMessageOpenedApp` stream and verify navigation.
- [ ] Test foreground notification display using `flutter_local_notifications`.

### authentication

- [ ] Test `authStateChanges()` stream: mock the stream emitting `null` (signed out) and a `User` (signed in) and verify the app routes correctly between auth and main app.
- [ ] Test sign-out: verify all local state (Riverpod providers, secure storage) is cleared on logout.
- [ ] Test token-expired path: if using a custom backend, verify the Dio interceptor correctly refreshes the token and retries the request.

---

## What NOT to over-test

- **Generated code** (`*.g.dart`, `router.gr.dart`, `*.freezed.dart`) — these are outputs of code generators. Testing them tests the generator, not your business logic. Generated files should be excluded from coverage reports.
- **Third-party package internals** — do not test that `firebase_auth.signIn()` calls the Firebase API. Trust the package; test your code that calls it.
- **UI pixel perfection** — golden file tests are fragile and expensive to maintain. Use widget tests to verify state-driven rendering, not visual accuracy.
- **Every getter/setter** — trivial data classes do not need unit tests. Focus test effort on notifiers, service classes, repositories, and any non-trivial logic.

---

## Test file organization

```
test/
  helpers/
    notifier_tester.dart      ← brick-provided testNotifier helper
    fake_providers.dart       ← shared fake/mock providers
    test_data.dart            ← test fixtures and factory builders
  features/
    auth/
      auth_notifier_test.dart
    home/
      home_screen_test.dart
    payments/
      payment_notifier_test.dart
  integration/
    payment_flow_test.dart    ← end-to-end payment sandbox test
```
