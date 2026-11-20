import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../widgets/picker_scaffold.dart';

/// Whether [c] matches the lower-cased [query] by name, branch, location or
/// GST number.
bool companyMatches(Company c, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return [c.name, c.branchName, c.location ?? '', c.gstNumber ?? '']
      .any((f) => f.toLowerCase().contains(q));
}

/// Full-page searchable list of companies (each backend row is one branch).
/// Pops with the selected [Company]:
///
/// ```dart
/// final company = await CompanyPickerScreen.open(context);
/// ```
class CompanyPickerScreen extends ConsumerWidget {
  const CompanyPickerScreen({super.key, this.selectedId, this.allowedIds});

  /// Highlighted as the current choice.
  final int? selectedId;

  /// When set, only these companies are listed (client roles).
  final Set<int>? allowedIds;

  static Future<Company?> open(
    BuildContext context, {
    int? selectedId,
    Set<int>? allowedIds,
  }) {
    return Navigator.of(context).push<Company>(
      MaterialPageRoute(
        builder: (_) =>
            CompanyPickerScreen(selectedId: selectedId, allowedIds: allowedIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var companies = ref.watch(companiesProvider);
    final allowed = allowedIds;
    if (allowed != null) {
      companies = companies.whenData(
        (list) => list.where((c) => allowed.contains(c.id)).toList(),
      );
    }
    return PickerScaffold<Company>(
      title: 'Select Company',
      searchHint: 'Search name, branch, location, GST',
      items: companies,
      matches: companyMatches,
      onRetry: () => ref.invalidate(companiesProvider),
      emptyText: 'No companies yet',
      itemBuilder: (context, c) => PickerCard(
        icon: Icons.apartment_outlined,
        title: c.name.isEmpty ? 'Company #${c.id}' : c.name,
        tag: c.serviceLabel.isEmpty ? null : c.serviceLabel,
        selected: c.id == selectedId,
        lines: [
          if (c.branchName.isNotEmpty) 'Branch : ${c.branchName}',
          if ((c.location ?? '').isNotEmpty) 'Location : ${c.location}',
          if ((c.gstNumber ?? '').isNotEmpty) 'GST : ${c.gstNumber}',
        ],
        onTap: () => Navigator.of(context).pop(c),
      ),
    );
  }
}
