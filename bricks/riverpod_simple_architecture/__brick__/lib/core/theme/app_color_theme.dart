import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/brand_palette.dart';

/// Base semantic color tokens. Widgets read these via `context.appColors`
/// (`app_colors_ext.dart`) — never raw `Colors.*` / `Color(0x…)` literals
/// (enforced by test/core/theme/hardcoded_visual_values_test.dart).
@immutable
class AppColorTheme extends ThemeExtension<AppColorTheme> {
  const AppColorTheme({
    required this.background,
    required this.surfaceCard,
    required this.cardBorder,
    required this.primary,
    required this.primarySoft,
    required this.selectedTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.accentLink,
    required this.heroBackdrop,
    required this.successSurface,
    required this.onSuccessSurface,
    required this.warningSurface,
    required this.onWarningSurface,
    required this.error,
  });

  final Color background;
  final Color surfaceCard;
  final Color cardBorder;
  final Color primary;
  final Color primarySoft;
  final Color selectedTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color accentLink;
  final Color heroBackdrop;
  final Color successSurface;
  final Color onSuccessSurface;
  final Color warningSurface;
  final Color onWarningSurface;
  final Color error;

  static final light = AppColorTheme(
    background: BrandPaletteLight.background,
    surfaceCard: BrandPaletteLight.surfaceCard,
    cardBorder: BrandPaletteLight.cardBorder,
    primary: BrandPaletteLight.primary,
    primarySoft: BrandPaletteLight.primarySoft,
    selectedTint: BrandPaletteLight.selectedTint,
    textPrimary: BrandPaletteLight.ink,
    textSecondary: BrandPaletteLight.inkMuted,
    textOnPrimary: _onSeed(BrandPaletteLight.primary),
    accentLink: BrandPaletteLight.accentLink,
    heroBackdrop: BrandPaletteLight.heroBackdrop,
    successSurface: BrandPaletteLight.success,
    onSuccessSurface: BrandPaletteLight.onSuccess,
    warningSurface: BrandPaletteLight.warning,
    onWarningSurface: BrandPaletteLight.onWarning,
    error: BrandPaletteLight.error,
  );

  static final dark = AppColorTheme(
    background: BrandPaletteDark.background,
    surfaceCard: BrandPaletteDark.surfaceCard,
    cardBorder: BrandPaletteDark.cardBorder,
    primary: BrandPaletteDark.primary,
    primarySoft: BrandPaletteDark.primarySoft,
    selectedTint: BrandPaletteDark.selectedTint,
    textPrimary: BrandPaletteDark.ink,
    textSecondary: BrandPaletteDark.inkMuted,
    textOnPrimary: _onSeed(BrandPaletteDark.primary),
    accentLink: BrandPaletteDark.accentLink,
    heroBackdrop: BrandPaletteDark.heroBackdrop,
    successSurface: BrandPaletteDark.success,
    onSuccessSurface: BrandPaletteDark.onSuccess,
    warningSurface: BrandPaletteDark.warning,
    onWarningSurface: BrandPaletteDark.onWarning,
    error: BrandPaletteDark.error,
  );

  /// Contrast-correct on-color for the seed primary.
  static Color _onSeed(Color seed) {
    return ThemeData.estimateBrightnessForColor(seed) == Brightness.dark
        ? BrandPaletteDark.ink
        : BrandPaletteLight.ink;
  }

  @override
  AppColorTheme copyWith({
    Color? background,
    Color? surfaceCard,
    Color? cardBorder,
    Color? primary,
    Color? primarySoft,
    Color? selectedTint,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnPrimary,
    Color? accentLink,
    Color? heroBackdrop,
    Color? successSurface,
    Color? onSuccessSurface,
    Color? warningSurface,
    Color? onWarningSurface,
    Color? error,
  }) {
    return AppColorTheme(
      background: background ?? this.background,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      cardBorder: cardBorder ?? this.cardBorder,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      selectedTint: selectedTint ?? this.selectedTint,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      accentLink: accentLink ?? this.accentLink,
      heroBackdrop: heroBackdrop ?? this.heroBackdrop,
      successSurface: successSurface ?? this.successSurface,
      onSuccessSurface: onSuccessSurface ?? this.onSuccessSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      onWarningSurface: onWarningSurface ?? this.onWarningSurface,
      error: error ?? this.error,
    );
  }

  @override
  AppColorTheme lerp(ThemeExtension<AppColorTheme>? other, double t) {
    if (other is! AppColorTheme) return this;
    return AppColorTheme(
      background: Color.lerp(background, other.background, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      selectedTint: Color.lerp(selectedTint, other.selectedTint, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      accentLink: Color.lerp(accentLink, other.accentLink, t)!,
      heroBackdrop: Color.lerp(heroBackdrop, other.heroBackdrop, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      onSuccessSurface:
          Color.lerp(onSuccessSurface, other.onSuccessSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      onWarningSurface:
          Color.lerp(onWarningSurface, other.onWarningSurface, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
