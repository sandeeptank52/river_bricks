import 'package:flutter/foundation.dart';

/// Pluggable crash/error reporter. The default [NoopCrashReporter] lets apps
/// run with no Firebase; `tool/setup_firebase.sh` swaps in a Firebase-backed
/// implementation.
abstract class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });

  Future<void> log(String message);

  Future<void> setCustomKey(String key, Object value);
}

/// Default reporter: does nothing. Errors are still logged via talker.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}
