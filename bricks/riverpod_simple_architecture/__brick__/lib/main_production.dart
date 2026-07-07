import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';

/// Production entry point: `flutter run -t lib/main_production.dart`
Future<void> main() => runFlavoredApp(AppEnv.production);
