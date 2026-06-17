import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_api_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_time_response_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/dio_client_provider.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/form_data_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

void main() {
  test(
    'expect dio.baseUrl should be "https://randomuser.me/api/" '
    'with the configured interceptors',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      expect(
        dio,
        isA<DioForNative>()
            .having(
              (d) => d.options.baseUrl,
              'baseUrl',
              equals("https://randomuser.me/api/"),
            )
            .having(
              (d) => d.interceptors.length,
              "interceptors length",
              equals(5),
            )
            .having(
                (d) => d.interceptors,
                "configured interceptors",
                containsAll(
                  [
                    isA<TimeResponseInterceptor>(),
                    isA<FormDataInterceptor>(),
                    isA<TalkerDioLogger>(),
                    isA<DefaultAPIInterceptor>(),
                  ],
                )),
      );
    },
  );
}
