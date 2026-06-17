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
    expect(out, contains('com.google.gms.google-services'));
    expect(out, contains('com.google.firebase.crashlytics'));
    expect(out, contains('apply false'));
  });

  test('app build.gradle.kts gets both plugins applied (no version)', () {
    final out = addFirebasePlugins(_app, isSettings: false);
    expect(out, contains('id("com.google.gms.google-services")'));
    expect(out, contains('id("com.google.firebase.crashlytics")'));
    expect(out.contains('apply false'), isFalse);
  });

  test('is idempotent', () {
    final once = addFirebasePlugins(_app, isSettings: false);
    final twice = addFirebasePlugins(once, isSettings: false);
    expect(
      'com.google.gms.google-services'.allMatches(twice).length,
      'com.google.gms.google-services'.allMatches(once).length,
    );
  });
}
