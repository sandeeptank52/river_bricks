import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/box_encryption_key.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/secure_kv_store.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/storage_keys.dart';

class InMemorySecureKvStore implements SecureKvStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  group('obtainBoxEncryptionKey', () {
    test('generates and persists a key on first launch', () async {
      final store = InMemorySecureKvStore();
      final key = await obtainBoxEncryptionKey(store);
      expect(key, hasLength(32));
      expect(store.values[StorageKeys.boxEncryptionKey], isNotNull);
    });

    test('is idempotent: subsequent calls return the SAME key', () async {
      final store = InMemorySecureKvStore();
      final first = await obtainBoxEncryptionKey(store);
      final second = await obtainBoxEncryptionKey(store);
      expect(second, equals(first));
    });
  });
}
