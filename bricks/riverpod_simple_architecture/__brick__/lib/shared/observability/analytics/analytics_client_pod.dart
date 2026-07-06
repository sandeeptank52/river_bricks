import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/analytics/analytics_client.dart';

/// The active [AnalyticsClient]. `createAppContainer` overrides this with a
/// [RecordingAnalyticsClient] in debug builds and [NoopAnalyticsClient] in
/// release builds; the analytics integration goal later binds real backends
/// through this SAME seam. Features must not care which implementation is
/// bound.
final analyticsClientPod = Provider<AnalyticsClient>(
  (ref) => const NoopAnalyticsClient(),
  name: 'analyticsClientPod',
);
