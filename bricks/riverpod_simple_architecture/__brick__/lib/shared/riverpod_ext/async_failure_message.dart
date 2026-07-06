import 'package:{{project_name.snakeCase()}}/shared/exception/app_failure.dart';

typedef AsyncFailureMessageMapper = String Function(
  Object error,
  StackTrace stackTrace,
);

String defaultAsyncFailureMessage(Object error, StackTrace _) {
  return AppFailure.from(error).message;
}
