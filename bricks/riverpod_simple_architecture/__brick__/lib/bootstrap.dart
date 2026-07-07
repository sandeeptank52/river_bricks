import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:platform_info/platform_info.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:{{project_name.snakeCase()}}/app/view/app.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/box_encryption_key.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/secure_kv_store.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/storage_keys.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/init.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/analytics/analytics_client.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/analytics/analytics_client_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/crash_reporter_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/observability/error_handlers.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/internet_checker_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/persisted_state_contract.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/riverpod_observer/riverpod_obs.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/riverpod_observer/talker_riverpod_settings.dart';

// coverage:ignore-file

/// This `talker` global variable used for logging and accessible
///  to other classed or function
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    useConsoleLogs: !kReleaseMode,
    enabled: !kReleaseMode,
  ),
  logger: TalkerLogger(
    output: debugPrint,
    settings: TalkerLoggerSettings(enableColors: !Platform.I.iOS),
  ),
);

/// Single entry point used by every flavored `main_<flavor>.dart`.
///
/// Performs all async initialization BEFORE `runApp` (the native splash
/// covers the gap), then hands one fully-configured [ProviderContainer] to
/// [bootstrap]. There is exactly one MaterialApp in the tree — the router's
/// splash route owns any in-app resolution UI.
Future<void> runFlavoredApp(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  // FIREBASE_INIT (do not remove — setup_firebase.sh inserts Firebase.initializeApp here)
  final container = await createAppContainer(env: env);
  // AGENT-SEAM: integration goals append their init steps HERE (notifications,
  // remote config, sync, attribution, …). These lines are agent-owned
  // insertions — the scaffold intentionally ships none of them.
  await bootstrap(() => const App(), parent: container);
}

/// Builds the app's root [ProviderContainer]: encrypted Hive box, device
/// translations, environment override, analytics/crash seams, and observers.
Future<ProviderContainer> createAppContainer({
  required AppEnv env,
  SecureKvStore secureStore = const KeychainSecureKvStore(),
}) async {
  await Hive.initFlutter();

  final encryptionCipher = await Platform.I.when(
    mobile: () async {
      final encryptionKey = await obtainBoxEncryptionKey(secureStore);
      return HiveAesCipher(encryptionKey);
    },
  );

  final appBox = await Hive.openBox(
    StorageKeys.appBox,
    encryptionCipher: encryptionCipher,
  );
  final appStorage = AppStorage(appBox);
  final locale = resolveStartupLocale(
    appStorage,
    deviceLocale: AppLocaleUtils.findDeviceLocale(),
  );
  final translations = await locale.build();

  // Foundation analytics seam: debug builds log events via talker, release
  // builds no-op. Real backends are bound in the analytics integration goal —
  // features only ever talk to [AnalyticsClient].
  final AnalyticsClient analyticsClient = kReleaseMode
      ? const NoopAnalyticsClient()
      : RecordingAnalyticsClient(talker: talker);
  await analyticsClient.initialize();

  return ProviderContainer(
    overrides: [
      appEnvPod.overrideWithValue(env),
      appBoxProvider.overrideWithValue(appBox),
      translationsPod.overrideWith((ref) => translations),
      analyticsClientPod.overrideWithValue(analyticsClient),
      // Decision (G01 Appx A #5): the connectivity banner is LIVE by default —
      // ConnectionMonitor reflects real connectivity. Tests override this to
      // false so widget tests never touch the network.
      enableInternetCheckerPod.overrideWithValue(true),
    ],
    observers: [
      TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(
          printProviderDisposed: true,
        ),
      ),
    ],
  );
}

/// Resolves the active [AppLocale] from persisted storage, falling back to
/// [deviceLocale] when no language has been chosen.
AppLocale resolveStartupLocale(
  AppStorage storage, {
  required AppLocale deviceLocale,
}) {
  final storedLanguage = storage.get(
    key: PersistedStateKeys.language.storageKey,
  );
  if (storedLanguage != null) {
    for (final locale in AppLocale.values) {
      if (locale.languageCode == storedLanguage) {
        return locale;
      }
    }
  }
  return deviceLocale;
}

///This bootstrap function builds widget asynchronusly
///where builder function used for building your start widget.
///You can override riverpod providers ,also setup observers
///or you can put a provider container in parent
Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required ProviderContainer parent,
}) async {
  wireCrashHandlers(parent.read(crashReporterPod), talker);

  runApp(UncontrolledProviderScope(container: parent, child: await builder()));
}
