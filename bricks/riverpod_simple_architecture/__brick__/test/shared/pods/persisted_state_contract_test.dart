import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/persisted_state_contract.dart';

void main() {
  group('PersistedStateContract', () {
    test('userSession-scoped keys clear on logout; app-scoped do not', () {
      expect(PersistedStateKeys.sessionToken.clearOnLogout, isTrue);
      expect(PersistedStateKeys.language.clearOnLogout, isFalse);
      expect(PersistedStateKeys.onboardedFlag.clearOnLogout, isFalse);
      expect(PersistedStateKeys.themeMode.clearOnLogout, isFalse);
      for (final key in PersistedStateKeys.clearOnLogout) {
        expect(key.scope, PersistedStateScope.userSession);
      }
    });

    test('sensitive keys are marked sensitive', () {
      expect(PersistedStateKeys.sessionToken.sensitive, isTrue);
      expect(PersistedStateKeys.language.sensitive, isFalse);
    });

    test('store round-trips, deletes, and clears logout-scoped state',
        () async {
      final appBox = await Hive.openBox(
        'persistedStateContractBox',
        bytes: Uint8List(0),
      );
      addTearDown(() async {
        await appBox.clear();
        await appBox.close();
      });
      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(AppStorage(appBox)),
        ],
      );
      addTearDown(container.dispose);
      final store = container.read(persistedStateStoreProvider);

      await store.write(PersistedStateKeys.language, 'ta');
      expect(store.read(PersistedStateKeys.language), 'ta');

      await store.delete(PersistedStateKeys.language);
      expect(store.read(PersistedStateKeys.language), isNull);

      await store.write(PersistedStateKeys.language, 'hi');
      await store.write(PersistedStateKeys.sessionToken, 'secret');
      await store.clearLogoutScopedState();
      expect(store.read(PersistedStateKeys.language), 'hi');
      expect(store.read(PersistedStateKeys.sessionToken), isNull);

      await store.purgeAllPersistedState();
      expect(store.read(PersistedStateKeys.language), isNull);
    });
  });
}
