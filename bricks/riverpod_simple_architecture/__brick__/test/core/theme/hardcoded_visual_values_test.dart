import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Brand guard: widgets must route colors through theme tokens
/// (AppColorTheme / colorScheme / AppTokens). The ONLY place raw color
/// literals may live is lib/core/theme/. Rebranding must be a
/// token-file-only change — this test enforces that forever.
void main() {
  test('widgets route hardcoded visual colors through theme tokens', () {
    final violations = <String>[];
    // \b avoids matching the `context.appColors.` token accessor (which ends
    // in "Colors.") — only real `Colors.<name>` and `Color(0x…)` literals.
    final colorPattern = RegExp(r'\bColors\.[a-z]|\bColor\(0x');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (entity.path.startsWith('lib/core/theme/')) {
        continue;
      }
      // Generated files (localization/router codegen) are not hand-authored
      // widget code.
      if (entity.path.endsWith('.g.dart') || entity.path.endsWith('.gr.dart')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('Colors.transparent')) {
          // Transparent is not a brand value.
          continue;
        }
        if (colorPattern.hasMatch(line)) {
          violations.add('${entity.path}:${index + 1}:$line');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
