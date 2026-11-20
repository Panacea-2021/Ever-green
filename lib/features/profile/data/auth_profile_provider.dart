import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/network/api_client.dart';

/// Raw payload from `GET /auth/profile`. Exposed so the Company Profile
/// section can map whatever fields the backend actually returns without
/// inventing keys. Returns null on failure so callers can fall back.
final authProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) async {
    try {
      final body = unwrap(await ref.watch(apiClientProvider).get<dynamic>('auth/profile'));
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return null;
    } catch (_) {
      return null;
    }
  },
);

/// Companies derived from `GET /auth/profile`, if the response carries them.
/// Falls back to an empty list when the endpoint omits company details, so
/// the existing `myCompaniesProvider` (auth/me) remains the source of truth.
List<Company> companiesFromProfile(Map<String, dynamic>? body) {
  if (body == null) return const [];
  dynamic source = body;
  // Unwrap common envelopes.
  if (source['data'] is Map) source = source['data'];
  // Try common company-carrying keys.
  for (final key in const ['company', 'companies', 'company_user', 'companyUser']) {
    final v = source is Map ? source[key] : null;
    if (v is Map<String, dynamic>) {
      try {
        return [Company.fromJson(v)];
      } catch (_) {}
    }
    if (v is List) {
      final out = <Company>[];
      for (final item in v) {
        if (item is Map<String, dynamic>) {
          final company = item['company'];
          if (company is Map<String, dynamic>) {
            try {
              out.add(Company.fromJson(company));
            } catch (_) {}
          } else {
            try {
              out.add(Company.fromJson(item));
            } catch (_) {}
          }
        }
      }
      if (out.isNotEmpty) return out;
    }
  }
  return const [];
}