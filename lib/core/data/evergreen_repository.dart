import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../config/environment_config.dart';
import '../errors/failures.dart';
import '../models/backend_models.dart';
import '../network/api_client.dart';
import '../../features/auth/domain/models/user_model.dart';

final evergreenRepositoryProvider = Provider<EvergreenRepository>((ref) {
  return EvergreenRepository(ref.watch(apiClientProvider));
});

/// Shared reads used by several modules. Each call throws [Failure]-carrying
/// exceptions via [unwrap], so FutureProviders surface errors as AsyncError.
class EvergreenRepository {
  final ApiClient api;

  EvergreenRepository(this.api);

  Future<List<Company>> getCompanies() async {
    final body = unwrap(await api.get<dynamic>('user/getAllCompanies'));
    return dataList(body).map(Company.fromJson).toList();
  }

  Future<List<Equipment>> getEquipments({int? companyId}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getAllEquipments',
        data: {if (companyId != null) 'company_link': companyId},
      ),
    );
    return dataList(body).map(Equipment.fromJson).toList();
  }

  /// `getAllTasks` is already scoped by the backend: technicians get their
  /// own tickets, client roles get their companies' tickets.
  Future<List<ServiceTask>> getTasks({TaskStatus? status}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getAllTasks',
        data: {if (status != null) 'status': status.key},
      ),
    );
    return dataList(body).map(ServiceTask.fromJson).toList();
  }

  /// Admin-only on the backend.
  Future<List<User>> getUsers(
      {String? accessLevel, String? designation}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getAllUser',
        data: {
          if (accessLevel != null) 'access_level': accessLevel,
          if (designation != null) 'designation': designation,
        },
      ),
    );
    return dataList(body).map(User.fromBackend).toList();
  }

  /// Uploads one file to `upload-file` and returns the stored URL/path.
  Future<String> uploadFile(String filePath,
      {required String folderName}) async {
    final form =
        FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final body = unwrap(
      await api.post<dynamic>(
        'user/upload-file',
        data: form,
        queryParameters: {'folderName': folderName},
      ),
    );
    final url = body is Map ? body['image_url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw const RepositoryException('Upload returned no file URL');
    }
    return url;
  }
}

/// Turns a stored image/file value (Cloudinary URL or `uploads/...` path)
/// into a loadable URL.
String mediaUrl(String? value) {
  if (value == null || value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final path = value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  return '${EnvironmentConfig.backendUrl}$path';
}

/// Returns the value or throws the failure as a [FailureException].
T unwrap<T>(Either<Failure, T> result) =>
    result.fold((failure) => throw FailureException(failure), (value) => value);

class FailureException implements Exception {
  final Failure failure;
  const FailureException(this.failure);
  @override
  String toString() => failure.displayMessage;
}

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
  @override
  String toString() => message;
}

final companiesProvider = FutureProvider.autoDispose<List<Company>>((ref) {
  return ref.watch(evergreenRepositoryProvider).getCompanies();
});

final tasksProvider = FutureProvider.autoDispose<List<ServiceTask>>((ref) {
  return ref.watch(evergreenRepositoryProvider).getTasks();
});

/// All equipment visible to the user, or one company's when [companyId] is set.
final equipmentsProvider =
    FutureProvider.autoDispose.family<List<Equipment>, int?>((ref, companyId) {
  return ref
      .watch(evergreenRepositoryProvider)
      .getEquipments(companyId: companyId);
});

final techniciansProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref
      .watch(evergreenRepositoryProvider)
      .getUsers(accessLevel: 'technician');
});
