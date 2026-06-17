// coverage:ignore-file

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Disables TLS certificate validation for the given [dio] instance (disabled
/// on web).
///
/// ⚠️ SECURITY WARNING: this trusts *every* certificate and must only be used
/// in debug builds (it is gated behind `kDebugMode` at the call site). Never
/// enable it in production — it makes the app vulnerable to man-in-the-middle
/// attacks.
void fixBadCertificate({required Dio dio}) {
  if (!kIsWeb) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // Don't trust any certificate just because their root cert is trusted.
        final HttpClient client =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
      validateCertificate: (cert, host, port) => true,
    );
  }
}
