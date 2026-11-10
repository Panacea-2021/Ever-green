import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/environment_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// Use case providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

// Auth controller
class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final authNotifier = _ref.read(authStateProvider.notifier);
    authNotifier.setLoading(true);

    final loginUseCase = _ref.read(loginUseCaseProvider);
    final result = await loginUseCase(email: email, password: password);

    result.fold(
      (failure) => authNotifier.setUnauthenticated(failure.displayMessage),
      (response) => authNotifier.setAuthenticated(response.user),
    );
  }

  /// `POST auth/register` (api-key, no JWT). The account is created inactive
  /// until an administrator activates it, so this never signs the user in;
  /// on success it returns the backend message to show verbatim.
  Future<Either<Failure, String>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? location,
  }) async {
    final result = await _ref.read(apiClientProvider).post<dynamic>(
          'auth/register',
          data: {
            'name': name,
            'phone': phone,
            'email': email,
            'password': password,
            if (location != null && location.isNotEmpty) 'location': location,
          },
          options: Options(headers: {'api-key': EnvironmentConfig.apiKey}),
        );
    return result.map((body) {
      final message = body is Map ? body['message']?.toString().trim() : null;
      return (message == null || message.isEmpty)
          ? 'Registration received. An administrator will activate your account.'
          : message;
    });
  }

  /// Clears the local session immediately and notifies the backend in the
  /// background so a slow server cannot keep the user signed in locally.
  Future<void> logout() async {
    final authNotifier = _ref.read(authStateProvider.notifier);
    final logoutUseCase = _ref.read(logoutUseCaseProvider);

    unawaited(_notifyBackendLogout());
    await logoutUseCase();
    authNotifier.logout();
  }

  Future<void> _notifyBackendLogout() async {
    try {
      final result = await _ref
          .read(apiClientProvider)
          .post<dynamic>('auth/logout')
          .timeout(const Duration(seconds: 5));
      result.fold(
        (failure) => debugPrint(
          'AuthController: backend logout failed (${failure.displayMessage})',
        ),
        (_) {},
      );
    } catch (error) {
      debugPrint('AuthController: backend logout request failed ($error)');
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
