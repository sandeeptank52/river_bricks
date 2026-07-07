import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build flavors. Entry points (`main_<flavor>.dart`) pick one and pass its
/// [AppEnv] through `runFlavoredApp`.
enum AppFlavor { development, staging, production }

/// Flavor-scoped runtime configuration.
///
/// Values that differ per environment (endpoints, support contacts, legal
/// URLs) live here — never inline in widgets or clients. Empty release-facing
/// values are release-checklist gated: the app must not ship until they are
/// replaced with real ones.
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.refundPolicyUrl,
  });

  final AppFlavor flavor;

  /// Base URL for the app's own API surface. Empty until the backend exists;
  /// `dioProvider` fails fast when read while this is unset.
  final String apiBaseUrl;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String refundPolicyUrl;

  static const development = AppEnv(
    flavor: AppFlavor.development,
    apiBaseUrl: '{{{api_base_url_development}}}',
    supportEmail: '{{support_email}}',
    privacyPolicyUrl: '{{{privacy_url}}}',
    termsOfServiceUrl: '{{{terms_url}}}',
    refundPolicyUrl: '{{{refund_url}}}',
  );

  static const staging = AppEnv(
    flavor: AppFlavor.staging,
    apiBaseUrl: '{{{api_base_url_staging}}}',
    supportEmail: '{{support_email}}',
    privacyPolicyUrl: '{{{privacy_url}}}',
    termsOfServiceUrl: '{{{terms_url}}}',
    refundPolicyUrl: '{{{refund_url}}}',
  );

  static const production = AppEnv(
    flavor: AppFlavor.production,
    apiBaseUrl: '{{{api_base_url_production}}}',
    supportEmail: '{{support_email}}',
    privacyPolicyUrl: '{{{privacy_url}}}',
    termsOfServiceUrl: '{{{terms_url}}}',
    refundPolicyUrl: '{{{refund_url}}}',
  );
}

/// The active environment. Overridden with the selected flavor's [AppEnv] in
/// `createAppContainer`; reading it without an override is a wiring bug.
final appEnvPod = Provider<AppEnv>(
  (ref) => throw UnimplementedError('appEnvPod is not overridden'),
  name: 'appEnvPod',
);
