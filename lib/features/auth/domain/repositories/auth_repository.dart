import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, AuthTokens>> refreshToken(String refreshToken);

  Future<bool> isAuthenticated();
}
