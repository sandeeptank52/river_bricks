import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

/// Known provider ids → the `.env.example` block flags they enable. Unknown
/// providers fall into the generic `other_providers` block.
const _knownProviderFlags = <String, String>{
  'firebase': 'has_firebase',
  'firebase-suite': 'has_firebase',
  'firebase-auth': 'has_firebase',
  'supabase': 'has_supabase',
  'msg91': 'has_msg91',
  'appsflyer': 'has_appsflyer',
  'razorpay': 'has_razorpay',
  'cashfree': 'has_cashfree',
  'truecaller': 'has_truecaller',
  'revenuecat': 'has_revenuecat',
  'onesignal': 'has_onesignal',
};

/// Locale code → native display name for the locale-picker strings. Unknown
/// codes fall back to the upper-cased code.
const _localeDisplayNames = <String, String>{
  'en': 'English',
  'hi': 'हिन्दी',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'bn': 'বাংলা',
  'mr': 'मराठी',
  'gu': 'ગુજરાતી',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'pa': 'ਪੰਜਾਬੀ',
  'ur': 'اردو',
  'es': 'Español',
};

String _snake(String value) => value
    .trim()
    .replaceAll(RegExp(r'[\s\-]+'), '_')
    .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '')
    .toLowerCase();

String _pascal(String value) => _snake(value)
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join();

Never _fail(HookContext context, String message) {
  context.logger.err(message);
  throw Exception(message);
}

void run(HookContext context) {
  context.logger.info('Pre generation started');

  // Resolve project_name: prefer the declared var, fall back to host pubspec.yaml.
  final providedName =
      ((context.vars['project_name'] as String?)?.trim() ?? '');

  String projectName;
  if (providedName.isNotEmpty) {
    projectName = providedName;
  } else {
    // Fall back to reading the `name:` field from the host pubspec.yaml.
    final pubspec = File(path.join('.', 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      _fail(context, 'Could not find pubspec.yaml');
    }

    final content = pubspec.readAsStringSync();
    final yamlMap = loadYaml(content) as YamlMap?;
    final defaultName = yamlMap?['name'] as String?;
    if (defaultName == null) {
      _fail(context, 'Could not find the "name" field in pubspec.yaml');
    }
    projectName = defaultName;
  }

  // Set the resolved project name in context vars.
  context.vars['project_name'] = projectName;
  context.logger.info('Project name: $projectName');

  // Derive a display title from the project name when not provided.
  final providedTitle = (context.vars['app_title'] as String?)?.trim() ?? '';
  if (providedTitle.isEmpty) {
    final title = projectName
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    context.vars['app_title'] = title;
  } else {
    context.vars['app_title'] = providedTitle;
  }

  // Normalize the seed color: strip a leading '#' and whitespace.
  final seed = (context.vars['seed_color'] as String?)?.trim() ?? '3F51B5';
  context.vars['seed_color'] =
      seed.startsWith('#') ? seed.substring(1) : seed;

  // ── backend ────────────────────────────────────────────────────────────────
  final backend =
      ((context.vars['backend'] as String?)?.trim().toLowerCase() ?? 'none');
  if (!{'firebase', 'supabase', 'none'}.contains(backend)) {
    _fail(context, 'backend must be one of firebase|supabase|none, got '
        '"$backend"');
  }
  context.vars['backend'] = backend;
  context.vars['backend_firebase'] = backend == 'firebase';
  context.vars['backend_supabase'] = backend == 'supabase';

  // ── languages (first = base; 'en' always included and always base) ────────
  final rawLanguages = (context.vars['languages'] as List?) ?? const ['en'];
  final languageCodes = <String>[];
  for (final entry in rawLanguages) {
    final code = _snake(entry.toString());
    if (code.isEmpty) continue;
    if (!RegExp(r'^[a-z]{2,3}$').hasMatch(code)) {
      _fail(context, 'languages entries must be 2-3 letter locale codes, '
          'got "$entry"');
    }
    if (!languageCodes.contains(code)) languageCodes.add(code);
  }
  languageCodes.remove('en');
  languageCodes.insert(0, 'en');
  context.vars['languages'] = [
    for (final code in languageCodes)
      {
        'code': code,
        'display': _localeDisplayNames[code] ?? code.toUpperCase(),
        'is_base': code == 'en',
      },
  ];
  context.vars['language_codes'] = languageCodes;

  // ── features (skeletons only; content stays agent-owned) ──────────────────
  final rawFeatures = (context.vars['features'] as List?) ?? const [];
  final features = <Map<String, Object>>[];
  const reservedFeatures = {'splash', 'settings'};
  for (final entry in rawFeatures) {
    String name;
    var data = false;
    if (entry is Map) {
      name = _snake('${entry['name'] ?? ''}');
      data = entry['data'] == true;
    } else {
      name = _snake(entry.toString());
    }
    if (name.isEmpty) {
      _fail(context, 'features entries must have a non-empty name, '
          'got "$entry"');
    }
    if (reservedFeatures.contains(name)) continue; // brick-owned features
    if (features.any((feature) => feature['name'] == name)) continue;
    features.add({'name': name, 'data': data});
  }
  context.vars['features'] = features;

  // ── routes (splash/settings/not_found are brick-owned; strip collisions) ──
  final rawRoutes = (context.vars['routes'] as List?) ?? const [];
  var routes = <Map<String, Object>>[];
  const reservedRoutes = {'splash', 'settings', 'not_found'};
  for (final entry in rawRoutes) {
    if (entry is! Map) {
      _fail(context, 'routes entries must be maps '
          '({name, path, requires_onboarding, requires_auth, initial}), '
          'got "$entry"');
    }
    final name = _snake('${entry['name'] ?? ''}');
    final routePath = '${entry['path'] ?? ''}'.trim();
    if (name.isEmpty || !routePath.startsWith('/')) {
      _fail(context, 'route needs a name and a path starting with "/", '
          'got "$entry"');
    }
    if (reservedRoutes.contains(name)) continue;
    final requiresOnboarding = entry['requires_onboarding'] == true;
    final requiresAuth = entry['requires_auth'] == true;
    routes.add({
      'name': name,
      'pascal_name': _pascal(name),
      'path': routePath,
      'requires_onboarding': requiresOnboarding,
      'requires_auth': requiresAuth,
      'has_guards': requiresOnboarding || requiresAuth,
      'initial': entry['initial'] == true,
    });
  }
  // Fallback when no routes were provided: a single guardless home route.
  if (routes.isEmpty) {
    routes = [
      {
        'name': 'home',
        'pascal_name': 'Home',
        'path': '/',
        'requires_onboarding': false,
        'requires_auth': false,
        'has_guards': false,
        'initial': true,
      },
    ];
  }
  final hasOnboardingRoutes =
      routes.any((route) => route['requires_onboarding'] == true);
  final hasAuthRoutes = routes.any((route) => route['requires_auth'] == true);

  // The post-splash landing route: explicit initial flag, else path '/', else
  // the first route.
  final initialRoute = routes.firstWhere(
    (route) => route['initial'] == true,
    orElse: () => routes.firstWhere(
      (route) => route['path'] == '/',
      orElse: () => routes.first,
    ),
  );

  // OnboardingGuard redirect target: the first fully-unguarded route (the
  // onboarding entry screen). Required whenever any route needs onboarding.
  Map<String, Object>? onboardingRoute;
  if (hasOnboardingRoutes) {
    onboardingRoute = routes.cast<Map<String, Object>?>().firstWhere(
          (route) =>
              route!['requires_onboarding'] == false &&
              route['requires_auth'] == false &&
              route != initialRoute,
          orElse: () => null,
        );
    onboardingRoute ??= routes.cast<Map<String, Object>?>().firstWhere(
          (route) =>
              route!['requires_onboarding'] == false &&
              route['requires_auth'] == false,
          orElse: () => null,
        );
    if (onboardingRoute == null) {
      _fail(context, 'routes require onboarding but no unguarded onboarding '
          'entry route exists (a route with requires_onboarding=false and '
          'requires_auth=false).');
    }
  }

  // AuthGuard redirect target: a login-ish unauthenticated route. Required
  // whenever any route needs auth.
  Map<String, Object>? loginRoute;
  if (hasAuthRoutes) {
    final loginPattern = RegExp(r'login|sign_?in');
    loginRoute = routes.cast<Map<String, Object>?>().firstWhere(
          (route) =>
              route!['requires_auth'] == false &&
              loginPattern.hasMatch(route['name']! as String),
          orElse: () => null,
        );
    if (loginRoute == null) {
      _fail(context, 'routes require auth but no login route exists (an '
          'unauthenticated route whose name contains "login"/"sign_in").');
    }
  }

  context.vars['routes'] = routes;
  context.vars['has_onboarding_routes'] = hasOnboardingRoutes;
  context.vars['has_auth_routes'] = hasAuthRoutes;
  context.vars['has_any_guards'] = hasOnboardingRoutes || hasAuthRoutes;
  context.vars['initial_route_pascal'] = initialRoute['pascal_name'];
  context.vars['onboarding_route_pascal'] =
      onboardingRoute?['pascal_name'] ?? '';
  context.vars['login_route_pascal'] = loginRoute?['pascal_name'] ?? '';

  // ── providers (drive the .env.example blocks) ─────────────────────────────
  final rawProviders = (context.vars['providers'] as List?) ?? const [];
  final providers = <String>[];
  for (final entry in rawProviders) {
    final id = entry.toString().trim().toLowerCase();
    if (id.isNotEmpty && !providers.contains(id)) providers.add(id);
  }
  for (final flag in _knownProviderFlags.values.toSet()) {
    context.vars[flag] = false;
  }
  final otherProviders = <String>[];
  for (final id in providers) {
    final flag = _knownProviderFlags[id];
    if (flag != null) {
      context.vars[flag] = true;
    } else {
      otherProviders.add(id);
    }
  }
  // Backend identity implies its env block even when not listed as a provider.
  if (backend == 'firebase') context.vars['has_firebase'] = true;
  if (backend == 'supabase') context.vars['has_supabase'] = true;
  context.vars['providers'] = providers;
  context.vars['other_providers'] = otherProviders;
  context.vars['has_other_providers'] = otherProviders.isNotEmpty;

  context.logger
    ..info('App title: ${context.vars['app_title']}')
    ..info('Seed color: ${context.vars['seed_color']}')
    ..info('Backend: $backend')
    ..info('Languages: ${languageCodes.join(', ')}')
    ..info('Routes: ${routes.map((route) => route['path']).join(', ')}')
    ..info('Features: ${features.map((feature) => feature['name']).join(', ')}')
    ..info('Providers: ${providers.join(', ')}')
    ..info('Pre generation completed');
}
