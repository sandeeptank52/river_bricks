import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/controller/package_info_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/asynvalue_easy_when.dart';

/// The About section of the settings page. Presentational: identity strings are
/// injected; the running version comes from [packageInfoPod].
class AboutSection extends ConsumerWidget {
  const AboutSection({
    super.key,
    required this.appTitle,
    required this.supportEmail,
    required this.privacyUrl,
    required this.onContactSupport,
    required this.onPrivacyPolicy,
  });

  final String appTitle;
  final String supportEmail;
  final String privacyUrl;
  final VoidCallback onContactSupport;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsPod);
    final packageInfo = ref.watch(packageInfoPod);
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              t.settings.about,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(appTitle),
            subtitle: packageInfo.easyWhen(
              data: (info) => Text(
                '${t.settings.version} ${info.version}+${info.buildNumber}',
              ),
              loadingWidget: () => const SizedBox.shrink(),
              errorWidget: (e, st) => const SizedBox.shrink(),
            ),
          ),
          if (supportEmail.isNotEmpty)
            ListTile(
              key: const ValueKey('contact_support_tile'),
              leading: const Icon(Icons.mail_outline),
              title: Text(t.settings.contactSupport),
              onTap: onContactSupport,
            ),
          if (privacyUrl.isNotEmpty)
            ListTile(
              key: const ValueKey('privacy_policy_tile'),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(t.settings.privacyPolicy),
              onTap: onPrivacyPolicy,
            ),
        ],
      ),
    );
  }
}
