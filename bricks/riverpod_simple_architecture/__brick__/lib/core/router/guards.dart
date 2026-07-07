import 'package:flutter_riverpod/misc.dart';
{{#has_any_guards}}
import 'package:auto_route/auto_route.dart';
import 'package:{{project_name.snakeCase()}}/core/router/guard_state.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';
{{/has_any_guards}}

/// Reader injected into the router's guards so they can consult Riverpod
/// state without owning a container reference.
typedef NavigationStateReader = T Function<T>(ProviderListenable<T> provider);
{{#has_any_guards}}

T _unconfiguredNavigationStateReader<T>(ProviderListenable<T> provider) {
  throw StateError(
    'AppRouter guard state was read before a Riverpod reader was configured.',
  );
}
{{/has_any_guards}}
{{#has_onboarding_routes}}

/// Redirects any onboarding-gated route to the onboarding entry screen until
/// onboarding completes. `redirectUntil(..., replace: true)` keeps the stack
/// one deep — at most one redirect per navigation.
class OnboardingGuard extends AutoRouteGuard {
  OnboardingGuard([NavigationStateReader? read])
      : _read = read ?? _unconfiguredNavigationStateReader;

  final NavigationStateReader _read;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final onboardingComplete = _read(onboardingCompleteProvider);
    if (onboardingComplete) {
      resolver.next();
      return;
    }

    resolver.redirectUntil(const {{onboarding_route_pascal}}Route(), replace: true);
  }
}
{{/has_onboarding_routes}}
{{#has_auth_routes}}

/// Redirects auth-gated routes to login (or splash while auth state is still
/// resolving). Login itself stays reachable; reevaluation never redirects a
/// second time.
class AuthGuard extends AutoRouteGuard {
  AuthGuard([NavigationStateReader? read])
      : _read = read ?? _unconfiguredNavigationStateReader;

  final NavigationStateReader _read;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuthenticated = _read(isAuthenticatedProvider);
    if (isAuthenticated) {
      resolver.next();
      return;
    }

    final authResolving = _read(authResolvingProvider);

    if (resolver.isReevaluating) {
      resolver.resolveNext(false, reevaluateNext: false);
      return;
    }

    if (!authResolving && router.topRoute.name == {{login_route_pascal}}Route.name) {
      resolver.next(false);
      return;
    }

    resolver.redirectUntil(
      authResolving ? const SplashRoute() : const {{login_route_pascal}}Route(),
      replace: true,
    );
  }
}
{{/has_auth_routes}}
