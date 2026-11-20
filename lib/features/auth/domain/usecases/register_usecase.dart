import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call({
    required String email,
    required String password,
    required String name,
  }) {
    return _repository.register(
      email: email,
      password: password,
      name: name,
    );
  }
}
