import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '┌──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );
    developer.log(
      '│ 🌐 ${options.method} ${options.uri}',
      name: 'HTTP',
    );

    if (options.headers.isNotEmpty) {
      developer.log('│ Headers:', name: 'HTTP');
      options.headers.forEach((key, value) {
        if (key.toLowerCase() != 'authorization') {
          developer.log('│   $key: $value', name: 'HTTP');
        } else {
          developer.log('│   $key: [HIDDEN]', name: 'HTTP');
        }
      });
    }

    if (options.data != null) {
      developer.log('│ Body: ${options.data}', name: 'HTTP');
    }

    developer.log(
      '└──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '┌──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );
    developer.log(
      '│ ✅ ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
      name: 'HTTP',
    );
    developer.log('│ Response: ${response.data}', name: 'HTTP');
    developer.log(
      '└──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '┌──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );
    developer.log(
      '│ ❌ ${err.response?.statusCode ?? 'ERROR'} '
      '${err.requestOptions.method} ${err.requestOptions.uri}',
      name: 'HTTP',
    );
    developer.log('│ Error: ${err.message}', name: 'HTTP');
    if (err.response?.data != null) {
      developer.log('│ Response: ${err.response?.data}', name: 'HTTP');
    }
    developer.log(
      '└──────────────────────────────────────────────────────────────────',
      name: 'HTTP',
    );

    handler.next(err);
  }
}
