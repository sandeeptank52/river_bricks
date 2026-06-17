import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

// coverage:ignore-file
/// Optional alternative to [TalkerRiverpodObserver] that logs provider
/// updates through [Talker].
///
/// Riverpod 3 unified the observer callbacks behind a
/// [ProviderObserverContext] and made [ProviderObserver] a `base` class, so
/// subclasses must also be marked `base`. Wire this up via the `observers`
/// of your [ProviderContainer]/[ProviderScope] if you prefer this output over
/// the default talker observer.
base class MyObserverLogger extends ProviderObserver {
  MyObserverLogger({required this.talker});
  final Talker talker;

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final provider = context.provider;
    final name = provider.name != null
        ? '${provider.name} of Type `${provider.runtimeType}`'
        : '${provider.runtimeType}';

    if (newValue is AsyncValue && previousValue is AsyncValue?) {
      talker.log('Provider is: $name \n'
          'previous value: ${previousValue?.value} \n'
          'new value: ${newValue.value}');
    } else {
      talker.log('Provider is: $name \n'
          'previous value: $previousValue\n'
          'new value: $newValue');
    }
  }
}
