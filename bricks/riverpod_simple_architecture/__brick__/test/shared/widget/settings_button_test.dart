import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/settings_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appBox', bytes: Uint8List(0));
  });
  tearDown(() => appBox.clear());

  testWidgets('renders a settings icon button', (tester) async {
    await tester.pumpApp(
      container: ProviderContainer(
        overrides: [
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
        ],
      ),
      child: Scaffold(appBar: AppBar(actions: const [SettingsButton()])),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings_button')), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
