import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../widgets/picker_scaffold.dart';
import '../../../../core/utils/fuzzy_search.dart';

/// Whether [e] matches [query] (typo-tolerant, see [fuzzyMatches]) by
/// name, make, model, serial number, EG serial number, type or location.
bool equipmentMatches(Equipment e, String query) => fuzzyMatches(query, [
      e.name,
      e.make,
      e.model,
      e.serialNumber,
      e.egSerialNumber,
      e.type,
      e.location,
      e.serviceType?.name,
    ]);

/// Full-page searchable list of one company's equipment. Inactive equipment
/// is hidden unless it is the current [selectedId]. Pops with the selected
/// [Equipment]:
///
/// ```dart
/// final equipment = await EquipmentPickerScreen.open(context, companyId: 9);
/// ```
class EquipmentPickerScreen extends ConsumerWidget {
  const EquipmentPickerScreen({
    super.key,
    required this.companyId,
    this.selectedId,
  });

  final int companyId;
  final int? selectedId;

  static Future<Equipment?> open(
    BuildContext context, {
    required int companyId,
    int? selectedId,
  }) {
    return Navigator.of(context).push<Equipment>(
      MaterialPageRoute(
        builder: (_) =>
            EquipmentPickerScreen(companyId: companyId, selectedId: selectedId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipments = ref.watch(equipmentsProvider(companyId)).whenData(
          (list) =>
              list.where((e) => e.isActive || e.id == selectedId).toList(),
        );
    return PickerScaffold<Equipment>(
      title: 'Select Equipment',
      searchHint: 'Search name, make, model, serial',
      items: equipments,
      matches: equipmentMatches,
      onRetry: () => ref.invalidate(equipmentsProvider(companyId)),
      emptyText: 'No equipment for this company',
      itemBuilder: (context, e) {
        final makeModel = [e.make ?? '', e.model ?? '']
            .where((s) => s.isNotEmpty)
            .join(' · ');
        final serials = [
          if (e.egSerialNumber.isNotEmpty) 'EG ${e.egSerialNumber}',
          if ((e.serialNumber ?? '').isNotEmpty) 'S.No ${e.serialNumber}',
        ].join('  •  ');
        return PickerCard(
          icon: Icons.handyman_outlined,
          imageUrl: mediaUrl(e.imageUrl),
          title: e.name.isEmpty ? 'Equipment #${e.id}' : e.name,
          tag: e.isActive ? e.serviceType?.name : 'Inactive',
          selected: e.id == selectedId,
          lines: [makeModel, serials],
          onTap: () => Navigator.of(context).pop(e),
        );
      },
    );
  }
}
