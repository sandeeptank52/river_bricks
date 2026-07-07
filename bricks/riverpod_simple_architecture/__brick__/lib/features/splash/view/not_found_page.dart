import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

/// Wildcard (`*`) recovery page: any unknown location lands here with a CTA
/// back to the splash resolver.
@RoutePage()
class NotFoundPage extends ConsumerWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsPod).navigation.notFound;
    final tokens = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: tokens.spaceM),
              Text(
                t.message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceL),
              FilledButton.icon(
                onPressed: () {
                  context.router.replaceAll([const SplashRoute()]);
                },
                icon: const Icon(Icons.home_outlined),
                label: Text(t.cta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
