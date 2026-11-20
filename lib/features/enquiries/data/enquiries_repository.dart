import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/network/api_client.dart';
import '../domain/enquiry.dart';

/// Admin enquiry endpoints (guest repair bookings + free estimates).
///
/// Uses the existing authenticated ApiClient (Bearer token).
class EnquiriesRepository {
  final ApiClient api;

  EnquiriesRepository(this.api);

  // Guest Repair Bookings
  Future<List<Enquiry>> fetchGuestRepairBookings({
    int page = 1,
    int limit = 20,
  }) async {
    final body = unwrap(
      await api.get<dynamic>(
        'guest-repair-bookings',
        queryParameters: {'page': page, 'limit': limit},
      ),
    );
    dynamic data = body;
    if (data is Map) {
      data = data['data'] ?? data['items'] ?? data['results'] ?? data;
      if (data is Map) data = data['data'] ?? data['items'] ?? data['results'] ?? data;
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((json) {
        final e = Enquiry.fromJson(json);
        return Enquiry(
          tokenId: e.tokenId,
          customerName: e.customerName,
          phone: e.phone,
          email: e.email,
          equipment: e.equipment,
          service: e.service,
          requestType: (e.requestType == null || e.requestType!.trim().isEmpty)
              ? 'Book a Repair'
              : e.requestType,
          problemDescription: e.problemDescription,
          photos: e.photos,
          submissionDate: e.submissionDate,
          status: e.status,
        );
      }).toList();
    }
    return const [];
  }

  Future<Enquiry> fetchGuestRepairBooking(String id) async {
    final body = unwrap(await api.get<dynamic>('guest-repair-bookings/$id'));
    final data = body is Map ? (body['data'] ?? body) : body;
    if (data is Map<String, dynamic>) return Enquiry.fromJson(data);
    throw const RepositoryException('Enquiry not found');
  }

  Future<void> updateGuestRepairBookingStatus(String id, EnquiryStatus status) async {
    unwrap(await api.patch<dynamic>('guest-repair-bookings/$id/status', data: {'status': status.key}));
  }

  Future<void> updateGuestRepairBooking(String id, Map<String, dynamic> data) async {
    unwrap(await api.patch<dynamic>('guest-repair-bookings/$id', data: data));
  }

  Future<void> deleteGuestRepairBooking(String id) async {
    unwrap(await api.delete<dynamic>('guest-repair-bookings/$id'));
  }

  // Free Estimates
  Future<List<Enquiry>> fetchFreeEstimates() async {
    final body = unwrap(await api.get<dynamic>('free-estimates'));
    dynamic data = body;
    if (data is Map) {
      data = data['data'] ?? data['items'] ?? data['results'] ?? data;
      if (data is Map) data = data['data'] ?? data['items'] ?? data['results'] ?? data;
    }
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((json) {
        final e = Enquiry.fromJson(json);
        return Enquiry(
          tokenId: e.tokenId,
          customerName: e.customerName,
          phone: e.phone,
          email: e.email,
          equipment: e.equipment,
          service: e.service,
          requestType: e.requestType ?? 'Get Estimate',
          problemDescription: e.problemDescription,
          photos: e.photos,
          submissionDate: e.submissionDate,
          status: e.status,
        );
      }).toList();
    }
    return const [];
  }

  Future<Enquiry> fetchFreeEstimate(String id) async {
    final body = unwrap(await api.get<dynamic>('free-estimates/$id'));
    final data = body is Map ? (body['data'] ?? body) : body;
    if (data is Map<String, dynamic>) {
      final e = Enquiry.fromJson(data);
      return Enquiry(
        tokenId: e.tokenId,
        customerName: e.customerName,
        phone: e.phone,
        email: e.email,
        equipment: e.equipment,
        service: e.service,
        requestType: e.requestType ?? 'Get Estimate',
        problemDescription: e.problemDescription,
        photos: e.photos,
        submissionDate: e.submissionDate,
        status: e.status,
      );
    }
    throw const RepositoryException('Enquiry not found');
  }

  Future<void> updateFreeEstimate(String id, Map<String, dynamic> data) async {
    unwrap(await api.patch<dynamic>('free-estimates/$id', data: data));
  }

  Future<void> deleteFreeEstimate(String id) async {
    unwrap(await api.delete<dynamic>('free-estimates/$id'));
  }
}

final enquiriesRepositoryProvider = Provider<EnquiriesRepository>((ref) {
  return EnquiriesRepository(ref.watch(evergreenRepositoryProvider).api);
});
