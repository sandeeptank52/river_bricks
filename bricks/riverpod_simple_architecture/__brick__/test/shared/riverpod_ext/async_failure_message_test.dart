import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/async_failure_message.dart';

void main() {
  group('defaultAsyncFailureMessage', () {
    test('maps errors through AppFailure.from', () {
      final message = defaultAsyncFailureMessage(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.cancel,
        ),
        StackTrace.current,
      );
      expect(message, 'Request cancelled');
    });

    test('falls back to toString for unknown errors', () {
      final message = defaultAsyncFailureMessage(
        StateError('boom'),
        StackTrace.current,
      );
      expect(message, contains('boom'));
    });
  });
}
