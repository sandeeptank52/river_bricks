import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/shared/pods/translation_pod.dart';

void main() {
  test('translationsPod throws UnimplementedError when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Riverpod 3 wraps build-time errors in a ProviderException; match on the
    // underlying message rather than the wrapper type.
    expect(
      () => container.read(translationsPod),
      throwsA(
        predicate((e) => e.toString().contains('translations not overriden')),
      ),
    );
  });
}
