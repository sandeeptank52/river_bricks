import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/persisted_state_contract.dart';

// keepAlive: logout reset is an app-wide privacy boundary. User-scoped
// providers watch this provider and rebuild from a fresh generation when auth
// signs out, even if the reset is triggered outside a screen scope.
final userSessionProvider =
    NotifierProvider<UserSessionController, UserSessionState>(
  UserSessionController.new,
  name: 'userSessionProvider',
);

class UserSessionState {
  const UserSessionState({this.logoutGeneration = 0});

  final int logoutGeneration;

  UserSessionState nextLogoutGeneration() {
    return UserSessionState(logoutGeneration: logoutGeneration + 1);
  }
}

class UserSessionController extends Notifier<UserSessionState> {
  @override
  UserSessionState build() {
    return const UserSessionState();
  }

  Future<void> logout({
    FutureOr<void> Function()? clearPersistedUserState,
  }) async {
    state = state.nextLogoutGeneration();
    await clearPersistedUserState?.call();
  }

  Future<void> logoutAndClearPersistedState() {
    return logout(
      clearPersistedUserState:
          ref.read(persistedStateStoreProvider).clearLogoutScopedState,
    );
  }
}

extension UserSessionScopedRef on Ref {
  /// Every user-scoped provider must call this so logout moves it to a fresh
  /// generation (see state_management_conventions.dart).
  int watchUserSessionScope() {
    return watch(userSessionProvider).logoutGeneration;
  }
}
