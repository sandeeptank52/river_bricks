import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:{{project_name.snakeCase()}}/bootstrap.dart';
import 'package:{{project_name.snakeCase()}}/const/app_env.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/bad_certificate_fixer.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_api_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/default_time_response_interceptor.dart';
import 'package:{{project_name.snakeCase()}}/shared/api_client/dio/form_data_interceptor.dart';

///This provider dioClient with interceptors(TimeResponseInterceptor,FormDataInterceptor,TalkerDioLogger,DefaultAPIInterceptor)
///with fixing bad certificate.
///
/// Retry policy is owned by the backend/auth integration goal — do not add
/// ad-hoc retries here.
final dioProvider = Provider.autoDispose<Dio>(
  (ref) {
    final env = ref.watch(appEnvPod);
    // Fail fast on misconfiguration: an empty base URL means the backend for
    // this flavor hasn't been wired — silently defaulting would send requests
    // to the wrong host.
    if (env.apiBaseUrl.isEmpty) {
      throw StateError(
        'AppEnv.apiBaseUrl is not configured for ${env.flavor.name}; '
        'no API calls are possible until the backend is wired.',
      );
    }
    final dio = Dio();
    dio.options.baseUrl = env.apiBaseUrl;
    if (kDebugMode) {
      dio.interceptors.add(TimeResponseInterceptor());
      dio.interceptors.add(FormDataInterceptor());
      dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: true,
            printRequestData: false,
            printResponseData: false,
          ),
        ),
      );
    }

    dio.interceptors.addAll([DefaultAPIInterceptor(dio: dio)]);
    // SECURITY: relaxing TLS certificate validation is only done in debug
    // builds (e.g. to talk to a local server with a self-signed cert). Trusting
    // all certificates in production enables man-in-the-middle attacks.
    if (kDebugMode) {
      fixBadCertificate(dio: dio);
    }
    return dio;
  },
  name: 'dioProvider',
);
