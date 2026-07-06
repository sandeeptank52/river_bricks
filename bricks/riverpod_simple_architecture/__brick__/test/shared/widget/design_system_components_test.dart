import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_color_theme.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_theme.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/design_system_components.dart';

void main() {
  group('shared design-system components', () {
    testWidgets('selectable card shows brand primary border when selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ThemeHarness(
          child: AppSelectableCard(
            selected: true,
            onTap: () {},
            child: const Text('Option one'),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byKey(AppSelectableCard.containerKey),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, AppColorTheme.light.primary);
    });

    testWidgets('primary button renders as brand pill', (tester) async {
      await tester.pumpWidget(
        _ThemeHarness(
          child: AppPrimaryButton(
            onPressed: () {},
            child: const Text('Continue'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!;
      final shape = style.shape!.resolve({})! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 28);
      expect(style.backgroundColor!.resolve({}), AppColorTheme.light.primary);
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        AppColorTheme.light.primarySoft,
      );
    });

    testWidgets('primary CTA supports enabled, disabled, and loading states', (
      tester,
    ) async {
      var taps = 0;

      await tester.pumpWidget(
        _ThemeHarness(
          child: AppPrimaryButton(
            onPressed: () => taps++,
            child: const Text('Continue'),
          ),
        ),
      );
      await tester.tap(find.byType(AppPrimaryButton));
      expect(taps, 1);

      await tester.pumpWidget(
        const _ThemeHarness(
          child: AppPrimaryButton(onPressed: null, child: Text('Continue')),
        ),
      );
      await tester.tap(find.byType(AppPrimaryButton));
      expect(taps, 1);

      await tester.pumpWidget(
        _ThemeHarness(
          child: AppPrimaryButton(
            isLoading: true,
            onPressed: () => taps++,
            child: const Text('Continue'),
          ),
        ),
      );
      await tester.tap(find.byType(AppPrimaryButton));
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('category chip row wraps and reports selected ids', (
      tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        _ThemeHarness(
          child: AppCategoryChipRow(
            selectedId: 'first',
            items: const [
              AppCategoryChipItem(id: 'first', label: 'First category'),
              AppCategoryChipItem(id: 'second', label: 'Second category'),
              AppCategoryChipItem(id: 'third', label: 'Third category'),
            ],
            onSelected: (id) => selected = id,
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      await tester.tap(find.text('Second category'));
      expect(selected, 'second');
    });

    testWidgets('playable list tile exposes play and pause affordances', (
      tester,
    ) async {
      var taps = 0;

      await tester.pumpWidget(
        _ThemeHarness(
          child: AppPlayableListTile(
            title: 'Track title',
            subtitle: 'Category',
            isPlaying: false,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(find.byType(AppPlayableListTile));
      expect(taps, 1);

      await tester.pumpWidget(
        _ThemeHarness(
          child: AppPlayableListTile(
            title: 'Track title',
            subtitle: 'Category',
            isPlaying: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('bottom-sheet scaffold lays out title, action, and body', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ThemeHarness(
          child: AppBottomSheetScaffold(
            title: Text('Pick a language'),
            action: Text('Save'),
            child: Text('English'),
          ),
        ),
      );

      expect(find.text('Pick a language'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('components avoid overflow at 320dp and text scale 2.0', (
      tester,
    ) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);

      await tester.pumpWidget(
        _ThemeHarness(
          textScaler: const TextScaler.linear(2),
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppSelectableCard(
                  selected: true,
                  onTap: () {},
                  child: const Text(_longLabel),
                ),
                AppPrimaryButton(
                  onPressed: () {},
                  child: const Text(_longLabel),
                ),
                AppCategoryChipRow(
                  selectedId: 'long',
                  items: const [
                    AppCategoryChipItem(id: 'long', label: _longLabel),
                    AppCategoryChipItem(id: 'second', label: 'Second'),
                  ],
                  onSelected: (_) {},
                ),
                AppPlayableListTile(
                  title: _longLabel,
                  subtitle: 'A long descriptive subtitle for a small phone',
                  isPlaying: false,
                  onPressed: () {},
                ),
                const AppBottomSheetScaffold(
                  title: Text(_longLabel),
                  child: Text('Body content'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        errors.where(
          (error) => error.exceptionAsString().contains('overflowed by'),
        ),
        isEmpty,
      );
    });

    testWidgets('components render under the dark theme too', (tester) async {
      await tester.pumpWidget(
        _ThemeHarness(
          dark: true,
          child: Column(
            children: [
              AppSelectableCard(
                selected: false,
                onTap: () {},
                child: const Text('Dark option'),
              ),
              AppPrimaryButton(
                onPressed: () {},
                child: const Text('Dark CTA'),
              ),
            ],
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byKey(AppSelectableCard.containerKey),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColorTheme.dark.surfaceCard);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.style!.backgroundColor!.resolve({}),
        AppColorTheme.dark.primary,
      );
    });
  });
}

const _longLabel =
    'A very long option label that must stay readable on small phones '
    'without overflowing the layout';

class _ThemeHarness extends StatelessWidget {
  const _ThemeHarness({required this.child, this.textScaler, this.dark = false});

  final Widget child;
  final TextScaler? textScaler;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: dark ? Themes.darkTheme : Themes.theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }
}
