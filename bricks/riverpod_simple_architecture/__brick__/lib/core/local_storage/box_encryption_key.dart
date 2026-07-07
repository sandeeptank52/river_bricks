import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/secure_kv_store.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/storage_keys.dart';

/// Returns the Hive box encryption key, generating and persisting one in the
/// secure store on first launch. Idempotent: subsequent calls return the same
/// key, so the encrypted box stays readable across restarts.
Future<Uint8List> obtainBoxEncryptionKey(SecureKvStore store) async {
  final existing = await store.read(StorageKeys.boxEncryptionKey);
  if (existing != null) {
    return base64Url.decode(existing);
  }
  final key = Hive.generateSecureKey();
  await store.write(StorageKeys.boxEncryptionKey, base64UrlEncode(key));
  return Uint8List.fromList(key);
}
