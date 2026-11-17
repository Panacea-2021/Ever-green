import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment_config.dart';

/// Guest (unauthenticated) repair booking endpoints.
///
/// These use the same deployed backend as the authenticated APIs. The base URL
/// comes from [EnvironmentConfig] (no hardcoded host).
class GuestRepairBookingsRepository {
  final Dio _dio;

  GuestRepairBookingsRepository()
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

  Future<List<String>> fetchServices() async {
    final res = await _dio.get<dynamic>('/guest-repair-bookings/services');
    final data = res.data;
    final list = data is Map ? data['data'] : data;
    if (list is List) {
      return list.map((e) => '$e').toList();
    }
    return const [];
  }

  Future<String?> submit({
    required String name,
    required String phone,
    String? email,
    required String equipmentId,
    required String service,
    required String idempotencyKey,
  }) async {
    final res = await _dio.post<dynamic>(
      '/guest-repair-bookings',
      data: {
        'name': name,
        'phone': phone,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'equipmentId': equipmentId,
        'service': service,
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    final data = res.data;
    if (data is Map) {
      final d = data['data'];
      if (d is Map) return d['reference']?.toString();
      return data['reference']?.toString();
    }
    return null;
  }
}

final guestRepairBookingsRepositoryProvider = Provider<GuestRepairBookingsRepository>((ref) {
  return GuestRepairBookingsRepository();
});
