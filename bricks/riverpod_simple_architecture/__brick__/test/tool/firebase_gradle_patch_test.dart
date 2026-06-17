import 'package:flutter_test/flutter_test.dart';

import '../../tool/firebase_gradle_patch.dart';

const _settings = '''
pluginManagement { }
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.5.0" apply false
}
''';

const _app = '''
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
''';

void main() {
  test('settings.gradle.kts gets both plugins with version + apply false', () {
    final out = addFirebasePlugins(_settings, isSettings: true);
    // Assert the full firebase-specific lines (version + apply false), not just
    // the generic "apply false" that already exists on com.android.application.
    expect(
      out,
      contains('id("com.google.gms.google-services") version "4.4.2" apply false'),
    );
    expect(
      out,
      contains('id("com.google.firebase.crashlytics") version "3.0.2" apply false'),
    );
  });

  test('app build.gradle.kts gets both plugins applied (no version)', () {
    final out = addFirebasePlugins(_app, isSettings: false);
    expect(out, contains('id("com.google.gms.google-services")'));
    expect(out, contains('id("com.google.firebase.crashlytics")'));
    // Applied plugins must NOT carry "apply false" — they must be active.
    expect(out.contains('apply false'), isFalse);
  });

  test('is idempotent', () {
    final once = addFirebasePlugins(_app, isSettings: false);
    final twice = addFirebasePlugins(once, isSettings: false);
    // Absolute assertion: exactly one occurrence after a single run.
    // A doubling-on-every-run bug would produce 2 after "once", failing here.
    expect(
      'com.google.gms.google-services'.allMatches(once).length,
      equals(1),
    );
    // Running twice must not add a second copy.
    expect(
      'com.google.gms.google-services'.allMatches(twice).length,
      equals('com.google.gms.google-services'.allMatches(once).length),
    );
  });
}
