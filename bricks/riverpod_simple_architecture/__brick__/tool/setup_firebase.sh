#!/usr/bin/env bash
# Activates Firebase Crashlytics in this generated app. Run from the project root.
# Prereq: dart pub global activate flutterfire_cli
set -euo pipefail

command -v flutterfire >/dev/null 2>&1 || {
  echo "flutterfire CLI not found. Install it with:"
  echo "  dart pub global activate flutterfire_cli"
  exit 1
}

PKG=$(awk '/^name:/{print $2; exit}' pubspec.yaml)
OBS="lib/shared/observability"

echo "==> flutterfire configure (interactive: log in + select/create a Firebase project)"
flutterfire configure

echo "==> Adding Firebase dependencies"
flutter pub add firebase_core firebase_crashlytics

echo "==> Installing the Firebase crash reporter"
cp tool/templates/firebase_crash_reporter.dart.tmpl "$OBS/firebase_crash_reporter.dart"

echo "==> Wiring crashReporterPod -> FirebaseCrashReporter"
perl -0pi -e 's/\(ref\) => const NoopCrashReporter\(\),/(ref) => FirebaseCrashReporter(),/' "$OBS/crash_reporter_pod.dart"
grep -q "firebase_crash_reporter.dart" "$OBS/crash_reporter_pod.dart" || \
  perl -0pi -e "s{(import 'package:${PKG}/shared/observability/crash_reporter.dart';)}{\$1\nimport 'package:${PKG}/shared/observability/firebase_crash_reporter.dart';}" "$OBS/crash_reporter_pod.dart"

echo "==> Inserting Firebase.initializeApp into the init flow"
FI="lib/features/splash/controller/future_initializer.dart"
perl -0pi -e 's{// FIREBASE_INIT \(do not remove[^\n]*\n}{await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);\n}' "$FI"
grep -q "package:firebase_core/firebase_core.dart" "$FI" || \
  perl -0pi -e "s{(import 'package:hive_ce_flutter/hive_flutter.dart';)}{\$1\nimport 'package:firebase_core/firebase_core.dart';\nimport 'package:${PKG}/firebase_options.dart';}" "$FI"

echo "==> Patching Android Gradle plugins"
[ -f android/settings.gradle.kts ] && dart run tool/firebase_gradle_patch.dart settings android/settings.gradle.kts || echo "  (android/settings.gradle.kts not found — skipping)"
[ -f android/app/build.gradle.kts ] && dart run tool/firebase_gradle_patch.dart app android/app/build.gradle.kts || echo "  (android/app/build.gradle.kts not found — skipping)"

echo "==> Done. Run: flutter pub get && flutter run"
echo "    iOS: upload dSYMs to Crashlytics (see Firebase docs) for symbolicated crashes."
