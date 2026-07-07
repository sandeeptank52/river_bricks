import 'package:{{project_name.snakeCase()}}/main_production.dart' as production;

/// Default entry point (`flutter run` / store builds) — production flavor.
/// Use `-t lib/main_development.dart` for day-to-day development.
Future<void> main() => production.main();
