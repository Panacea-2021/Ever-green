import 'package:flutter_riverpod/flutter_riverpod.dart';

final webModuleSearchQueryProvider = StateProvider<String>((ref) => '');

bool matchesWebSearch(String query, Iterable<String?> fields) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return fields.any(
    (field) => field?.toLowerCase().contains(normalized) ?? false,
  );
}
