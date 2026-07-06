import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/widget/async_value_view.dart';

void main() {
  group('AsyncValueView', () {
    testWidgets('renders data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncValueView<int>(
            value: const AsyncValue.data(7),
            data: (context, value) => Text('value $value'),
          ),
        ),
      );
      expect(find.text('value 7'), findsOneWidget);
    });

    testWidgets('renders the shared loading view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncValueView<int>(
            value: const AsyncValue.loading(),
            data: (context, value) => Text('value $value'),
          ),
        ),
      );
      expect(find.byType(AsyncValueLoadingView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders errors through the AppFailure message mapper',
        (tester) async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.cancel,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncValueView<int>(
            value: AsyncValue.error(error, StackTrace.current),
            data: (context, value) => Text('value $value'),
          ),
        ),
      );
      expect(find.byType(AsyncValueErrorView), findsOneWidget);
      expect(find.text('Request cancelled'), findsOneWidget);
    });
  });
}
