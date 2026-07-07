import 'dart:io';

/// Adds the Firebase Gradle plugins to a Kotlin-DSL gradle file's first
/// `plugins { }` block. [isSettings] true → `settings.gradle.kts` (with version
/// + `apply false`); false → `app/build.gradle.kts` (applied, no version).
/// Idempotent: a plugin already present is not added again.
String addFirebasePlugins(String content, {required bool isSettings}) {
  final lines = isSettings
      ? const [
          'id("com.google.gms.google-services") version "4.4.2" apply false',
          'id("com.google.firebase.crashlytics") version "3.0.2" apply false',
        ]
      : const [
          'id("com.google.gms.google-services")',
          'id("com.google.firebase.crashlytics")',
        ];

  // Each plugin is prepended individually, so the emitted order in the file is
  // the reverse of the list above (last item in the list ends up first).
  var result = content;
  for (final line in lines) {
    final id = RegExp(r'id\("([^"]+)"\)').firstMatch(line)!.group(1)!;
    if (result.contains(id)) continue; // already present — idempotent
    result = result.replaceFirst(
      RegExp(r'plugins\s*\{'),
      'plugins {\n    $line',
    );
  }
  return result;
}

/// CLI: `dart run tool/firebase_gradle_patch.dart <settings|app> <path>`
void main(List<String> args) {
  if (args.length != 2 || (args[0] != 'settings' && args[0] != 'app')) {
    stderr.writeln('usage: firebase_gradle_patch.dart <settings|app> <path>');
    exitCode = 2;
    return;
  }
  final file = File(args[1]);
  if (!file.existsSync()) {
    stderr.writeln('file not found: ${args[1]}');
    exitCode = 2;
    return;
  }
  file.writeAsStringSync(
    addFirebasePlugins(file.readAsStringSync(), isSettings: args[0] == 'settings'),
  );
  stdout.writeln('patched ${args[1]}');
}
