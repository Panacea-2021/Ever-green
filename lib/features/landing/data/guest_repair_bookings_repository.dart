import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/network/api_client.dart';

class GuestRepairEquipment {
  const GuestRepairEquipment({required this.id, required this.name});

  final int id;
  final String name;

  factory GuestRepairEquipment.fromJson(dynamic value) {
    if (value is! Map) {
      throw const RepositoryException('Invalid equipment response');
    }

    final rawId = value['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    final rawName = value['name'];
    if (id == null || rawName is! String || rawName.trim().isEmpty) {
      throw const RepositoryException('Invalid equipment response');
    }
    return GuestRepairEquipment(id: id, name: rawName);
  }
}

class GuestRepairBookingResponse {
  const GuestRepairBookingResponse({
    required this.reference,
    required this.status,
    required this.createdAt,
  });

  final String reference;
  final String status;
  final DateTime createdAt;

  factory GuestRepairBookingResponse.fromJson(dynamic value) {
    if (value is! Map) {
      throw const RepositoryException('Invalid booking response');
    }

    final reference = value['reference'];
    final status = value['status'];
    final createdAtValue = value['created_at'];
    final createdAt =
        createdAtValue is String ? DateTime.tryParse(createdAtValue) : null;
    if (reference is! String ||
        reference.isEmpty ||
        status is! String ||
        status.isEmpty ||
        createdAt == null) {
      throw const RepositoryException('Invalid booking response');
    }
    return GuestRepairBookingResponse(
      reference: reference,
      status: status,
      createdAt: createdAt,
    );
  }
}

abstract interface class GuestRepairBookingsRepository {
  Future<List<GuestRepairEquipment>> getEquipment();

  Future<List<String>> getServices();

  Future<GuestRepairBookingResponse> submitBooking({
    required String name,
    required String phone,
    required String email,
    required int equipmentId,
    required String service,
    required String idempotencyKey,
  });
}

class ApiGuestRepairBookingsRepository
    implements GuestRepairBookingsRepository {
  ApiGuestRepairBookingsRepository(this.api);

  static const _baseUrl = 'http://127.0.0.1:3001';
  static const _equipmentPath = '$_baseUrl/guest-repair-bookings/equipment';
  static const _servicesPath = '$_baseUrl/guest-repair-bookings/services';
  static const _createPath = '$_baseUrl/guest-repair-bookings';

  final ApiClient api;

  @override
  Future<List<GuestRepairEquipment>> getEquipment() async {
    final envelope = unwrap(await api.get<dynamic>(_equipmentPath));
    final data = _responseData(envelope);
    if (data is! List) {
      throw const RepositoryException('Invalid equipment response');
    }
    return data.map(GuestRepairEquipment.fromJson).toList(growable: false);
  }

  @override
  Future<List<String>> getServices() async {
    final envelope = unwrap(await api.get<dynamic>(_servicesPath));
    final data = _responseData(envelope);
    if (data is! List || data.any((value) => value is! String)) {
      throw const RepositoryException('Invalid services response');
    }
    return data.cast<String>().toList(growable: false);
  }

  @override
  Future<GuestRepairBookingResponse> submitBooking({
    required String name,
    required String phone,
    required String email,
    required int equipmentId,
    required String service,
    required String idempotencyKey,
  }) async {
    final envelope = unwrap(
      await api.post<dynamic>(
        _createPath,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          if (email.trim().isNotEmpty) 'email': email.trim(),
          'equipmentId': equipmentId,
          'service': service,
        },
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      ),
    );
    return GuestRepairBookingResponse.fromJson(_responseData(envelope));
  }

  dynamic _responseData(dynamic envelope) {
    if (envelope is! Map || !envelope.containsKey('data')) {
      throw const RepositoryException('Invalid guest repair booking response');
    }
    return envelope['data'];
  }
}

final guestRepairBookingsRepositoryProvider =
    Provider<GuestRepairBookingsRepository>((ref) {
  return ApiGuestRepairBookingsRepository(ref.watch(apiClientProvider));
});
