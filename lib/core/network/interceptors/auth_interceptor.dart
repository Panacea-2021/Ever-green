import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/environment_config.dart';
import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  static const _apiKeyRoutes = {'auth/signIn', 'user/forgetPassword'};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path.replaceFirst(RegExp(r'^/+'), '');
    if (_apiKeyRoutes.contains(path)) {
      options.headers['api-key'] = EnvironmentConfig.apiKey;
    } else {
      final accessToken = await _ref.read(tokenStorageProvider).getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _ref.read(tokenStorageProvider).expireSession();
    }
    handler.next(err);
  }
}
