import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

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
  /// [deleted] lists only soft-deleted tickets (admins / managers).
  Future<List<ServiceTask>> getTasks({
    TaskStatus? status,
    bool deleted = false,
  }) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getAllTasks',
        data: {
          if (status != null) 'status': status.key,
          if (deleted) 'deleted': true,
        },
      ),
    );
    return dataList(body).map(ServiceTask.fromJson).toList();
  }

  /// The equipment's ticket that is not closed or deleted, or null.
  Future<ActiveEquipmentTask?> getActiveTaskForEquipment(
      int equipmentId) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getActiveTaskForEquipment',
        data: {'equipment_link': equipmentId},
      ),
    );
    final data = body is Map ? body['data'] : null;
    return data is Map<String, dynamic>
        ? ActiveEquipmentTask.fromJson(data)
        : null;
  }

  /// Active issue types, or every one when [includeInactive] (admins).
  Future<List<IssueType>> getIssueTypes({bool includeInactive = false}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getIssueTypes',
        data: {if (includeInactive) 'include_inactive': true},
      ),
    );
    return dataList(body).map(IssueType.fromJson).toList();
  }

  Future<void> createIssueType(String name) async {
    unwrap(
        await api.post<dynamic>('user/createIssueType', data: {'name': name}));
  }

  Future<void> updateIssueType(int id, {String? name, bool? isActive}) async {
    unwrap(
      await api.post<dynamic>(
        'user/updateIssueType',
        data: {
          'issue_type_link': id,
          if (name != null) 'name': name,
          if (isActive != null) 'is_active': isActive,
        },
      ),
    );
  }

  /// Active service types, or every one when [includeInactive] (admins).
  Future<List<ServiceType>> getServiceTypes({
    bool includeInactive = false,
  }) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getServiceTypes',
        data: {if (includeInactive) 'include_inactive': true},
      ),
    );
    return dataList(body).map(ServiceType.fromJson).toList();
  }

  Future<void> createServiceType(String name) async {
    unwrap(
      await api.post<dynamic>('user/createServiceType', data: {'name': name}),
    );
  }

  Future<void> updateServiceType(int id, {String? name, bool? isActive}) async {
    unwrap(
      await api.post<dynamic>(
        'user/updateServiceType',
        data: {
          'service_type_link': id,
          if (name != null) 'name': name,
          if (isActive != null) 'is_active': isActive,
        },
      ),
    );
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
  Future<String> uploadFile(XFile file, {required String folderName}) async {
    final multipartFile = kIsWeb
        ? MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name.isEmpty ? 'upload' : file.name,
            contentType: file.mimeType == null
                ? null
                : DioMediaType.parse(file.mimeType!),
          )
        : await MultipartFile.fromFile(
            file.path,
            filename: file.name.isEmpty ? null : file.name,
          );
    final form = FormData.fromMap({'file': multipartFile});
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

/// How long reference lists stay cached after the last screen using them
/// closes. Saves invalidate these providers, so edits still show at once.
const listCacheDuration = Duration(seconds: 60);

/// Keeps an auto-dispose provider's value for [duration] after its last
/// listener leaves, so moving between screens does not refetch it.
void cacheFor(Ref ref, Duration duration) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() => timer = Timer(duration, link.close));
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}

final companiesProvider = FutureProvider.autoDispose<List<Company>>((ref) {
  cacheFor(ref, listCacheDuration);
  return ref.watch(evergreenRepositoryProvider).getCompanies();
});

final tasksProvider = FutureProvider.autoDispose<List<ServiceTask>>((ref) {
  return ref.watch(evergreenRepositoryProvider).getTasks();
});

/// Soft-deleted tickets (admins / managers only).
final deletedTasksProvider =
    FutureProvider.autoDispose<List<ServiceTask>>((ref) {
  return ref.watch(evergreenRepositoryProvider).getTasks(deleted: true);
});

/// Issue types offered when raising a task.
final issueTypesProvider = FutureProvider.autoDispose<List<IssueType>>((ref) {
  cacheFor(ref, listCacheDuration);
  return ref.watch(evergreenRepositoryProvider).getIssueTypes();
});

/// Every issue type, including deactivated ones (admins / managers).
final allIssueTypesProvider =
    FutureProvider.autoDispose<List<IssueType>>((ref) {
  return ref
      .watch(evergreenRepositoryProvider)
      .getIssueTypes(includeInactive: true);
});

/// Service types offered when adding or editing equipment.
final serviceTypesProvider =
    FutureProvider.autoDispose<List<ServiceType>>((ref) {
  cacheFor(ref, listCacheDuration);
  return ref.watch(evergreenRepositoryProvider).getServiceTypes();
});

/// Every service type, including deactivated ones (admins / managers).
final allServiceTypesProvider =
    FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ref
      .watch(evergreenRepositoryProvider)
      .getServiceTypes(includeInactive: true);
});

/// The equipment's active ticket (not closed or deleted), or null.
final activeTaskForEquipmentProvider = FutureProvider.autoDispose
    .family<ActiveEquipmentTask?, int>((ref, equipmentId) {
  return ref
      .watch(evergreenRepositoryProvider)
      .getActiveTaskForEquipment(equipmentId);
});

/// All equipment visible to the user, or one company's when [companyId] is set.
final equipmentsProvider =
    FutureProvider.autoDispose.family<List<Equipment>, int?>((ref, companyId) {
  cacheFor(ref, listCacheDuration);
  return ref
      .watch(evergreenRepositoryProvider)
      .getEquipments(companyId: companyId);
});

final techniciansProvider = FutureProvider.autoDispose<List<User>>((ref) {
  cacheFor(ref, listCacheDuration);
  return ref
      .watch(evergreenRepositoryProvider)
      .getUsers(accessLevel: 'technician');
});
