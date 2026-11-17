import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment_config.dart';

/// Guest (unauthenticated) Free Estimate endpoints.
///
/// POST /free-estimates is public (no JWT), like the guest repair booking
/// endpoints. Equipment and service options are loaded from the same public
/// dropdown endpoints used by "Book a Repair".
class FreeEstimatesRepository {
  final Dio _dio;

  FreeEstimatesRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: EnvironmentConfig.backendUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  Future<List<Map<String, dynamic>>> fetchEquipment() async {
    final res = await _dio.get<dynamic>('/guest-repair-bookings/equipment');
    final data = res.data;
    final list = data is Map ? data['data'] : data;
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<List<dynamic>> fetchServices() async {
    final res = await _dio.get<dynamic>('/guest-repair-bookings/services');
    final data = res.data;
    final list = data is Map ? data['data'] : data;
    if (list is List) return list;
    return const [];
  }

  /// Submits a free estimate. Returns the reference/token if provided.
  ///
  /// Sends JSON when [photos] is empty, otherwise multipart/form-data with
  /// repeated field name `photos` (max 5).
  Future<String?> submit({
    required int equipmentId,
    required dynamic serviceId,
    required String problemDescription,
    required String customerName,
    required String phoneNumber,
    List<PlatformFile> photos = const [],
  }) async {
    final limited = photos.take(5).toList();
    if (limited.isEmpty) {
      final res = await _dio.post<dynamic>(
        '/free-estimates',
        data: {
          'equipment_id': equipmentId,
          'service_id': serviceId,
          'problem_description': problemDescription,
          'customer_name': customerName,
          'phone_number': phoneNumber,
        },
      );
      return _extractReference(res.data);
    }

    final form = FormData();
    form.fields.add(MapEntry('equipment_id', '$equipmentId'));
    form.fields.add(MapEntry('service_id', '$serviceId'));
    form.fields.add(MapEntry('problem_description', problemDescription));
    form.fields.add(MapEntry('customer_name', customerName));
    form.fields.add(MapEntry('phone_number', phoneNumber));
    for (final photo in limited) {
      if (photo.bytes != null) {
        form.files.add(MapEntry(
          'photos',
          MultipartFile.fromBytes(
            photo.bytes!,
            filename: photo.name.isEmpty ? 'photo.jpg' : photo.name,
          ),
        ));
      } else if (photo.path != null && photo.path!.isNotEmpty) {
        form.files.add(MapEntry('photos', await MultipartFile.fromFile(photo.path!, filename: photo.name)));
      }
    }
    final res = await _dio.post<dynamic>('/free-estimates', data: form);
    return _extractReference(res.data);
  }

  String? _extractReference(dynamic data) {
    if (data is Map) {
      final d = data['data'];
      if (d is Map) return d['reference']?.toString() ?? d['id']?.toString() ?? d['token_id']?.toString();
      return data['reference']?.toString() ?? data['id']?.toString() ?? data['token_id']?.toString();
    }
    return null;
  }
}

final freeEstimatesRepositoryProvider = Provider<FreeEstimatesRepository>((ref) {
  return FreeEstimatesRepository();
});
