import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../auth/domain/models/user_model.dart';
import '../domain/models/equipment_item.dart';

/// Equipment row plus its service history (`getEquipmentInfo`).
class EquipmentInfo {
  final Equipment equipment;
  final List<ServiceTask> history;

  const EquipmentInfo({required this.equipment, this.history = const []});
}

/// Outcome of an Excel bulk upload (`uploadEquipmentData`,
/// `uploadTechnicianData`).
class UploadResult {
  final String message;
  final int added;
  final int skipped;
  final List<String> errors;

  const UploadResult({
    required this.message,
    this.added = 0,
    this.skipped = 0,
    this.errors = const [],
  });
}

final equipmentApiProvider = Provider<EquipmentApi>((ref) {
  return EquipmentApi(ref.watch(apiClientProvider));
});

/// Equipment writes, lookups, QR sticker PDFs and bulk uploads.
class EquipmentApi {
  final ApiClient api;

  EquipmentApi(this.api);

  /// `fields` uses backend keys (name, make, model, serial_number, ...).
  Future<Equipment> create(Map<String, dynamic> fields) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/createEquipment',
        data: fields,
      ),
    );
    final data = body is Map ? body['data'] : null;
    return Equipment.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<void> update(int equipmentId, Map<String, dynamic> fields) async {
    unwrap(
      await api.post<dynamic>(
        'user/updateEquipment',
        data: {...fields, 'equipment_link': equipmentId},
      ),
    );
  }

  /// Soft activate/deactivate (`deleteEquipment` never hard-deletes).
  Future<void> setActive(int equipmentId, bool active) async {
    unwrap(
      await api.post<dynamic>(
        'user/deleteEquipment',
        data: {
          'equipment_link': equipmentId,
          'action': active ? 'activate' : 'deactivate',
        },
      ),
    );
  }

  /// [link] may be the equipment id, EG serial number or serial number.
  /// Client-side [user]s only get equipment of their own companies; anything
  /// else throws [ForeignEquipmentException].
  Future<EquipmentInfo> getInfo(String link, {User? user}) async {
    final trimmed = link.trim();
    final Object? body;
    try {
      body = unwrap(
        await api.post<dynamic>(
          'user/getEquipmentInfo',
          data: {'equipment_link': int.tryParse(trimmed) ?? trimmed},
        ),
      );
    } on FailureException catch (e) {
      if (user != null && isForeignEquipmentFailure(e.failure, user.role)) {
        throw const ForeignEquipmentException();
      }
      rethrow;
    }
    final data = body is Map ? body['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const RepositoryException('Equipment not found');
    }
    final equipment = Equipment.fromJson(data);
    if (user != null && !userCanViewEquipment(user, equipment)) {
      throw const ForeignEquipmentException();
    }
    return EquipmentInfo(
      equipment: equipment,
      history: dataList(data, 'tasks').map(ServiceTask.fromJson).toList(),
    );
  }

  /// Marks the equipment as verified by the caller (after a QR scan).
  Future<void> verify(int equipmentId) async {
    unwrap(
      await api.post<dynamic>(
        'user/verifyEquipment',
        data: {'equipment_link': equipmentId},
      ),
    );
  }

  /// Verified equipment (with `company` and `verifier`), newest first.
  Future<List<Equipment>> getVerified() async {
    final body = unwrap(
      await api.post<dynamic>('user/getVerifiedEquipments', data: const {}),
    );
    return dataList(body).map(Equipment.fromJson).toList();
  }

  /// QR sticker PDF for a whole company or specific equipment ids. Only the
  /// selected key is sent.
  Future<Uint8List> qrStickerPdf(
      {int? companyId, List<int>? equipmentIds}) async {
    final result = await api.postBytes(
      'user/qrCodeGenerator',
      data: {
        if (companyId != null) 'company_link': companyId,
        if (equipmentIds != null && equipmentIds.isNotEmpty)
          'equipment_link': equipmentIds,
      },
    );
    return _pdfOrThrow(unwrap(result), 'Could not generate the QR PDF');
  }

  /// Service report PDF of one ticket (`getServiceReport`, admin only).
  Future<Uint8List> serviceReportPdf(int taskId) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getServiceReport',
        data: {'task_link': taskId},
      ),
    );
    final encoded = body is Map ? body['pdf_base64']?.toString() : null;
    if (encoded == null || encoded.isEmpty) {
      throw const RepositoryException(
        'The service report could not be generated',
      );
    }
    return base64Decode(encoded);
  }

  Uint8List _pdfOrThrow(List<int> raw, String fallback) {
    final bytes = Uint8List.fromList(raw);
    final header = bytes.length >= 4
        ? ascii.decode(bytes.sublist(0, 4), allowInvalid: true)
        : '';
    if (header == '%PDF') {
      return bytes;
    }
    String? message;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map) message = decoded['message']?.toString();
    } catch (_) {}
    throw RepositoryException(message ?? fallback);
  }

  Future<UploadResult> uploadEquipmentExcel(String filePath,
      {required int companyId}) {
    return _uploadExcel(
        'user/uploadEquipmentData', filePath, {'company_link': companyId});
  }

  Future<UploadResult> uploadTechnicianExcel(String filePath) {
    return _uploadExcel('user/uploadTechnicianData', filePath, const {});
  }

  Future<UploadResult> _uploadExcel(
    String path,
    String filePath,
    Map<String, dynamic> fields,
  ) async {
    final form = FormData.fromMap({
      ...fields,
      'file': await MultipartFile.fromFile(filePath),
    });
    final body = unwrap(await api.post<dynamic>(path, data: form));
    final map = body is Map ? body : const {};
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return UploadResult(
      message: map['message']?.toString() ?? 'Upload complete',
      added: asInt(map['added']),
      skipped: asInt(map['skipped']),
      errors: (map['errors'] as List? ?? const []).map((e) => '$e').toList(),
    );
  }
}

/// Equipment + service history by id or serial number, scoped to the
/// signed-in user's companies for client-side roles.
final equipmentInfoProvider =
    FutureProvider.autoDispose.family<EquipmentInfo, String>((ref, link) {
  return ref
      .watch(equipmentApiProvider)
      .getInfo(link, user: ref.watch(currentUserProvider));
});

const foreignEquipmentMessage =
    'This equipment does not belong to your company';

/// A client-side user looked up equipment of another company.
class ForeignEquipmentException implements Exception {
  const ForeignEquipmentException();

  @override
  String toString() => foreignEquipmentMessage;
}

/// Client / Client Admin may only see equipment of a company they are linked
/// to. Every other role sees everything.
bool userCanViewEquipment(User user, Equipment equipment) {
  if (!user.role.isClientSide) return true;
  final companyId = equipment.companyId ?? equipment.company?.id;
  return companyId != null && user.companies.any((c) => c.id == companyId);
}

/// Whether a failed equipment lookup is the backend's "not your company"
/// rejection (a 403 envelope, or a bare HTTP 403) for a client-side [role].
bool isForeignEquipmentFailure(Failure failure, UserRole role) {
  if (!role.isClientSide) return false;
  if (failure.message.toLowerCase().contains('does not belong')) return true;
  if (failure is ServerFailure) return failure.statusCode == 403;
  return failure is AuthenticationFailure && failure.message == 'Access denied';
}

/// Every equipment row the current user can see (admins: all; others: their
/// companies').
final allEquipmentsProvider =
    FutureProvider.autoDispose<List<Equipment>>((ref) {
  return ref.watch(equipmentsProvider(null).future);
});

/// Equipment verified by QR scan (`getVerifiedEquipments`).
final verifiedEquipmentsProvider =
    FutureProvider.autoDispose<List<Equipment>>((ref) {
  return ref.watch(equipmentApiProvider).getVerified();
});

/// Equipment as list items (empty while loading or on error).
final equipmentProvider = Provider<List<EquipmentItem>>((ref) {
  final equipment = ref.watch(allEquipmentsProvider).valueOrNull ?? const [];
  return equipment.map(EquipmentItem.fromEquipment).toList();
});

/// Total equipment count, for KPI tiles.
final equipmentCountProvider = Provider<int>((ref) {
  return ref.watch(equipmentProvider).length;
});

/// Equipment grouped by status, for breakdowns.
final equipmentByStatusProvider = Provider<Map<EquipmentStatus, int>>((ref) {
  final items = ref.watch(equipmentProvider);
  final counts = <EquipmentStatus, int>{
    for (final s in EquipmentStatus.values) s: 0,
  };
  for (final e in items) {
    counts[e.status] = (counts[e.status] ?? 0) + 1;
  }
  return counts;
});

/// Admin roles (EG super admin / admin) may add, edit and (de)activate.
bool canManageEquipment(UserRole role) =>
    role == UserRole.superAdmin || role == UserRole.manager;

/// Pulls the equipment id/serial out of a scanned QR value. Backend stickers
/// encode the bare equipment id; URLs and JSON payloads are tolerated.
String? parseEquipmentCode(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        for (final key in const [
          'equipment_link',
          'equipmentId',
          'equipment_id',
          'id',
          'eg_serial_number',
          'serial_number',
        ]) {
          final v = decoded[key]?.toString().trim();
          if (v != null && v.isNotEmpty) return v;
        }
      }
    } catch (_) {}
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    for (final key in const [
      'equipment_link',
      'equipmentId',
      'equipment_id',
      'id'
    ]) {
      final v = uri.queryParameters[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.last;
  }
  return value;
}
