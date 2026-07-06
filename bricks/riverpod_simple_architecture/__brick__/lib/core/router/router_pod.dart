{{#has_auth_routes}}
import 'dart:async';

{{/has_auth_routes}}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/core/router/guard_state.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.dart';
{{#has_auth_routes}}
import 'package:{{project_name.snakeCase()}}/core/router/router.gr.dart';
{{/has_auth_routes}}

/// This global variable used for global working on ui elements where
/// may be context is not present
final navigatorKey = GlobalKey<NavigatorState>();

/// Re-runs route guards whenever the guard-state providers flip, so an
/// already-mounted stack reacts to onboarding/auth changes.
final routerReevaluateListenableProvider =
    Provider.autoDispose<RouterReevaluateListenable>((ref) {
  final notifier = RouterReevaluateListenable();
  ref
    ..listen(onboardingCompleteProvider, (_, _) => notifier.trigger())
    ..listen(isAuthenticatedProvider, (_, _) => notifier.trigger())
    ..listen(authResolvingProvider, (_, _) => notifier.trigger())
    ..onDispose(notifier.dispose);
  return notifier;
}, name: 'routerReevaluateListenableProvider');

class RouterReevaluateListenable extends ChangeNotifier {
  void trigger() {
    notifyListeners();
  }
}

/// This provider used for storing router
/// and can be acessed by reading it using ProviderRef/WidgetRef
final autorouterProvider = Provider.autoDispose<AppRouter>((ref) {
  final router = AppRouter(
    navigatorKey: navigatorKey,
    read: ref.read,
    reevaluateListenable: ref.watch(routerReevaluateListenableProvider),
  );
{{#has_auth_routes}}

  ref.listen(isAuthenticatedProvider, (previous, next) {
    if (previous == true && !next && !ref.read(authResolvingProvider)) {
      unawaited(router.replaceAll([const {{login_route_pascal}}Route()]));
    }
  });
{{/has_auth_routes}}

  return router;
}, name: 'autorouterProvider');
