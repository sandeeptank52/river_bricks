import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_colors_ext.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/brand_palette.dart';

/// Brand-driven light/dark themes (FlexColorScheme + ThemeExtensions).
/// All hex values live in brand_palette.dart; dimensions in app_tokens.dart.
class Themes {
  static ThemeData get theme => _finish(
        FlexThemeData.light(
          colors: FlexSchemeColor(
            primary: BrandPaletteLight.primary,
            primaryContainer: BrandPaletteLight.primarySoft,
            secondary: BrandPaletteLight.accentLink,
            secondaryContainer: BrandPaletteLight.selectedTint,
            tertiary: BrandPaletteLight.accentLink,
            tertiaryContainer: BrandPaletteLight.selectedTint,
            error: BrandPaletteLight.error,
          ),
          usedColors: 6,
          surfaceMode: FlexSurfaceMode.level,
          blendLevel: 0,
          scaffoldBackground: BrandPaletteLight.background,
          surface: BrandPaletteLight.surfaceCard,
          subThemesData: _subThemes,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        BrandPaletteLight.ink,
        lightThemeExtensions,
      );

  static ThemeData get darkTheme => _finish(
        FlexThemeData.dark(
          colors: FlexSchemeColor(
            primary: BrandPaletteDark.primary,
            primaryContainer: BrandPaletteDark.primarySoft,
            secondary: BrandPaletteDark.accentLink,
            secondaryContainer: BrandPaletteDark.selectedTint,
            tertiary: BrandPaletteDark.accentLink,
            tertiaryContainer: BrandPaletteDark.selectedTint,
            error: BrandPaletteDark.error,
          ),
          usedColors: 6,
          surfaceMode: FlexSurfaceMode.level,
          blendLevel: 0,
          scaffoldBackground: BrandPaletteDark.background,
          surface: BrandPaletteDark.surfaceCard,
          subThemesData: _subThemes,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        BrandPaletteDark.ink,
        darkThemeExtensions,
      );

  static const _subThemes = FlexSubThemesData(
    elevatedButtonRadius: 28,
    filledButtonRadius: 28,
    outlinedButtonRadius: 28,
    inputDecoratorRadius: 28,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedBorderIsColored: false,
    cardRadius: 16,
    dialogRadius: 24,
    bottomSheetRadius: 24,
  );

  static ThemeData _finish(
    ThemeData base,
    Color ink,
    List<ThemeExtension<dynamic>> extensions,
  ) {
    final scheme = base.colorScheme.copyWith(onSurface: ink);
    return base.copyWith(
      colorScheme: scheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ink,
      ),
      // Predictive back on Android (post_gen also opts the manifest in);
      // Cupertino transitions keep the iOS edge-swipe gesture working.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      extensions: [...extensions, AppTokens.standard()],
    );
  }
}
