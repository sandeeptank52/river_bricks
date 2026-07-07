import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/controller/package_info_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/about_section.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/settings_page.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/theme_segmented_btn.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/app_locale_popup.dart';

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
    version: '1.0.0',
    buildNumber: '1',
  );

  testWidgets('renders appearance, language and about sections', (tester) async {
    await tester.pumpApp(
      container: ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          appEnvPod.overrideWithValue(AppEnv.development),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
          packageInfoPod.overrideWith((ref) => fakeInfo),
        ],
      ),
      child: const SettingsPage(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byType(ThemeSegmentedBtn), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(AppLocalePopUp), findsOneWidget);
    expect(find.byType(AboutSection), findsOneWidget);
  });
}
