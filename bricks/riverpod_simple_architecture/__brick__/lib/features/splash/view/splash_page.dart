import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{#has_any_guards}}
import 'package:{{project_name.snakeCase()}}/core/router/guard_state.dart';
{{/has_any_guards}}
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';

/// Start-route resolution screen. Async app initialization happens before
/// `runApp` (see bootstrap.dart), so this page only ever shows while routing
/// decisions resolve — it replaces itself with the correct landing route.
@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
{{#has_onboarding_routes}}
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
{{/has_onboarding_routes}}
{{#has_auth_routes}}
    final authResolving = ref.watch(authResolvingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
{{/has_auth_routes}}

    final target = _targetRoute(
{{#has_onboarding_routes}}
      onboardingComplete: onboardingComplete,
{{/has_onboarding_routes}}
{{#has_auth_routes}}
      authResolving: authResolving,
      isAuthenticated: isAuthenticated,
{{/has_auth_routes}}
    );
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.router.replaceAll([target]);
        }
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  PageRouteInfo? _targetRoute({{#has_any_guards}}{
{{#has_onboarding_routes}}
    required bool onboardingComplete,
{{/has_onboarding_routes}}
{{#has_auth_routes}}
    required bool authResolving,
    required bool isAuthenticated,
{{/has_auth_routes}}
  }{{/has_any_guards}}) {
{{#has_onboarding_routes}}
    if (!onboardingComplete) {
      return const {{onboarding_route_pascal}}Route();
    }
{{/has_onboarding_routes}}
{{#has_auth_routes}}
    if (authResolving) {
      return null;
    }
    if (!isAuthenticated) {
      return const {{login_route_pascal}}Route();
    }
{{/has_auth_routes}}
    return const {{initial_route_pascal}}Route();
  }
}
