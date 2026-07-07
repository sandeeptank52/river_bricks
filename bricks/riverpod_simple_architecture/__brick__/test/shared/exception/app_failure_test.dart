import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/exception/app_failure.dart';
import 'package:{{project_name.snakeCase()}}/shared/exception/base_exception.dart';

void main() {
  group('AppFailure.from', () {
    final options = RequestOptions(path: '/test');

    test('passes an existing AppFailure through unchanged', () {
      const failure = AuthFailure(message: 'expired');
      expect(AppFailure.from(failure), same(failure));
    });

    test('maps dio timeouts to TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final failure = AppFailure.from(
          DioException(requestOptions: options, type: type),
        );
        expect(failure, isA<TimeoutFailure>(), reason: '$type');
      }
    });

    test('maps connection errors to NetworkFailure', () {
      final failure = AppFailure.from(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      expect(failure, isA<NetworkFailure>());
    });

    test('maps bad responses to ServerFailure with status code', () {
      final failure = AppFailure.from(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 503),
        ),
      );
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    });

    test('maps cancellation to CancelledFailure', () {
      final failure = AppFailure.from(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      );
      expect(failure, isA<CancelledFailure>());
    });

    test('maps APIException to ServerFailure', () {
      final failure = AppFailure.from(
        APIException(statusCode: 401, errorMessage: 'unauthorized'),
      );
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 401);
      expect(failure.message, 'unauthorized');
    });

    test('maps anything else to UnknownFailure preserving the cause', () {
      final error = StateError('boom');
      final failure = AppFailure.from(error);
      expect(failure, isA<UnknownFailure>());
      expect(failure.cause, same(error));
    });
  });
}
