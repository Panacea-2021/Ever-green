import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/network/api_client.dart';
import '../domain/enquiry.dart';

/// Repository for customer repair enquiries (Book a Repair popup).
///
/// Backend integration is pending: the endpoints below are the agreed contract.
/// Until the backend ships them, [fetchEnquiries] throws a [RepositoryException]
/// so the UI can show an integration-pending state instead of fake data.
class EnquiriesRepository {
  final ApiClient api;

  EnquiriesRepository(this.api);

  /// Configurable endpoint paths (update when backend provides the contract).
  static const String listPath = 'enquiries/getAll';
  static const String detailPath = 'enquiries/getOne';
  static const String updateStatusPath = 'enquiries/updateStatus';

  Future<List<Enquiry>> fetchEnquiries({
    String? search,
    EnquiryStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final body = unwrap(
      await api.get<dynamic>(
        listPath,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null) 'status': status.key,
          'page': page,
          'pageSize': pageSize,
        },
      ),
    );
    final data = body is Map ? body['data'] : body;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Enquiry.fromJson)
          .toList();
    }
    return const [];
  }

  Future<Enquiry> fetchEnquiry(String tokenId) async {
    final body = unwrap(
      await api.get<dynamic>('$detailPath/$tokenId'),
    );
    final data = body is Map ? body['data'] : body;
    if (data is Map<String, dynamic>) return Enquiry.fromJson(data);
    throw const RepositoryException('Enquiry not found');
  }

  Future<void> updateStatus(String tokenId, EnquiryStatus status) async {
    unwrap(
      await api.post<dynamic>(
        '$updateStatusPath/$tokenId',
        data: {'status': status.key},
      ),
    );
  }
}

final enquiriesRepositoryProvider = Provider<EnquiriesRepository>((ref) {
  return EnquiriesRepository(ref.watch(apiClientProvider));
});
