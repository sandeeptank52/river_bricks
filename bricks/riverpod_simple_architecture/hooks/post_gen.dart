import 'dart:io';

import 'package:mason/mason.dart';

/// Runs a command and reports progress, returning whether it succeeded.
Future<bool> _run(
  HookContext context,
  String label,
  String executable,
  List<String> args,
) async {
  final progress = context.logger.progress(label);
  try {
    final result = await Process.run(executable, args, runInShell: true);
    if (result.exitCode == 0) {
      progress.complete('$label — done');
      return true;
    }
    progress.fail('$label — failed (exit ${result.exitCode})');
    context.logger.detail('stdout: ${result.stdout}');
    context.logger.err('stderr: ${result.stderr}');
    return false;
  } catch (e) {
    progress.fail('$label — error: $e');
    return false;
  }
}

void _patchAndroidIdentity(HookContext context) {
  final org = (context.vars['org'] as String?)?.trim() ?? '';
  final name = (context.vars['project_name'] as String?)?.trim() ?? '';
  final title = (context.vars['app_title'] as String?)?.trim() ?? '';
  final snake = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  // applicationId in build.gradle(.kts), only when org is non-default.
  if (org.isNotEmpty && org != 'com.example' && snake.isNotEmpty) {
    final appId = '$org.$snake';
    for (final p in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
      final f = File(p);
      if (!f.existsSync()) continue;
      var src = f.readAsStringSync();
      final patched = src.replaceAllMapped(
        RegExp(r'''applicationId\s*=?\s*["'][^"']*["']'''),
        (_) => 'applicationId = "$appId"',
      );
      if (patched != src) {
        f.writeAsStringSync(patched);
        context.logger.detail('Set applicationId to $appId in $p');
      } else {
        context.logger.detail('applicationId pattern not found in $p');
      }
    }
  }

  // android:label in AndroidManifest.xml — scoped to the <application> tag only.
  if (title.isNotEmpty) {
    final f = File('android/app/src/main/AndroidManifest.xml');
    if (!f.existsSync()) {
      context.logger.detail(
          'AndroidManifest.xml not found — skipping android:label patch');
    } else {
      var src = f.readAsStringSync();
      // Match the entire <application ...> opening tag (from <application to the
      // first >) and replace android:label only within that captured block.
      final patched = src.replaceFirstMapped(
        RegExp(r'<application\b[^>]*>', dotAll: true),
        (m) {
          final tag = m.group(0)!;
          final updated = tag.replaceFirst(
            RegExp(r'android:label="[^"]*"'),
            'android:label="$title"',
          );
          return updated;
        },
      );
      if (patched != src) {
        f.writeAsStringSync(patched);
        context.logger.detail('Set android:label to "$title" in AndroidManifest.xml');
      } else {
        context.logger.detail(
            'android:label not found in <application> tag of AndroidManifest.xml');
      }
    }
  }
}

/// G03 parity: predictive back on Android needs the OnBackInvoked opt-in on
/// the <application> tag (the theme side ships
/// PredictiveBackPageTransitionsBuilder in app_theme.dart).
void _patchAndroidPredictiveBack(HookContext context) {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    context.logger.detail(
        'AndroidManifest.xml not found — skipping predictive-back patch');
    return;
  }
  var src = f.readAsStringSync();
  if (src.contains('android:enableOnBackInvokedCallback')) return;
  final patched = src.replaceFirstMapped(
    RegExp(r'<application\b'),
    (_) => '<application\n        android:enableOnBackInvokedCallback="true"',
  );
  if (patched != src) {
    f.writeAsStringSync(patched);
    context.logger
        .detail('Enabled android:enableOnBackInvokedCallback in AndroidManifest.xml');
  }
}

/// Both platforms are first-class: mirror the Android identity patches on the
/// iOS Runner (bundle id in project.pbxproj, CFBundleDisplayName in Info.plist).
void _patchIosIdentity(HookContext context) {
  final org = (context.vars['org'] as String?)?.trim() ?? '';
  final name = (context.vars['project_name'] as String?)?.trim() ?? '';
  final title = (context.vars['app_title'] as String?)?.trim() ?? '';
  final snake = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  // Bundle id: replace the existing base identifier everywhere it appears
  // (Runner + RunnerTests keep their relative suffixes).
  if (org.isNotEmpty && org != 'com.example' && snake.isNotEmpty) {
    final newBase = '$org.$snake';
    final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
    if (!pbxproj.existsSync()) {
      context.logger
          .detail('project.pbxproj not found — skipping iOS bundle id patch');
    } else {
      final src = pbxproj.readAsStringSync();
      final baseMatch = RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+?);',
      ).allMatches(src).map((m) => m.group(1)!.trim()).where(
            (id) => !id.endsWith('.RunnerTests'),
          );
      if (baseMatch.isEmpty) {
        context.logger.detail(
            'PRODUCT_BUNDLE_IDENTIFIER not found — skipping iOS bundle id patch');
      } else {
        final oldBase = baseMatch.first.replaceAll('"', '');
        if (oldBase != newBase) {
          final patched = src.replaceAll(oldBase, newBase);
          pbxproj.writeAsStringSync(patched);
          context.logger.detail(
              'Set iOS PRODUCT_BUNDLE_IDENTIFIER base to $newBase (was $oldBase)');
        }
      }
    }
  }

  // CFBundleDisplayName in Info.plist.
  if (title.isNotEmpty) {
    final plist = File('ios/Runner/Info.plist');
    if (!plist.existsSync()) {
      context.logger
          .detail('Info.plist not found — skipping CFBundleDisplayName patch');
      return;
    }
    var src = plist.readAsStringSync();
    final displayNameKey = '<key>CFBundleDisplayName</key>';
    if (src.contains(displayNameKey)) {
      final patched = src.replaceFirstMapped(
        RegExp('$displayNameKey\\s*<string>[^<]*</string>'),
        (_) => '$displayNameKey\n\t<string>$title</string>',
      );
      if (patched != src) {
        plist.writeAsStringSync(patched);
        context.logger
            .detail('Set CFBundleDisplayName to "$title" in Info.plist');
      }
    } else {
      final patched = src.replaceFirst(
        '<dict>',
        '<dict>\n\t$displayNameKey\n\t<string>$title</string>',
      );
      if (patched != src) {
        plist.writeAsStringSync(patched);
        context.logger
            .detail('Inserted CFBundleDisplayName "$title" into Info.plist');
      }
    }
  }
}

/// Language fan-out: the brick ships `en.i18n.json` (base). Every other
/// selected language gets a copy of the base file as an untranslated
/// placeholder (translation itself is human/agent work), then slang
/// regenerates the matching strings set.
void _writeLanguageFiles(HookContext context) {
  final codes = ((context.vars['language_codes'] as List?) ?? const ['en'])
      .map((code) => code.toString())
      .toList();
  final base = File('lib/i18n/en.i18n.json');
  if (!base.existsSync()) {
    context.logger.err('lib/i18n/en.i18n.json missing — cannot fan out languages');
    return;
  }
  final baseContent = base.readAsStringSync();
  for (final code in codes) {
    if (code == 'en') continue;
    final file = File('lib/i18n/$code.i18n.json');
    file.writeAsStringSync(
      baseContent.replaceFirst('"locale": "en"', '"locale": "$code"'),
    );
    context.logger.detail('Wrote lib/i18n/$code.i18n.json (placeholder copy of en)');
  }
  // Remove locale files for languages that are NOT selected (stale runs).
  final dir = Directory('lib/i18n');
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final match =
        RegExp(r'([a-z]{2,3})\.i18n\.json$').firstMatch(entity.path);
    if (match != null && !codes.contains(match.group(1))) {
      entity.deleteSync();
      context.logger.detail('Removed stale ${entity.path}');
    }
  }
}

/// Feature skeletons (foundation only): folder + barrel + mirrored test dir.
/// All feature CONTENT is agent-owned — the brick never writes pages,
/// controllers, or repositories here.
void _writeFeatureSkeletons(HookContext context) {
  final features = (context.vars['features'] as List?) ?? const [];
  for (final entry in features) {
    if (entry is! Map) continue;
    final name = '${entry['name']}';
    final data = entry['data'] == true;
    final dirs = <String>[
      'lib/features/$name/controller',
      'lib/features/$name/view',
      if (data) 'lib/features/$name/data',
      'test/features/$name',
    ];
    for (final dir in dirs) {
      Directory(dir).createSync(recursive: true);
      File('$dir/.gitkeep').writeAsStringSync('');
    }
    final layers = data ? 'controller/, view/, data/' : 'controller/, view/';
    File('lib/features/$name/$name.dart').writeAsStringSync('''
/// Barrel for the `$name` feature — public exports only.
///
/// Layout (do NOT create domain/application/presentation layers):
///   $layers
/// Feature content is agent-owned and implemented from the app's goals/
/// specs; the scaffold only provides this skeleton.
library;
''');
    context.logger.detail('Scaffolded feature skeleton lib/features/$name/');
  }
}

void run(HookContext context) async {
  context.logger.info('Post generation started');

  // When responsive=false, the brick still copies responsive_wrapper.dart
  // (macOS APFS does not allow '/' in filenames, so the Mason conditional-
  // filename trick cannot be used on macOS). Delete the file here instead.
  final responsive = context.vars['responsive'] as bool? ?? false;
  if (!responsive) {
    final wrapperFile =
        File('lib/shared/widget/responsive_wrapper.dart');
    if (wrapperFile.existsSync()) {
      wrapperFile.deleteSync();
      context.logger
          .info('Removed responsive_wrapper.dart (responsive=false)');
    }
  }

  // Var-driven language files and feature skeletons come before codegen so
  // slang/build_runner see the final tree.
  _writeLanguageFiles(context);
  _writeFeatureSkeletons(context);

  // Dependencies are now pinned in pubspec.yaml, so we only need to resolve
  // them — no `dart pub add` step is required anymore.
  if (!await _run(context, 'Getting packages', 'flutter', ['pub', 'get'])) {
    return;
  }

  // build_runner (>= 2.15) refuses to overwrite pre-existing generated files,
  // so remove any that survived from a previous run before regenerating.
  // (The brick itself no longer ships generated files; slang + build_runner
  // create router.gr.dart and the strings_*.g.dart set for the selected
  // language list below.)
  final staleGenerated = <FileSystemEntity>[
    File('lib/core/router/router.gr.dart'),
    ...Directory('lib/i18n').listSync().where(
          (entity) => entity is File && entity.path.endsWith('.g.dart'),
        ),
  ];
  for (final entity in staleGenerated) {
    if (entity.existsSync()) entity.deleteSync();
  }

  // Localization is generated by slang's own CLI (the build_runner integration
  // skips without explicit config).
  if (!await _run(context, 'Generating localization (slang)', 'dart',
      ['run', 'slang'])) {
    return;
  }

  // Routes (auto_route) are generated via build_runner.
  if (!await _run(context, 'Generating routes (build_runner)', 'dart',
      ['run', 'build_runner', 'build'])) {
    return;
  }

  // Platform identity + predictive back on BOTH platforms (iOS and Android
  // are co-equal targets) — before tests so nothing depends on stale config.
  _patchAndroidIdentity(context);
  _patchAndroidPredictiveBack(context);
  _patchIosIdentity(context);

  // Tests + coverage are informational; a failure here should not abort
  // generation of an otherwise-valid project.
  await _run(context, 'Running tests', 'flutter', ['test', '--coverage']);

  final responsiveNote = responsive ? ', responsive_framework' : '';
  context.logger.info(
    '''\n\n 🎉 Your Riverpod simple-architecture app is ready!
      \n 🔄 State management: Riverpod 3 (with cache/refresh/debounce/cancel + easyWhen extensions)
      \n 🛣️  Routing: auto_route (typed guarded route table + NotFound wildcard)
      \n 🌐 Networking: Dio (AppEnv-driven base URL, error handler, time logging)
      \n 🎨 Theming: flex_color_scheme + AppTokens/AppColorTheme design tokens (light/dark with persistence)
      \n 🗄️  Storage: Hive CE with an encrypted box (key via SecureKvStore in flutter_secure_storage)
      \n 🌍 Localization: slang (var-driven language set)
      \n 🚫 Built-in no-internet + locale-picker widgets$responsiveNote, and talker logging
      \n\n 💡 Android note: flutter_secure_storage requires minSdk 23.
      \n 💡 To enable Riverpod lints later, re-add custom_lint + riverpod_lint once the
      \n    analyzer ecosystem realigns, then uncomment the plugin in analysis_options.yaml.
      \n\n Made with ❤️🔥 by Shreeman Arjun — https://shreeman.dev\n\n''',
  );

  context.logger.info('Post generation completed');
}
