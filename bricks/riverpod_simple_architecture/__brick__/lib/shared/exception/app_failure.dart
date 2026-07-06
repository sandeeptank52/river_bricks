import 'package:dio/dio.dart';
import 'package:{{project_name.snakeCase()}}/shared/exception/base_exception.dart';

/// Canonical typed-failure hierarchy for the app.
///
/// Data and controller layers map raw errors to an [AppFailure] before
/// anything crosses into widgets. Widgets render failures via messages keyed
/// off the failure type — they never inspect raw exceptions.
sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.cause});

  /// Developer-facing description (logs/reports). Not for direct display;
  /// UI layers translate the failure *type* into localized text.
  final String message;

  /// The underlying error, preserved for crash reporting.
  final Object? cause;

  /// Maps any thrown object to a typed failure. Extend the mapping here —
  /// never at call sites — so classification stays consistent app-wide.
  static AppFailure from(Object error) {
    return switch (error) {
      final AppFailure failure => failure,
      final DioException dio => _fromDio(dio),
      final APIException api => ServerFailure(
          message: api.errorMessage,
          statusCode: api.statusCode,
          cause: api,
        ),
      _ => UnknownFailure(message: error.toString(), cause: error),
    };
  }

  static AppFailure _fromDio(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        TimeoutFailure(
          message: error.message ?? 'Request timed out',
          cause: error,
        ),
      DioExceptionType.connectionError => NetworkFailure(
          message: error.message ?? 'Connection failed',
          cause: error,
        ),
      DioExceptionType.badResponse => ServerFailure(
          message: error.message ?? 'Server returned an error',
          statusCode: error.response?.statusCode,
          cause: error,
        ),
      DioExceptionType.cancel => CancelledFailure(
          message: 'Request cancelled',
          cause: error,
        ),
      DioExceptionType.badCertificate || DioExceptionType.unknown =>
        NetworkFailure(message: error.message ?? 'Network error', cause: error),
    };
  }
}

/// No connectivity / connection-level errors.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({required super.message, super.cause});
}

/// The operation exceeded its deadline.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({required super.message, super.cause});
}

/// The backend answered with an error status.
final class ServerFailure extends AppFailure {
  const ServerFailure({required super.message, this.statusCode, super.cause});
  final int? statusCode;
}

/// Session/credential problems (expired, rejected, revoked).
final class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, super.cause});
}

/// Input rejected by local or server-side validation.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.cause});
}

/// Local persistence errors (Hive/secure storage).
final class StorageFailure extends AppFailure {
  const StorageFailure({required super.message, super.cause});
}

/// A required platform permission is missing or denied.
final class PermissionFailure extends AppFailure {
  const PermissionFailure({required super.message, super.cause});
}

/// The caller cancelled the operation; usually rendered silently.
final class CancelledFailure extends AppFailure {
  const CancelledFailure({required super.message, super.cause});
}

/// Anything not yet classified. Mapping something here is a signal to add a
/// proper variant, not to handle it at the call site.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({required super.message, super.cause});
}
