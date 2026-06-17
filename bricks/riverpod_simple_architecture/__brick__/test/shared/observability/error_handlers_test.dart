import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/error_handlers.dart';

class _SpyReporter implements CrashReporter {
  int flutterErrors = 0;
  int errors = 0;
  bool throwOnRecord = false;

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
      {bool fatal = false}) async {
    flutterErrors++;
    if (throwOnRecord) throw StateError('boom');
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false, String? reason}) async {
    errors++;
    if (throwOnRecord) throw StateError('boom');
  }

  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

void main() {
  final silentTalker = Talker(settings: TalkerSettings(enabled: false));
  FlutterExceptionHandler? original;
  setUp(() => original = FlutterError.onError);
  tearDown(() => FlutterError.onError = original);

  test('routes a FlutterError to the reporter', () {
    final spy = _SpyReporter();
    wireCrashHandlers(spy, silentTalker);
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('x')));
    expect(spy.flutterErrors, 1);
  });

  test('a throwing reporter does not crash the handler', () {
    final spy = _SpyReporter()..throwOnRecord = true;
    wireCrashHandlers(spy, silentTalker);
    // Must not throw synchronously:
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('x')));
    expect(spy.flutterErrors, 1);
  });
}
