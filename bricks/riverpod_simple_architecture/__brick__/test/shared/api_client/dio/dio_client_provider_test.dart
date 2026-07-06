import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_api_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_time_response_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/dio_client_provider.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/form_data_interceptor.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';

void main() {
  group("dio Client Provider", () {
    test('fails fast when AppEnv.apiBaseUrl is not configured', () {
      final container = ProviderContainer(
        overrides: [
          appEnvPod.overrideWithValue(
            const AppEnv(
              flavor: AppFlavor.development,
              apiBaseUrl: '',
              supportEmail: '',
              privacyPolicyUrl: '',
              termsOfServiceUrl: '',
              refundPolicyUrl: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      Object? error;
      try {
        container.read(dioProvider);
      } catch (e) {
        error = e;
      }
      expect(
        error.toString(),
        contains('AppEnv.apiBaseUrl is not configured'),
      );
    });

    test('reads baseUrl from the flavored AppEnv and wires interceptors', () {
      final container = ProviderContainer(
        overrides: [
          appEnvPod.overrideWithValue(
            const AppEnv(
              flavor: AppFlavor.development,
              apiBaseUrl: 'https://api.example.dev',
              supportEmail: '',
              privacyPolicyUrl: '',
              termsOfServiceUrl: '',
              refundPolicyUrl: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);
      expect(
        dio,
        isA<DioForNative>()
            .having(
              (d) => d.options.baseUrl,
              'baseUrl comes from AppEnv',
              equals('https://api.example.dev'),
            )
            .having(
              (d) => d.interceptors,
              "Contains the default interceptors",
              containsAll([
                isA<TimeResponseInterceptor>(),
                isA<FormDataInterceptor>(),
                isA<TalkerDioLogger>(),
                isA<DefaultAPIInterceptor>(),
              ]),
            ),
      );
    });
  });
}
