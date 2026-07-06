import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/persisted_state_contract.dart';

/// THE single router seam.
///
/// The router, its guards, and the splash page read ONLY the three providers
/// below. The scaffold ships them mock/storage-backed; the real onboarding
/// and auth feature goals later re-point ONLY this file at their feature
/// state — no other router file is ever edited by another goal.

/// keepAlive: router guard state is app-wide infrastructure — the router's
/// reevaluateListenable must keep observing it across screens.
final onboardingStateProvider =
    NotifierProvider<OnboardingStateController, bool>(
  OnboardingStateController.new,
  name: 'onboardingStateProvider',
);

final onboardingCompleteProvider = Provider<bool>(
  (ref) => ref.watch(onboardingStateProvider),
  name: 'onboardingCompleteProvider',
);

/// keepAlive: see [onboardingStateProvider].
final mockAuthStateProvider =
    NotifierProvider<MockAuthStateController, MockAuthState>(
  MockAuthStateController.new,
  name: 'mockAuthStateProvider',
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(mockAuthStateProvider).isAuthenticated,
  name: 'isAuthenticatedProvider',
);

final authResolvingProvider = Provider<bool>(
  (ref) => ref.watch(mockAuthStateProvider).isResolving,
  name: 'authResolvingProvider',
);

/// Storage-backed onboarding completion flag. The onboarding feature calls
/// [markComplete] after its last step; the flag survives process death via
/// [PersistedStateKeys.onboardedFlag].
class OnboardingStateController extends Notifier<bool> {
  @override
  bool build() {
    return _storeOrNull()?.read(PersistedStateKeys.onboardedFlag) == 'true';
  }

  Future<void> markComplete() async {
    state = true;
    await _storeOrNull()?.write(PersistedStateKeys.onboardedFlag, 'true');
  }

  PersistedStateStore? _storeOrNull() {
    // Storage may be absent in bare test containers; treat that as
    // "not onboarded" rather than crashing router construction.
    try {
      return ref.read(persistedStateStoreProvider);
    } on Object {
      return null;
    }
  }
}

/// Mock auth state. The auth feature goal replaces this with its real session
/// controller and re-points [isAuthenticatedProvider]/[authResolvingProvider]
/// above (and ONLY those).
class MockAuthState {
  const MockAuthState({
    this.isAuthenticated = false,
    this.isResolving = false,
  });

  final bool isAuthenticated;
  final bool isResolving;
}

class MockAuthStateController extends Notifier<MockAuthState> {
  @override
  MockAuthState build() => const MockAuthState();

  void signIn() => state = const MockAuthState(isAuthenticated: true);

  void signOut() => state = const MockAuthState();

  void setResolving({required bool resolving}) =>
      state = MockAuthState(isResolving: resolving);
}
