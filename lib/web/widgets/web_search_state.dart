import 'package:flutter_riverpod/flutter_riverpod.dart';

final webModuleSearchQueryProvider = StateProvider<String>((ref) => '');

bool matchesWebSearch(String query, Iterable<String?> fields) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return fields.any(
    (field) => field?.toLowerCase().contains(normalized) ?? false,
  );
}

bool matchesWebSearchTerms(String query, Iterable<String?> fields) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  final terms = normalized.split(RegExp(r'\s+'));
  final searchableFields = fields
      .where((field) => field != null && field.trim().isNotEmpty)
      .map((field) => field!.toLowerCase())
      .toList();
  return terms.every(
    (term) => searchableFields.any((field) => field.contains(term)),
  );
}
