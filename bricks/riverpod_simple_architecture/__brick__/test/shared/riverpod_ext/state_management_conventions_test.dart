import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/state_management_conventions.dart';

void main() {
  test('conventions doc-in-code stays present and specific', () {
    expect(
      StateManagementConventions.providerDefaults,
      contains('NotifierProvider.autoDispose'),
    );
    expect(
      StateManagementConventions.keepAliveRule,
      contains('keepAlive justification'),
    );
    expect(
      StateManagementConventions.userScopedProviderRule,
      contains('watchUserSessionScope'),
    );
  });
}
