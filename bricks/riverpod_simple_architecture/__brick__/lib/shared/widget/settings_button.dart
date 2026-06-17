import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

/// App-bar action that opens the [SettingsPage].
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsPod);
    return IconButton(
      key: const ValueKey('settings_button'),
      icon: const Icon(Icons.settings),
      tooltip: t.settings.title,
      onPressed: () => context.router.push(const SettingsRoute()),
    );
  }
}
