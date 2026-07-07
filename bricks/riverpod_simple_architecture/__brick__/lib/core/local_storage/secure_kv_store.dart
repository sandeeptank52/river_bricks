import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal secure key-value contract so callers (and tests) never depend on
/// `flutter_secure_storage` directly.
abstract interface class SecureKvStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain/Keystore-backed implementation.
class KeychainSecureKvStore implements SecureKvStore {
  const KeychainSecureKvStore();

  // AES-GCM with RSA key wrapping on Android (requires minSdk 23+) and
  // first-unlock keychain access on iOS.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final secureKvStorePod = Provider<SecureKvStore>(
  (ref) => const KeychainSecureKvStore(),
  name: 'secureKvStorePod',
);
