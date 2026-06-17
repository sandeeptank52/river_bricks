import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/riverpod_observer/riverpod_log.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/riverpod_observer/riverpod_obs.dart';
import 'package:{{project_name.snakeCase()}}/shared/riverpod_ext/riverpod_observer/talker_riverpod_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider lives in the `legacy` entrypoint in Riverpod 3.x.
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Riverpod 3 unified the observer callbacks behind a `ProviderObserverContext`
/// whose constructor is internal (it carries a private element), so the
/// observer can no longer be unit-tested by calling its methods directly.
/// Instead these tests attach the observer to a real [ProviderContainer] and
/// drive provider lifecycle events (add / update / dispose / fail), which is
/// also closer to how the observer is used in the app.
void main() {
  group('TalkerRiverpodObserver', () {
    late Talker talker;
    late TalkerRiverpodObserver observer;

    setUp(() {
      talker = Talker();
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(printProviderDisposed: true),
      );
      talker.history.clear();
    });

    ProviderContainer containerWith(TalkerRiverpodObserver obs) {
      final container = ProviderContainer(observers: [obs]);
      return container;
    }

    // ---- didAddProvider --------------------------------------------------
    test('didAddProvider logs when enabled and accepted', () {
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(Provider((ref) => 'test', name: 'testProvider'));
      expect(talker.history.whereType<RiverpodAddLog>().length, 1);
    });

    test('didAddProvider does not log when disabled', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(enabled: false),
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(Provider((ref) => 'test', name: 'testProvider'));
      expect(talker.history.whereType<RiverpodAddLog>().length, 0);
    });

    test('didAddProvider does not log when printProviderAdded is false', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(printProviderAdded: false),
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(Provider((ref) => 'test', name: 'testProvider'));
      expect(talker.history.whereType<RiverpodAddLog>().length, 0);
    });

    test('didAddProvider does not log when providerFilter rejects', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          providerFilter: (provider) => provider.name != 'testProvider',
        ),
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(Provider((ref) => 'test', name: 'testProvider'));
      expect(talker.history.whereType<RiverpodAddLog>().length, 0);
    });

    // ---- didUpdateProvider ------------------------------------------------
    test('didUpdateProvider logs when enabled and accepted', () {
      final provider = StateProvider((ref) => 'initial', name: 'testProvider');
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(provider);
      container.read(provider.notifier).state = 'updated';
      expect(talker.history.whereType<RiverpodUpdateLog>().length, 1);
    });

    test('didUpdateProvider does not log when disabled', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(enabled: false),
      );
      final provider = StateProvider((ref) => 'initial', name: 'testProvider');
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(provider);
      container.read(provider.notifier).state = 'updated';
      expect(talker.history.whereType<RiverpodUpdateLog>().length, 0);
    });

    test(
      'didUpdateProvider does not log when printProviderUpdated is false',
      () {
        observer = TalkerRiverpodObserver(
          talker: talker,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderUpdated: false,
          ),
        );
        final provider = StateProvider(
          (ref) => 'initial',
          name: 'testProvider',
        );
        final container = containerWith(observer);
        addTearDown(container.dispose);
        container.read(provider);
        container.read(provider.notifier).state = 'updated';
        expect(talker.history.whereType<RiverpodUpdateLog>().length, 0);
      },
    );

    test('didUpdateProvider does not log when providerFilter rejects', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          providerFilter: (provider) => provider.name != 'testProvider',
        ),
      );
      final provider = StateProvider((ref) => 'initial', name: 'testProvider');
      final container = containerWith(observer);
      addTearDown(container.dispose);
      container.read(provider);
      container.read(provider.notifier).state = 'updated';
      expect(talker.history.whereType<RiverpodUpdateLog>().length, 0);
    });

    // ---- didDisposeProvider ----------------------------------------------
    test('didDisposeProvider logs when enabled and accepted', () {
      final provider = Provider((ref) => 'test', name: 'testProvider');
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 1);
    });

    test('didDisposeProvider does not log when disabled', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(enabled: false),
      );
      final provider = Provider((ref) => 'test', name: 'testProvider');
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
    });

    test(
      'didDisposeProvider does not log when printProviderDisposed is false',
      () {
        observer = TalkerRiverpodObserver(
          talker: talker,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderDisposed: false,
          ),
        );
        final provider = Provider((ref) => 'test', name: 'testProvider');
        final container = containerWith(observer);
        container.read(provider);
        container.dispose();
        expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
      },
    );

    test('didDisposeProvider does not log when providerFilter rejects', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          providerFilter: (provider) => provider.name != 'testProvider',
        ),
      );
      final provider = Provider((ref) => 'test', name: 'testProvider');
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
    });

    test('didDisposeProvider does not log when provider is filtered out', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          // Filter out providers that don't have a name.
          providerFilter: (provider) => provider.name != null,
        ),
      );
      final provider = Provider((ref) => 'test'); // no name
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
    });

    test('didDisposeProvider does not log when provider type is filtered out',
        () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          // Filter out StateProviders.
          providerFilter: (provider) => provider is! StateProvider,
        ),
      );
      final provider = StateProvider((ref) => 0, name: 'filteredProvider');
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
    });

    test(
        'didDisposeProvider does not log when providerFilter rejects a FutureProvider',
        () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          printProviderDisposed: true,
          // Filter out FutureProviders.
          providerFilter: (provider) => provider is! FutureProvider,
        ),
      );
      final provider = FutureProvider((ref) => 'test', name: 'filteredProvider');
      final container = containerWith(observer);
      container.read(provider);
      container.dispose();
      expect(talker.history.whereType<RiverpodDisposeLog>().length, 0);
    });

    // ---- providerDidFail --------------------------------------------------
    test('providerDidFail logs when enabled and accepted', () {
      final provider = Provider<String>(
        (ref) => throw Exception('test error'),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 1);
    });

    test('providerDidFail does not log when disabled', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(enabled: false),
      );
      final provider = Provider<String>(
        (ref) => throw Exception('test error'),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 0);
    });

    test('providerDidFail does not log when printProviderFailed is false', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: const TalkerRiverpodLoggerSettings(
          printProviderFailed: false,
        ),
      );
      final provider = Provider<String>(
        (ref) => throw Exception('test error'),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 0);
    });

    test('providerDidFail does not log when providerFilter rejects', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          providerFilter: (provider) => provider.name != 'testProvider',
        ),
      );
      final provider = Provider<String>(
        (ref) => throw Exception('test error'),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 0);
    });

    test('providerDidFail does not log when didFailFilter rejects', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          didFailFilter: (error) =>
              error.toString() != Exception('test error').toString(),
        ),
      );
      final provider = Provider<String>(
        (ref) => throw Exception('test error'),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 0);
    });

    test('providerDidFail does not log when didFailFilter throws', () {
      observer = TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          // This filter will throw because Hello's toString() throws.
          didFailFilter: (error) => error.toString().isNotEmpty,
        ),
      );
      final provider = Provider<String>(
        (ref) => throw Hello(),
        name: 'testProvider',
      );
      final container = containerWith(observer);
      addTearDown(container.dispose);
      try {
        container.read(provider);
      } catch (_) {}
      expect(talker.history.whereType<RiverpodFailLog>().length, 0);
    });
  });
}

class Hello {
  void call() {
    throw UnimplementedError();
  }

  @override
  String toString() {
    throw UnimplementedError();
  }
}
