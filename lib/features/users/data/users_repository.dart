import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/models/user_model.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

/// User account writes on `user/*`. Every method returns the backend
/// `message` on success so screens can show it verbatim.
class UsersRepository {
  final ApiClient _api;

  UsersRepository(this._api);

  /// `POST user/createUser`. Technicians are never linked to companies on the
  /// backend, so [companyIds] is dropped for technician roles.
  Future<Either<Failure, String>> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
    String location = '',
    List<int> companyIds = const [],
  }) async {
    final result = await _api.post<dynamic>(
      'user/createUser',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'location': location,
        'access_level': role.accessLevel,
        if (role.designation != null) 'designation': role.designation,
        if (!role.isTechnicianLevel && companyIds.isNotEmpty)
          'company_link': companyIds,
      },
    );
    return result.map((body) => _message(body, 'User created'));
  }

  /// `PUT user/updateUser/:id`. Self-updates may change name, email,
  /// location, bio, date of birth and avatar; the backend ignores role/company
  /// changes then.
  Future<Either<Failure, String>> updateUser(
    int id, {
    String? name,
    String? email,
    String? location,
    String? bio,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    final result = await _api.put<dynamic>(
      'user/updateUser/$id',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (bio != null) 'bio': bio,
        if (dateOfBirth != null)
          'date_of_birth': DateTime.utc(
            dateOfBirth.year,
            dateOfBirth.month,
            dateOfBirth.day,
          ).toIso8601String(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return result.map((body) => _message(body, 'Profile updated'));
  }

  /// `POST user/setUserActive {user_link, is_active}`.
  Future<Either<Failure, String>> setUserActive(
    int id, {
    required bool isActive,
  }) async {
    final result = await _api.post<dynamic>(
      'user/setUserActive',
      data: {'user_link': id, 'is_active': isActive},
    );
    return result.map(
      (body) =>
          _message(body, isActive ? 'User activated' : 'User deactivated'),
    );
  }

  /// `POST user/deleteUser {user_link}`.
  Future<Either<Failure, String>> deleteUser(int id) async {
    final result =
        await _api.post<dynamic>('user/deleteUser', data: {'user_link': id});
    return result.map((body) => _message(body, 'User deleted'));
  }

  /// `POST user/changePassword {current_password, new_password}` for the
  /// signed-in user. New password must be 6-20 characters.
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _api.post<dynamic>(
      'user/changePassword',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    return result.map((body) => _message(body, 'Password updated'));
  }

  /// `POST user/forgetPassword {phone}`. The backend emails the account's
  /// existing password to its registered email address.
  Future<Either<Failure, String>> forgotPassword(String phone) async {
    final result =
        await _api.post<dynamic>('user/forgetPassword', data: {'phone': phone});
    return result.map(
        (body) => _message(body, 'Password sent to your registered email'));
  }

  String _message(dynamic body, String fallback) {
    final message = body is Map ? body['message']?.toString().trim() : null;
    return (message == null || message.isEmpty) ? fallback : message;
  }
}
