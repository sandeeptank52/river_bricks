import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';

/// Staging entry point: `flutter run -t lib/main_staging.dart`
Future<void> main() => runFlavoredApp(AppEnv.staging);
