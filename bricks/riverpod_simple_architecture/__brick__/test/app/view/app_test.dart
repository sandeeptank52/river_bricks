import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:{{project_name.snakeCase()}}/app/view/app.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/splash/view/splash_page.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/internet_checker_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Box appBox;
  setUp(() async {
    appBox = await Hive.openBox('appTestBox', bytes: Uint8List(0));
  });
  tearDown(() {
    appBox.clear();
  });
  group('App', () {
    testWidgets('boots the single MaterialApp.router on the splash route',
        (tester) async {
      final language = await AppLocale.en.build();
      final container = ProviderContainer(
        overrides: [
          enableInternetCheckerPod.overrideWith((ref) => false),
          appBoxProvider.overrideWithValue(appBox),
          translationsPod.overrideWith((ref) => language),
          appEnvPod.overrideWithValue(AppEnv.development),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const App(),
        ),
      );
      await tester.pump();
      // Exactly ONE MaterialApp in the tree (router-driven).
      expect(find.byType(MaterialApp), findsOneWidget);
      // The splash route resolves and replaces itself with the landing route.
      await tester.pumpAndSettle();
      expect(find.byType(SplashPage), findsNothing);
    });
  });
}
