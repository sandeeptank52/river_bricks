import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage.dart';
import 'package:{{project_name.snakeCase()}}/core/local_storage/app_storage_pod.dart';

Future<void> main() async {
  group(
    'App Storage Test',
    () {
      final AppStorage appStorage = AppStorage(null);
      setUp(() async {
        await appStorage.init(isTest: true);
      });
      tearDown(() async {
        await appStorage.clearAllData();
      });

      test('throw exception without intialization', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // Riverpod 3 wraps build-time errors in a ProviderException; match on
        // the underlying message rather than the wrapper type.
        expect(
          () => container.read(appStorageProvider),
          throwsA(
            predicate(
              (e) => e.toString().contains('appBoxProvider is not overriden'),
            ),
          ),
        );
      });

      test('intiailize and check box have no data', () {
        final container = ProviderContainer(
          overrides: [appStorageProvider.overrideWithValue(appStorage)],
        );
        addTearDown(container.dispose);
        container.read(appStorageProvider);

        expect(appStorage.appBox?.values.isEmpty, true);
        expect(appStorage.appBox?.toMap(), equals({}));
      });

      test('store a value and check not null in the box', () async {
        final container = ProviderContainer(
          overrides: [appStorageProvider.overrideWithValue(appStorage)],
        );
        addTearDown(container.dispose);
        container.read(appStorageProvider);

        await appStorage.put(key: 'hello', value: 'world');

        expect(appStorage.appBox?.values.isEmpty, false);
        expect(appStorage.appBox?.toMap(), equals({'hello': 'world'}));
        expect(appStorage.get(key: 'hello'), isNotNull);
        expect(appStorage.get(key: 'hello'), equals('world'));
      });

      test('check cleardata and box should be empty', () async {
        final container = ProviderContainer(
          overrides: [appStorageProvider.overrideWithValue(appStorage)],
        );
        addTearDown(container.dispose);
        container.read(appStorageProvider);

        await appStorage.clearAllData();

        expect(appStorage.appBox?.values.isEmpty, true);
        expect(appStorage.appBox?.toMap(), equals({}));
        expect(appStorage.get(key: 'hello'), isNull);
      });
    },
  );
}
