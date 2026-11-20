import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
