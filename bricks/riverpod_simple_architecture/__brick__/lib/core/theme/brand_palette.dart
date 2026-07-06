import 'package:flutter/material.dart';

/// Raw brand color values. This file is the ONLY place brand hex values
/// live — rebranding the app means editing these constants (and nothing
/// else; every widget reads colors through [AppColorTheme]/theme tokens).
///
/// The scaffold seeds [primary] from the generated `seed_color` and derives
/// soft/tint variants from it; the neutral surfaces/inks below are
/// deliberately placeholder values for a later token-file-only rebrand.
abstract final class BrandPalette {
  /// The generated brand seed.
  static const seed = Color(0xFF{{seed_color}});
}

abstract final class BrandPaletteLight {
  static const background = Color(0xFFFCFBF8);
  static const surfaceCard = Color(0xFFF4F2EE);
  static const cardBorder = Color(0xFFE3E0DA);
  static const primary = BrandPalette.seed;
  static final primarySoft = Color.lerp(primary, surfaceCard, 0.65)!;
  static final selectedTint = Color.lerp(primary, background, 0.80)!;
  static const ink = Color(0xFF1C1B1F);
  static const inkMuted = Color(0xFF6B6861);
  static const accentLink = BrandPalette.seed;
  static const heroBackdrop = Color(0xFFF8F6F2);
  static const success = Color(0xFFDDEFD8);
  static const onSuccess = Color(0xFF1E4620);
  static const warning = Color(0xFFFBE3C0);
  static const onWarning = Color(0xFF5C4300);
  static const error = Color(0xFFB3261E);
}

abstract final class BrandPaletteDark {
  static const background = Color(0xFF17161A);
  static const surfaceCard = Color(0xFF232227);
  static const cardBorder = Color(0xFF3A383F);
  static const primary = BrandPalette.seed;
  static final primarySoft = Color.lerp(primary, surfaceCard, 0.55)!;
  static final selectedTint = Color.lerp(primary, background, 0.70)!;
  static const ink = Color(0xFFF2EFEA);
  static const inkMuted = Color(0xFFB4B0A8);
  static const accentLink = BrandPalette.seed;
  static const heroBackdrop = Color(0xFF1D1C21);
  static const success = Color(0xFF2C4529);
  static const onSuccess = Color(0xFFC4E8BE);
  static const warning = Color(0xFF4E3C15);
  static const onWarning = Color(0xFFF4DFB2);
  static const error = Color(0xFFF2B8B5);
}
