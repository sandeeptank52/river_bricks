import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

void main() {
  test('NoopCrashReporter completes every method without throwing', () async {
    const reporter = NoopCrashReporter();
    await reporter.recordError(Exception('x'), StackTrace.current);
    await reporter.recordFlutterError(
      FlutterErrorDetails(exception: Exception('x')),
    );
    await reporter.log('hello');
    await reporter.setCustomKey('k', 'v');
    // Reaching here without throwing is the assertion; make it explicit:
    expect(reporter, isA<CrashReporter>());
  });
}
