import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/persisted_state_contract.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/user_session_scope.dart';

void main() {
  group('userSessionProvider', () {
    test(
      'logout resets user-scoped providers and preserves app-scoped ones',
      () async {
        var userBuilds = 0;
        var appBuilds = 0;

        final userScopedProvider = Provider.autoDispose<int>((ref) {
          ref.watchUserSessionScope();
          userBuilds += 1;
          return userBuilds;
        });
        final appScopedProvider = Provider.autoDispose<int>((ref) {
          appBuilds += 1;
          return appBuilds;
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final userSub = container.listen(
          userScopedProvider,
          (_, _) {},
          fireImmediately: true,
        );
        final appSub = container.listen(
          appScopedProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(userSub.close);
        addTearDown(appSub.close);

        expect(container.read(userScopedProvider), 1);
        expect(container.read(appScopedProvider), 1);

        await container.read(userSessionProvider.notifier).logout();
        await pumpEventQueue();

        expect(container.read(userScopedProvider), 2);
        expect(container.read(appScopedProvider), 1);
      },
    );

    test('logout runs the persisted-state clear hook', () async {
      var clearCalled = false;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(userSessionProvider.notifier).logout(
        clearPersistedUserState: () async {
          clearCalled = true;
        },
      );

      expect(clearCalled, isTrue);
      expect(container.read(userSessionProvider).logoutGeneration, 1);
    });

    test(
      'logoutAndClearPersistedState clears session-scoped keys only',
      () async {
        final appBox = await Hive.openBox(
          'userSessionScopeBox',
          bytes: Uint8List(0),
        );
        addTearDown(() async {
          await appBox.clear();
          await appBox.close();
        });
        final appStorage = AppStorage(appBox);
        final container = ProviderContainer(
          overrides: [appStorageProvider.overrideWithValue(appStorage)],
        );
        addTearDown(container.dispose);

        final store = container.read(persistedStateStoreProvider);
        await store.write(PersistedStateKeys.language, 'hi');
        await store.write(PersistedStateKeys.sessionToken, 'token-123');

        await container
            .read(userSessionProvider.notifier)
            .logoutAndClearPersistedState();

        expect(store.read(PersistedStateKeys.language), 'hi');
        expect(store.read(PersistedStateKeys.sessionToken), isNull);
        expect(container.read(userSessionProvider).logoutGeneration, 1);
      },
    );
  });
}
