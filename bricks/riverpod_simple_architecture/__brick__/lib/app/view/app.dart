import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name.snakeCase()}}/const/app_config.dart';
import 'package:{{project_name.snakeCase()}}/core/router/auto_route_observer.dart';
import 'package:{{project_name.snakeCase()}}/core/router/router_pod.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_theme.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/theme_controller.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';
import 'package:{{project_name.snakeCase()}}/shared/helper/global_helper.dart';
import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/no_internet_widget.dart';
{{#responsive}}import 'package:{{project_name.snakeCase()}}/shared/widget/responsive_wrapper.dart';
{{/responsive}}

///This class holds the ONE MaterialApp in the tree (router-driven), with
///theming, locale setup, text-scale clamping and system-bar styling.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with GlobalHelper {
  @override
  Widget build(BuildContext context) {
    final approuter = ref.watch(autorouterProvider);
    final currentTheme = ref.watch(themecontrollerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appTitle,
      theme: Themes.theme,
      darkTheme: Themes.darkTheme,
      themeMode: currentTheme,
      routerConfig: approuter.config(
        placeholder: (context) => const SizedBox.shrink(),
        navigatorObservers: () => [
          RouterObserver(),
        ],
      ),
      locale: ref.watch(translationsPod).$meta.locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        if (mounted) {
{{#responsive}}
          ///Used for responsive design
          ///Here you can define breakpoint and how the responsive should work
          child = ResponsiveBreakPointWrapper(
            firstFrameWidget: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: child!,
          );
{{/responsive}}
{{^responsive}}
          child = child!;
{{/responsive}}
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final tokens = AppTokens.of(context);
          final isDark = theme.brightness == Brightness.dark;

          /// Large-text users are supported up to the design-system target.
          final mediaquery = MediaQuery.of(context);
          child = MediaQuery(
            data: mediaquery.copyWith(
              textScaler: mediaquery.textScaler.clamp(
                maxScaleFactor: tokens.maxTextScale,
              ),
            ),
            child: child,
          );

          /// System bars follow the active Material color scheme.
          child = AnnotatedRegion<SystemUiOverlayStyle>(
            value: (isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(
              statusBarColor: colorScheme.surface.withValues(
                alpha: tokens.systemOverlaySurfaceOpacity,
              ),
              systemNavigationBarColor: colorScheme.surface,
              systemNavigationBarDividerColor: colorScheme.outlineVariant,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
            child: GestureDetector(
              child: child,
              onTap: () {
                hideKeyboard();
              },
            ),
          );
        } else {
          child = const SizedBox.shrink();
        }

        ///Add toast support for flash
        return Toast(
          navigatorKey: navigatorKey,
          child: child,
        ).monitorConnection();
      },
    );
  }
}
