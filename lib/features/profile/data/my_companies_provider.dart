import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/network/api_client.dart';

/// Parses the full company rows from an `auth/me` payload
/// (`data.company_user[].company`).
List<Company> companiesFromMe(dynamic body) {
  final data = body is Map ? body['data'] : null;
  final links = data is Map ? data['company_user'] : null;
  if (links is! List) return const [];
  return [
    for (final link in links)
      if (link is Map && link['company'] is Map<String, dynamic>)
        Company.fromJson(link['company'] as Map<String, dynamic>),
  ];
}

/// Companies the signed-in user is linked to, with every company column
/// (GST, location, AMC dates, …), read fresh from `auth/me`.
final myCompaniesProvider = FutureProvider.autoDispose<List<Company>>((ref) async {
  final body = unwrap(await ref.watch(apiClientProvider).get<dynamic>('auth/me'));
  return companiesFromMe(body);
});
