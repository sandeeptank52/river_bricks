/// Centralised, generated app identity/branding.
///
/// Compile-time constants only; environment-dependent values (URLs, support
/// contacts, endpoints) live in [AppEnv] (`app_env.dart`), and brand colors
/// live in `core/theme/brand_palette.dart`.
class AppConfig {
  const AppConfig._();

  static const String appTitle = '{{app_title}}';
  static const String description = '{{app_description}}';
  static const String author = '{{author}}';
}
