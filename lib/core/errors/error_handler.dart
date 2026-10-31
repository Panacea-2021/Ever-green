import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../network/api_exception.dart';
import 'failures.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Failure handleException(Object error, [StackTrace? stackTrace]) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return Failure.authentication(message: error.message);
      }
      return Failure.server(
          message: error.message, statusCode: error.statusCode);
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is SocketException) {
      return const Failure.noConnection();
    }

    if (error is FormatException) {
      return Failure.parsing(
        message: 'Invalid data format: ${error.message}',
      );
    }

    return Failure.unknown(
      message: error.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.timeout();

      case DioExceptionType.connectionError:
        return const Failure.noConnection();

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return const Failure.network(message: 'Request was cancelled');

      case DioExceptionType.badCertificate:
        return const Failure.network(message: 'Invalid certificate');

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return const Failure.noConnection();
        }
        return Failure.network(
          message: error.message ?? 'Network error occurred',
        );
    }
  }

  static Failure _handleBadResponse(Response? response) {
    if (response == null) {
      return const Failure.network(message: 'No response from server');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    String message = 'Server error';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          'Server error';
      final rawErrors = data['errors'];
      errors = rawErrors is Map<String, dynamic> ? rawErrors : null;
    }

    switch (statusCode) {
      case 400:
        if (errors != null) {
          return Failure.validation(
            message: message,
            fieldErrors: errors.map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              ),
            ),
          );
        }
        return Failure.server(message: message, statusCode: statusCode);

      case 401:
        return Failure.authentication(message: message);

      case 403:
        return Failure.authentication(message: 'Access denied');

      case 404:
        return Failure.server(
          message: 'Resource not found',
          statusCode: statusCode,
        );

      case 422:
        return Failure.validation(
          message: message,
          fieldErrors: errors?.map(
                (key, value) => MapEntry(
                  key,
                  (value as List).map((e) => e.toString()).toList(),
                ),
              ) ??
              {},
        );

      case 500:
      case 502:
      case 503:
        return Failure.server(
          message: 'Server is temporarily unavailable',
          statusCode: statusCode,
        );

      default:
        return Failure.server(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );
    }
  }

  static Either<Failure, T> guard<T>(T Function() operation) {
    try {
      return Right(operation());
    } catch (e, st) {
      return Left(handleException(e, st));
    }
  }

  static Future<Either<Failure, T>> guardAsync<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return Right(await operation());
    } catch (e, st) {
      return Left(handleException(e, st));
    }
  }
}
