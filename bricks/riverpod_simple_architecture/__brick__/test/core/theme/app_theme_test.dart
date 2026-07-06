import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_color_theme.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_theme.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/brand_palette.dart';

void main() {
  group('Themes', () {
    test('registers the token extensions in light AND dark themes', () {
      for (final theme in [Themes.theme, Themes.darkTheme]) {
        expect(theme.extension<AppColorTheme>(), isNotNull);
        expect(theme.extension<AppTokens>(), isNotNull);
      }
      expect(
        Themes.theme.extension<AppColorTheme>()!.primary,
        BrandPalette.seed,
      );
      expect(
        Themes.darkTheme.extension<AppColorTheme>()!.primary,
        BrandPalette.seed,
      );
    });

    test('uses Android predictive back page transitions (iOS keeps Cupertino)',
        () {
      for (final theme in [Themes.theme, Themes.darkTheme]) {
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<PredictiveBackPageTransitionsBuilder>(),
        );
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.iOS],
          isA<CupertinoPageTransitionsBuilder>(),
        );
      }
    });
  });
}
