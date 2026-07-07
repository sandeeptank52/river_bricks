import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/storage_keys.dart';

final persistedStateStoreProvider = Provider.autoDispose<PersistedStateStore>(
  (ref) => PersistedStateStore(ref.watch(appStorageProvider)),
  name: 'persistedStateStoreProvider',
);

enum PersistedStateScope { app, userSession }

/// A persisted-state identifier with its lifetime scope. `userSession`-scoped
/// keys are cleared on logout; `app`-scoped keys survive it.
class PersistedStateKey {
  const PersistedStateKey({
    required this.storageKey,
    required this.scope,
    this.sensitive = false,
  });

  final String storageKey;
  final PersistedStateScope scope;
  final bool sensitive;

  bool get clearOnLogout => scope == PersistedStateScope.userSession;

  @override
  bool operator ==(Object other) {
    return other is PersistedStateKey &&
        other.storageKey == storageKey &&
        other.scope == scope &&
        other.sensitive == sensitive;
  }

  @override
  int get hashCode => Object.hash(storageKey, scope, sensitive);
}

/// Registry of every persisted-state key. Feature goals APPEND here (and add
/// their keys to the survival/clear lists below) — never inline a storage key
/// at a call site.
abstract final class PersistedStateKeys {
  static const language = PersistedStateKey(
    storageKey: 'app.language',
    scope: PersistedStateScope.app,
  );

  static const onboardedFlag = PersistedStateKey(
    storageKey: 'app.onboarded',
    scope: PersistedStateScope.app,
  );

  static const sessionToken = PersistedStateKey(
    storageKey: 'user.session_token',
    scope: PersistedStateScope.userSession,
    sensitive: true,
  );

  /// Persisted [ThemeMode] name — canonical [PersistedStateKey] for
  /// `StorageKeys.themeMode`, the same storage entry `ThemeModeController`
  /// reads/writes directly via `AppStorage`.
  static const themeMode = PersistedStateKey(
    storageKey: StorageKeys.themeMode,
    scope: PersistedStateScope.app,
  );

  static const mustSurviveProcessDeath = [
    language,
    onboardedFlag,
    sessionToken,
  ];

  static const clearOnLogout = [sessionToken];
}

class PersistedStateStore {
  const PersistedStateStore(this._storage);

  final AppStorage _storage;

  String? read(PersistedStateKey key) {
    return _storage.get(key: key.storageKey);
  }

  Future<void> write(PersistedStateKey key, String value) {
    return _storage.put(key: key.storageKey, value: value);
  }

  /// Removes [key] entirely (as opposed to [write]ing an empty value), so a
  /// subsequent [read] sees `null` again.
  Future<void> delete(PersistedStateKey key) {
    return _storage.appBox?.delete(key.storageKey) ?? Future<void>.value();
  }

  Future<void> clearLogoutScopedState() async {
    for (final key in PersistedStateKeys.clearOnLogout) {
      await delete(key);
    }
  }

  Future<void> purgeAllPersistedState() {
    return _storage.clearAllData();
  }
}
