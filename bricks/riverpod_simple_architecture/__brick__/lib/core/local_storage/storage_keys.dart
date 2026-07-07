/// Single registry for every persisted-storage identifier.
///
/// Box names and keys are part of the persisted-data contract: renaming one
/// orphans existing user data, so changes require a migration plan. Later
/// goals APPEND their keys here — never inline a storage key at a call site.
abstract final class StorageKeys {
  /// The app's single encrypted Hive box.
  static const String appBox = '{{project_name.snakeCase()}}_box';

  /// Secure-storage entry holding the Hive box encryption key.
  static const String boxEncryptionKey = '{{project_name.snakeCase()}}_box_key';

  /// Persisted [ThemeMode] name.
  static const String themeMode = 'theme';
}
