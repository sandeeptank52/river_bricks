/// Doc-in-code: the state-management conventions every feature follows.
/// Referenced from code reviews and tests so the rules stay discoverable.
abstract final class StateManagementConventions {
  static const providerDefaults =
      'Use Riverpod 3 NotifierProvider.autoDispose and '
      'AsyncNotifierProvider.autoDispose for feature and screen state. '
      'Watch the narrowest field with select when a widget only needs one '
      'slice of a larger state object.';

  static const keepAliveRule =
      'A non-autoDispose provider is allowed only for app-wide infrastructure '
      'and must include a written keepAlive justification comment.';

  static const userScopedProviderRule =
      'Every user-scoped provider must call ref.watchUserSessionScope() so '
      'logout moves it to a fresh generation.';
}
