import 'package:talker_flutter/talker_flutter.dart';

/// App-wide analytics facade. Features log through this interface only —
/// never through an SDK directly. Real backends are bound in the analytics
/// integration goal; until then debug builds log events and release builds
/// no-op. No analytics SDK is a dependency of the scaffold.
abstract interface class AnalyticsClient {
  String get anonymousId;

  Future<void> initialize();
  Future<void> logEvent(String name, [Map<String, Object?> parameters]);
  Future<void> setConsent(AnalyticsConsent consent);
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
}

enum AnalyticsConsent { granted, denied }

/// Production-safe default: does nothing.
class NoopAnalyticsClient implements AnalyticsClient {
  const NoopAnalyticsClient();

  @override
  String get anonymousId => 'anonymous';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {}

  @override
  Future<void> setConsent(AnalyticsConsent consent) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}

/// Debug/test client: records every call and mirrors it to the logger so
/// funnels are visible during development and assertable in tests.
class RecordingAnalyticsClient implements AnalyticsClient {
  RecordingAnalyticsClient({this.talker, String? anonymousId})
      : _anonymousId = anonymousId ?? 'anonymous';

  final Talker? talker;
  final String _anonymousId;

  final List<({String name, Map<String, Object?> parameters})> events = [];
  final Map<String, String?> userProperties = {};
  final List<AnalyticsConsent> consents = [];
  String? userId;

  @override
  String get anonymousId => _anonymousId;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    events.add((name: name, parameters: parameters));
    talker?.info('analytics: $name $parameters');
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) async {
    consents.add(consent);
    talker?.info('analytics: consent=$consent');
  }

  @override
  Future<void> setUserId(String? userId) async {
    this.userId = userId;
    talker?.info('analytics: user_id=$userId');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
    talker?.info('analytics: property $name=$value');
  }
}
