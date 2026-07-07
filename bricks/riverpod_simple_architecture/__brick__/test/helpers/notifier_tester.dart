import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` is exported from the `misc` entrypoint in Riverpod 3.x.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' as ft;

/// Lightweight, dependency-free replacement for the `riverpod_test` package's
/// `testNotifier`.
///
/// `riverpod_test` is pinned to Riverpod 2.x and has no Riverpod 3 release, so
/// this template ships its own tiny helper. It spins up a [ProviderContainer],
/// records every state emitted by [provider], optionally runs [act] against the
/// notifier, and asserts the collected states equal [expect].
///
/// * [emitBuildStates] — when `true`, the initial build state is recorded too.
/// * [skip] — drops the first N recorded states before comparing.
void testNotifier<N extends Notifier<T>, T>(
  String description, {
  required NotifierProvider<N, T> provider,
  required List<Object?> Function() expect,
  List<Override> overrides = const [],
  FutureOr<void> Function()? setUp,
  FutureOr<void> Function(N notifier)? act,
  bool emitBuildStates = false,
  int skip = 0,
}) {
  ft.test(description, () async {
    final container = ProviderContainer(overrides: overrides);
    ft.addTearDown(container.dispose);

    if (setUp != null) await setUp();

    final states = <T>[];
    container.listen<T>(
      provider,
      (previous, next) => states.add(next),
      fireImmediately: emitBuildStates,
    );
    // Make sure the provider is built even when we are not capturing the
    // initial build state.
    if (!emitBuildStates) container.read(provider);

    if (act != null) await act(container.read(provider.notifier));
    await ft.pumpEventQueue();

    final result = skip > 0 ? states.skip(skip).toList() : states;
    ft.expect(result, expect());
  });
}
