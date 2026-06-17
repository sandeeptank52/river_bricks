import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This one is extension `when` extension on AsyncValue
/// with some default loading,error widget and
///  also which also supports custom loading and error widget
extension AsyncDisplay<T> on AsyncValue<T> {
  Widget easyWhen({
    required Widget Function(T data) data,
    Widget Function(Object error, StackTrace stackTrace)? errorWidget,
    Widget Function()? loadingWidget,
    bool skipLoadingOnReload = false,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
    bool isLinear = false,
    VoidCallback? onRetry,
    bool includedefaultDioErrorMessage = false,
  }) =>
      when(
        data: data,
        error: (error, stackTrace) {
          return errorWidget != null
              ? errorWidget(
                  error,
                  stackTrace,
                )
              : DefaultErrorWidget(
                  isLinear: isLinear,
                  error: error,
                  stackTrace: stackTrace,
                  onRetry: onRetry,
                  includedefaultDioErrorMessage: includedefaultDioErrorMessage,
                );
        },
        loading: () {
          return loadingWidget != null
              ? loadingWidget()
              : DefaultLoadingWidget(
                  isLinear: isLinear,
                );
        },
        skipError: skipError,
        skipLoadingOnRefresh: skipLoadingOnRefresh,
        skipLoadingOnReload: skipLoadingOnReload,
      );
}

/// This class give defaut loading widget
class DefaultLoadingWidget extends StatelessWidget {
  const DefaultLoadingWidget({
    required this.isLinear,
    super.key,
  });
  final bool isLinear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLinear
          ? const LinearProgressIndicator()
          : const CircularProgressIndicator.adaptive(),
    );
  }
}

/// This widget supports error messages automatically
class DefaultErrorWidget extends StatelessWidget {
  const DefaultErrorWidget({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
    required this.isLinear,
    required this.includedefaultDioErrorMessage,
    super.key,
  });
  final Object error;
  final StackTrace stackTrace;
  final VoidCallback? onRetry;
  final bool isLinear;
  final bool includedefaultDioErrorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLinear
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorTextWidget(
                  error: error,
                  includedefaultDioErrorMessage: includedefaultDioErrorMessage,
                ),
                if (onRetry != null)
                  Flexible(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Try again '),
                    ),
                  )
                else
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Try Again later.'),
                    ),
                  ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1FF44336),
                    ),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ),
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Something went wrong! ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ),
                ErrorTextWidget(
                  error: error,
                  includedefaultDioErrorMessage: includedefaultDioErrorMessage,
                ),
                if (onRetry != null)
                  Flexible(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Try again '),
                    ),
                  )
                else
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Try Again later.'),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Shared styled, padded, flexible error message used by the default
/// error widgets below (replaces the previous velocity_x text helpers).
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message, {this.padding = 8});
  final String message;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

///This widgets classes default error messages
class ErrorTextWidget extends StatelessWidget {
  const ErrorTextWidget({
    required this.error,
    required this.includedefaultDioErrorMessage,
    super.key,
  });
  final Object error;
  final bool includedefaultDioErrorMessage;

  @override
  Widget build(BuildContext context) {
    if (includedefaultDioErrorMessage && error is DioException) {
      return DefaultDioErrorWidget(
        dioError: error as DioException,
      );
    }
    return _ErrorMessage(error.toString(), padding: 4);
  }
}

///This class used to show error message according to DioException type
class DefaultDioErrorWidget extends StatelessWidget {
  const DefaultDioErrorWidget({
    required this.dioError,
    super.key,
  });
  final DioException dioError;

  @override
  Widget build(BuildContext context) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return const _ErrorMessage('Connection Timeout Error', padding: 4);

      case DioExceptionType.sendTimeout:
        return const _ErrorMessage(
          'Unable to connect to the server.Please try again later.',
        );

      case DioExceptionType.receiveTimeout:
        return const _ErrorMessage(
          'Check you internet connection reliability.',
        );
      case DioExceptionType.badCertificate:
        return const _ErrorMessage(
          'Please update your OS or add certificate.',
        );

      case DioExceptionType.badResponse:
        return const _ErrorMessage(
          'Something went wrong.Please try again later.',
        );
      case DioExceptionType.cancel:
        return const _ErrorMessage('Request Cancelled', padding: 4);
      case DioExceptionType.connectionError:
        return const _ErrorMessage(
          'Unable to connect to server.Please try again later.',
        );
      case DioExceptionType.unknown:
        return const _ErrorMessage(
          'Please check your internet connection.',
        );
    }
  }
}
