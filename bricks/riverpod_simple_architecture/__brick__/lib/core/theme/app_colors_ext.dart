import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_color_theme.dart';

/// Brand ThemeExtensions for the light theme (AppTokens is appended by
/// [Themes] separately). Feature goals may append their own extensions here.
List<ThemeExtension<dynamic>> get lightThemeExtensions => [
      AppColorTheme.light,
    ];

/// Brand ThemeExtensions for the dark theme.
List<ThemeExtension<dynamic>> get darkThemeExtensions => [
      AppColorTheme.dark,
    ];

/// Ergonomic access to the brand color extensions from any [BuildContext].
///
/// The accessor falls back to the matching light/dark set when the extension
/// is absent (e.g. a widget rendered under a bare [ThemeData] in a test).
/// The production app always registers these via [Themes].
extension AppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppColorTheme get appColors =>
      Theme.of(this).extension<AppColorTheme>() ??
      (isDarkMode ? AppColorTheme.dark : AppColorTheme.light);
}
