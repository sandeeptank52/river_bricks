import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/analytics/analytics_client.dart';

void main() {
  group('RecordingAnalyticsClient', () {
    test('records events, user id, properties, and consent', () async {
      final client = RecordingAnalyticsClient(anonymousId: 'anon-1');
      await client.initialize();
      await client.logEvent('screen_view', {'screen': 'home'});
      await client.setUserId('user-1');
      await client.setUserProperty('plan', 'free');
      await client.setConsent(AnalyticsConsent.denied);

      expect(client.anonymousId, 'anon-1');
      expect(client.events.single.name, 'screen_view');
      expect(client.events.single.parameters, {'screen': 'home'});
      expect(client.userId, 'user-1');
      expect(client.userProperties, {'plan': 'free'});
      expect(client.consents, [AnalyticsConsent.denied]);
    });
  });

  group('NoopAnalyticsClient', () {
    test('accepts every call without side effects', () async {
      const client = NoopAnalyticsClient();
      await client.initialize();
      await client.logEvent('anything');
      await client.setConsent(AnalyticsConsent.granted);
      await client.setUserId('u');
      await client.setUserProperty('k', 'v');
      expect(client.anonymousId, 'anonymous');
    });
  });
}
