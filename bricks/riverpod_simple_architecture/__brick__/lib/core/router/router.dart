import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/router/guards.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';

/// App route table. Splash (initial), `/settings`, and the `*` NotFound
/// wildcard are scaffold-owned; the routes in between are generated from the
/// resolved stack's screen list with per-route guard flags.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({
    super.navigatorKey,
    NavigationStateReader? read,
    Listenable? reevaluateListenable,
  })  : {{#has_onboarding_routes}}_onboardingGuard = OnboardingGuard(read),
        {{/has_onboarding_routes}}{{#has_auth_routes}}_authGuard = AuthGuard(read),
        {{/has_auth_routes}}_reevaluateListenable = reevaluateListenable{{^has_any_guards}},
        _read = read{{/has_any_guards}};

{{#has_onboarding_routes}}
  final OnboardingGuard _onboardingGuard;
{{/has_onboarding_routes}}
{{#has_auth_routes}}
  final AuthGuard _authGuard;
{{/has_auth_routes}}
  final Listenable? _reevaluateListenable;
{{^has_any_guards}}
  // Kept so re-pointing guard_state.dart later (adding guards) is a
  // router-file-only change.
  // ignore: unused_field
  final NavigationStateReader? _read;
{{/has_any_guards}}

  @override
  RouterConfig<UrlState> config({
    DeepLinkTransformer? deepLinkTransformer,
    DeepLinkBuilder? deepLinkBuilder,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    bool includePrefixMatches = !kIsWeb,
    bool Function(String? location)? neglectWhen,
    bool rebuildStackOnDeepLink = false,
    Listenable? reevaluateListenable,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return super.config(
      deepLinkTransformer: deepLinkTransformer,
      deepLinkBuilder: deepLinkBuilder,
      navRestorationScopeId: navRestorationScopeId,
      placeholder: placeholder,
      navigatorObservers: navigatorObservers,
      includePrefixMatches: includePrefixMatches,
      neglectWhen: neglectWhen,
      rebuildStackOnDeepLink: rebuildStackOnDeepLink,
      reevaluateListenable: reevaluateListenable ?? _reevaluateListenable,
      clipBehavior: clipBehavior,
    );
  }

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),
{{#routes}}
    AutoRoute(
      page: {{pascal_name}}Route.page,
      path: '{{{path}}}',{{#has_guards}}
      guards: [{{#requires_onboarding}}_onboardingGuard, {{/requires_onboarding}}{{#requires_auth}}_authGuard{{/requires_auth}}],{{/has_guards}}
    ),
{{/routes}}
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: NotFoundRoute.page, path: '*'),
  ];
}
