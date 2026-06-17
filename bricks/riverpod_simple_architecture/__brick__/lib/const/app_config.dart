import 'package:flutter/material.dart';

/// Centralised, generated app identity/branding.
///
/// Every later module (Settings, About, analytics consent, paywall) reads
/// app identity from here instead of hard-coding literals.
class AppConfig {
  const AppConfig._();

  static const String appTitle = '{{app_title}}';
  static const Color seedColor = Color(0xFF{{seed_color}});
  static const String description = '{{app_description}}';
  static const String author = '{{author}}';
  static const String supportEmail = '{{support_email}}';
  static const String privacyUrl = '{{privacy_url}}';
}
