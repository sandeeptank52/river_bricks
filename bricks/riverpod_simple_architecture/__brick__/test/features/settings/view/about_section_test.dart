import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/controller/package_info_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/about_section.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

import '../../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appBox', bytes: Uint8List(0));
  });
  tearDown(() => appBox.clear());

  final fakeInfo = PackageInfo(
    appName: 'Test',
    packageName: 'com.test',
    version: '1.2.3',
    buildNumber: '4',
  );

  ProviderContainer containerWith() => ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
          packageInfoPod.overrideWith((ref) => fakeInfo),
        ],
      );

  testWidgets('renders app title, version and both action rows', (tester) async {
    var contactTapped = 0;
    final container = containerWith();
    await tester.pumpApp(
      container: container,
      child: AboutSection(
        appTitle: 'My Tool',
        supportEmail: 's@x.dev',
        privacyUrl: 'https://x.dev/privacy',
        onContactSupport: () => contactTapped++,
        onPrivacyPolicy: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Tool'), findsOneWidget);
    expect(find.textContaining('1.2.3+4'), findsOneWidget);
    expect(find.byKey(const ValueKey('contact_support_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy_policy_tile')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('contact_support_tile')));
    expect(contactTapped, 1);
  });

  testWidgets('hides action rows when their config is empty', (tester) async {
    await tester.pumpApp(
      container: containerWith(),
      child: AboutSection(
        appTitle: 'My Tool',
        supportEmail: '',
        privacyUrl: '',
        onContactSupport: () {},
        onPrivacyPolicy: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('contact_support_tile')), findsNothing);
    expect(find.byKey(const ValueKey('privacy_policy_tile')), findsNothing);
  });
}
