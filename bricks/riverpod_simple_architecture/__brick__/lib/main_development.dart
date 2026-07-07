import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';

/// Development entry point: `flutter run -t lib/main_development.dart`
Future<void> main() => runFlavoredApp(AppEnv.development);
