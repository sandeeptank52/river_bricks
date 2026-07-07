import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/core/router/guard_state.dart';
import 'package:{{project_name.snakeCase()}}/core/router/placeholder_pages.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router_pod.dart';
import 'package:{{project_name.snakeCase()}}/features/splash/view/not_found_page.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

void main() {
  group('AppRouter', () {
    test('defines the complete typed route table', () {
      final router = AppRouter();
      final routesByName = {
        for (final route in router.routes) route.name: route,
      };

      expect(routesByName['SplashRoute']?.path, '/splash');
      expect(routesByName['SplashRoute']?.initial, isTrue);
{{#routes}}
      expect(routesByName['{{pascal_name}}Route']?.path, '{{{path}}}');
{{#has_guards}}
      expect(
        routesByName['{{pascal_name}}Route']?.guards,
        isNotEmpty,
        reason: '{{pascal_name}}Route must be state-gated.',
      );
{{/has_guards}}
{{/routes}}
      expect(routesByName['SettingsRoute']?.path, '/settings');
      expect(router.routes.last.name, 'NotFoundRoute');
      expect(router.routes.last.path, '*');
    });

    test('guard state exposes stable boolean router contracts', () {
      final container = _container();
      addTearDown(container.dispose);

      expect(container.read(onboardingCompleteProvider), isFalse);
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(authResolvingProvider), isFalse);

      container.read(onboardingStateProvider.notifier).markComplete();
      container.read(mockAuthStateProvider.notifier).signIn();

      expect(container.read(onboardingCompleteProvider), isTrue);
      expect(container.read(isAuthenticatedProvider), isTrue);
    });
{{#has_onboarding_routes}}

    testWidgets('splash replaces fresh installs with the onboarding entry', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      expect(find.byType({{onboarding_route_pascal}}Page), findsOneWidget);
      expect(container.read(autorouterProvider).stack.length, 1);
    });
{{/has_onboarding_routes}}
{{#has_auth_routes}}

    testWidgets('splash replaces {{#has_onboarding_routes}}onboarded {{/has_onboarding_routes}}signed-out users with login', (
      tester,
    ) async {
      final container = _container();
{{#has_onboarding_routes}}
      container.read(onboardingStateProvider.notifier).markComplete();
{{/has_onboarding_routes}}
      addTearDown(container.dispose);

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      expect(find.byType({{login_route_pascal}}Page), findsOneWidget);
      expect(container.read(autorouterProvider).stack.length, 1);
    });

    testWidgets('splash replaces signed-in users with the landing route', (
      tester,
    ) async {
      final container = _container();
{{#has_onboarding_routes}}
      container.read(onboardingStateProvider.notifier).markComplete();
{{/has_onboarding_routes}}
      container.read(mockAuthStateProvider.notifier).signIn();
      addTearDown(container.dispose);

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      expect(find.byType({{initial_route_pascal}}Page), findsOneWidget);
      expect(container.read(autorouterProvider).stack.length, 1);
    });

    testWidgets('logout reevaluation clears protected stack to login', (
      tester,
    ) async {
      final container = _container();
{{#has_onboarding_routes}}
      container.read(onboardingStateProvider.notifier).markComplete();
{{/has_onboarding_routes}}
      container.read(mockAuthStateProvider.notifier).signIn();
      addTearDown(container.dispose);

      final router = await _pumpRouter(tester, container);
      await tester.pumpAndSettle();
      expect(find.byType({{initial_route_pascal}}Page), findsOneWidget);

      container.read(mockAuthStateProvider.notifier).signOut();
      await _pumpFrames(tester);

      expect(find.byType({{login_route_pascal}}Page), findsOneWidget);
      expect(router.stack.length, 1);
    });
{{/has_auth_routes}}
{{^has_any_guards}}

    testWidgets('splash replaces itself with the landing route', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      expect(find.byType({{initial_route_pascal}}Page), findsOneWidget);
      expect(container.read(autorouterProvider).stack.length, 1);
    });
{{/has_any_guards}}

    testWidgets('wildcard route renders NotFound with recovery CTA', (
      tester,
    ) async {
      final container = _container();
{{#has_onboarding_routes}}
      container.read(onboardingStateProvider.notifier).markComplete();
{{/has_onboarding_routes}}
{{#has_auth_routes}}
      container.read(mockAuthStateProvider.notifier).signIn();
{{/has_auth_routes}}
      addTearDown(container.dispose);

      final router = await _pumpRouter(tester, container);
      await tester.pumpAndSettle();
      router.pushPath('/definitely-missing-page');
      await _pumpFrames(tester);

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text('Page not found'), findsOneWidget);
      await tester.tap(find.text('Go to safety'));
      await tester.pumpAndSettle();
      expect(find.byType({{initial_route_pascal}}Page), findsOneWidget);
    });
  });
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      translationsPod.overrideWith((ref) => AppLocale.en.buildSync()),
    ],
  );
}

Future<AppRouter> _pumpRouter(
  WidgetTester tester,
  ProviderContainer container,
) async {
  late AppRouter router;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          router = ref.watch(autorouterProvider);
          return MaterialApp.router(
            routerConfig: router.config(
              placeholder: (_) => const SizedBox.shrink(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return router;
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
