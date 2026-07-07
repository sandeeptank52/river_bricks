import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/async_failure_message.dart';

typedef AsyncValueDataBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

typedef AsyncValueErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  String message,
);

/// The one shared loading/error/data renderer, wired to the [AppFailure]
/// message mapper so error copy stays consistent app-wide.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.errorMessageMapper = defaultAsyncFailureMessage,
    super.key,
  });

  final AsyncValue<T> value;
  final AsyncValueDataBuilder<T> data;
  final WidgetBuilder? loading;
  final AsyncValueErrorBuilder? error;
  final AsyncFailureMessageMapper errorMessageMapper;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (value) => data(context, value),
      loading: () {
        return loading?.call(context) ?? const AsyncValueLoadingView();
      },
      error: (failure, stackTrace) {
        final message = errorMessageMapper(failure, stackTrace);
        return error?.call(context, failure, stackTrace, message) ??
            AsyncValueErrorView(message: message);
      },
    );
  }
}

class AsyncValueLoadingView extends StatelessWidget {
  const AsyncValueLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

class AsyncValueErrorView extends StatelessWidget {
  const AsyncValueErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
