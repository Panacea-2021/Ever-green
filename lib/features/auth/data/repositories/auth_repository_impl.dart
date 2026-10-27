import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  /// `email` carries the mobile number; the backend signs in by phone.
  @override
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final phone = email.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final deviceId = await _tokenStorage.getDeviceId();
    final fcmId = await PushService.currentToken();

    final result = await _apiClient.post<Map<String, dynamic>>(
      'auth/signIn',
      data: {
        'phone': phone,
        'password': password,
        if (fcmId != null) 'fcm_id': fcmId,
        'device_id': deviceId,
      },
    );

    return result.fold(Left.new, (body) async {
      try {
        final token = body['access_token']?.toString();
        final data = body['data'];
        if (token == null || token.isEmpty || data is! Map<String, dynamic>) {
          return const Left(
            AuthenticationFailure(message: 'Unexpected sign-in response'),
          );
        }
        final user = User.fromBackend(data);
        await _tokenStorage.saveAccessToken(token);
        await _tokenStorage.saveSessionUser(user.toJson());
        return Right(
          AuthResponse(
            user: user,
            tokens: AuthTokens(accessToken: token, refreshToken: ''),
          ),
        );
      } catch (e, st) {
        return Left(ErrorHandler.handleException(e, st));
      }
    });
  }

  @override
  Future<Either<Failure, AuthResponse>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return const Left(
      AuthenticationFailure(
        message: 'Accounts are created by EverGreen. Contact your administrator.',
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    await _tokenStorage.clearAll();
    return const Right(unit);
  }

  /// Refreshes the user from `auth/me`; falls back to the cached session user
  /// when the backend is unreachable so the app still opens offline.
  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final result = await _apiClient.get<Map<String, dynamic>>('auth/me');
    return result.fold(
      (failure) async {
        if (failure is AuthenticationFailure) return Left(failure);
        final cached = await _tokenStorage.getSessionUser();
        if (cached != null) return Right(User.fromJson(cached));
        return Left(failure);
      },
      (body) async {
        try {
          final data = body['data'];
          if (data is! Map<String, dynamic>) {
            throw const FormatException('auth/me returned no user');
          }
          final user = User.fromBackend(data);
          await _tokenStorage.saveSessionUser(user.toJson());
          return Right(user);
        } catch (e, st) {
          final cached = await _tokenStorage.getSessionUser();
          if (cached != null) return Right(User.fromJson(cached));
          return Left(ErrorHandler.handleException(e, st));
        }
      },
    );
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshToken(String refreshToken) async {
    return const Left(
      AuthenticationFailure(message: 'Session expired. Please sign in again.'),
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    return _tokenStorage.hasValidTokens();
  }
}
