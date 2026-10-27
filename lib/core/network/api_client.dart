import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../config/environment_config.dart';
import '../errors/error_handler.dart';
import '../errors/failures.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  late final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref) {
    final config = EnvironmentConfig.instance;

    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(milliseconds: config.connectionTimeout),
        receiveTimeout: Duration(milliseconds: config.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      AuthInterceptor(_ref),
      if (EnvironmentConfig.instance.enableLogging) LoggingInterceptor(),
    ]);
  }

  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  Future<Either<Failure, T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse(response, parser);
    });
  }

  /// POSTs and returns the raw response bytes (QR sticker and report PDFs).
  Future<Either<Failure, List<int>>> postBytes(
    String path, {
    dynamic data,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final response = await _dio.post<List<int>>(
        path,
        data: data,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const <int>[];
    });
  }

  T _parseResponse<T>(Response<dynamic> response, T Function(dynamic)? parser) {
    final businessError = ApiException.fromEnvelope(response.data);
    if (businessError != null) throw businessError;
    if (parser != null) {
      return parser(response.data);
    }
    return response.data as T;
  }
}
