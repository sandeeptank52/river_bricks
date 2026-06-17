// StateProvider moved to the `legacy` entrypoint in Riverpod 3.x. It remains
// fully supported; this holder is overridden with the device translations at
// startup (see future_initializer.dart) and updated when the user changes
// locale (see app_locale_popup.dart).
import 'package:flutter_riverpod/legacy.dart';
import 'package:{{project_name.snakeCase()}}/i18n/strings.g.dart';

final translationsPod = StateProvider<Translations>(
  (ref) => throw UnimplementedError(
    "translations not overriden yet",
  ),
  name: 'translationsProvider',
);
