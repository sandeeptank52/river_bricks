import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Non-color design tokens (spacing, radii, strokes, motion). Brand colors
/// live in [AppColorTheme] / `brand_palette.dart`, not here.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.spaceXs,
    required this.spaceS,
    required this.spaceM,
    required this.spaceL,
    required this.spaceXl,
    required this.radiusS,
    required this.radiusM,
    required this.radiusL,
    required this.strokeS,
    required this.strokeM,
    required this.iconM,
    required this.maxControlWidth,
    required this.maxTextScale,
    required this.systemOverlaySurfaceOpacity,
    required this.motionShort,
    required this.motionMedium,
    required this.motionLong,
  });

  /// The single set of neutral dimension tokens. `radiusM` (16) is the card
  /// radius and `radiusL` (28) is the pill/field radius.
  factory AppTokens.standard() {
    return const AppTokens(
      spaceXs: 4,
      spaceS: 8,
      spaceM: 16,
      spaceL: 24,
      spaceXl: 32,
      radiusS: 8,
      radiusM: 16,
      radiusL: 28,
      strokeS: 1,
      strokeM: 2,
      iconM: 20,
      maxControlWidth: 320,
      maxTextScale: 2,
      systemOverlaySurfaceOpacity: 0.72,
      motionShort: Duration(milliseconds: 150),
      motionMedium: Duration(milliseconds: 250),
      motionLong: Duration(milliseconds: 900),
    );
  }

  static AppTokens of(BuildContext context) {
    return Theme.of(context).extension<AppTokens>() ?? AppTokens.standard();
  }

  final double spaceXs;
  final double spaceS;
  final double spaceM;
  final double spaceL;
  final double spaceXl;
  final double radiusS;
  final double radiusM;
  final double radiusL;
  final double strokeS;
  final double strokeM;
  final double iconM;
  final double maxControlWidth;
  final double maxTextScale;
  final double systemOverlaySurfaceOpacity;
  final Duration motionShort;
  final Duration motionMedium;
  final Duration motionLong;

  @override
  AppTokens copyWith({
    double? spaceXs,
    double? spaceS,
    double? spaceM,
    double? spaceL,
    double? spaceXl,
    double? radiusS,
    double? radiusM,
    double? radiusL,
    double? strokeS,
    double? strokeM,
    double? iconM,
    double? maxControlWidth,
    double? maxTextScale,
    double? systemOverlaySurfaceOpacity,
    Duration? motionShort,
    Duration? motionMedium,
    Duration? motionLong,
  }) {
    return AppTokens(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceS: spaceS ?? this.spaceS,
      spaceM: spaceM ?? this.spaceM,
      spaceL: spaceL ?? this.spaceL,
      spaceXl: spaceXl ?? this.spaceXl,
      radiusS: radiusS ?? this.radiusS,
      radiusM: radiusM ?? this.radiusM,
      radiusL: radiusL ?? this.radiusL,
      strokeS: strokeS ?? this.strokeS,
      strokeM: strokeM ?? this.strokeM,
      iconM: iconM ?? this.iconM,
      maxControlWidth: maxControlWidth ?? this.maxControlWidth,
      maxTextScale: maxTextScale ?? this.maxTextScale,
      systemOverlaySurfaceOpacity:
          systemOverlaySurfaceOpacity ?? this.systemOverlaySurfaceOpacity,
      motionShort: motionShort ?? this.motionShort,
      motionMedium: motionMedium ?? this.motionMedium,
      motionLong: motionLong ?? this.motionLong,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) {
      return this;
    }

    return AppTokens(
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t),
      spaceS: _lerpDouble(spaceS, other.spaceS, t),
      spaceM: _lerpDouble(spaceM, other.spaceM, t),
      spaceL: _lerpDouble(spaceL, other.spaceL, t),
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t),
      radiusS: _lerpDouble(radiusS, other.radiusS, t),
      radiusM: _lerpDouble(radiusM, other.radiusM, t),
      radiusL: _lerpDouble(radiusL, other.radiusL, t),
      strokeS: _lerpDouble(strokeS, other.strokeS, t),
      strokeM: _lerpDouble(strokeM, other.strokeM, t),
      iconM: _lerpDouble(iconM, other.iconM, t),
      maxControlWidth: _lerpDouble(maxControlWidth, other.maxControlWidth, t),
      maxTextScale: _lerpDouble(maxTextScale, other.maxTextScale, t),
      systemOverlaySurfaceOpacity: _lerpDouble(
        systemOverlaySurfaceOpacity,
        other.systemOverlaySurfaceOpacity,
        t,
      ),
      motionShort: _lerpDuration(motionShort, other.motionShort, t),
      motionMedium: _lerpDuration(motionMedium, other.motionMedium, t),
      motionLong: _lerpDuration(motionLong, other.motionLong, t),
    );
  }
}

double _lerpDouble(double begin, double end, double t) {
  return lerpDouble(begin, end, t)!;
}

Duration _lerpDuration(Duration begin, Duration end, double t) {
  return Duration(
    microseconds: lerpDouble(
      begin.inMicroseconds,
      end.inMicroseconds,
      t,
    )!.round(),
  );
}
