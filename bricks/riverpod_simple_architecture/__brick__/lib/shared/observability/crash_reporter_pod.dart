import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter.dart';

/// The active [CrashReporter]. Defaults to a no-op so the app runs without
/// Firebase. `tool/setup_firebase.sh` replaces the no-op below with the
/// Firebase implementation.
final crashReporterPod = Provider<CrashReporter>(
  // FIREBASE_CRASH_REPORTER (do not remove — setup_firebase.sh swaps the line below)
  (ref) => const NoopCrashReporter(),
  name: 'crashReporterPod',
);
