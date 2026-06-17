import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

/// Routes uncaught framework and async errors to both [talker] (always) and
/// [reporter]. Reporter failures are swallowed (logged to talker) so crash
/// reporting can never itself crash the app.
void wireCrashHandlers(CrashReporter reporter, Talker talker) {
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
    _safe(() => reporter.recordFlutterError(details), talker); // fire-and-forget; reporter failures handled inside _safe
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    _safe(() => reporter.recordError(error, stack, fatal: true), talker); // fire-and-forget; reporter failures handled inside _safe
    return true;
  };
}

void _safe(Future<void> Function() op, Talker talker) {
  try {
    op().catchError((Object e, StackTrace s) => talker.handle(e, s));
  } catch (e, s) {
    talker.handle(e, s);
  }
}
