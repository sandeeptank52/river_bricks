import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/const/app_config.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/about_section.dart';
import 'package:{{project_name.snakeCase()}}/features/settings/view/theme_segmented_btn.dart';
import 'package:{{project_name.snakeCase()}}/shared/helper/global_helper.dart';
import 'package:{{project_name.snakeCase()}}/shared/helper/launcher_helper.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/app_locale_popup.dart';

@RoutePage()
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with GlobalHelper {
  Future<void> _contactSupport() async {
    final ok = await launchEmail(ref.read(appEnvPod).supportEmail);
    if (!ok && mounted) {
      showErrorSnack(child: Text(ref.read(translationsPod).settings.launchError));
    }
  }

  Future<void> _privacyPolicy() async {
    final ok = await launchWebUrl(ref.read(appEnvPod).privacyPolicyUrl);
    if (!ok && mounted) {
      showErrorSnack(child: Text(ref.read(translationsPod).settings.launchError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsPod);
    final env = ref.watch(appEnvPod);
    final tokens = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              tokens.spaceM,
              tokens.spaceM,
              tokens.spaceM,
              tokens.spaceS,
            ),
            child: Text(
              t.settings.appearance,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: tokens.spaceM),
            child: const ThemeSegmentedBtn(),
          ),
          ListTile(
            title: Text(t.settings.language),
            trailing: const AppLocalePopUp(),
          ),
          const Divider(),
          AboutSection(
            appTitle: AppConfig.appTitle,
            supportEmail: env.supportEmail,
            privacyUrl: env.privacyPolicyUrl,
            onContactSupport: _contactSupport,
            onPrivacyPolicy: _privacyPolicy,
          ),
        ],
      ),
    );
  }
}
