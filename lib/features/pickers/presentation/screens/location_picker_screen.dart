import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/utils/fuzzy_search.dart';
import '../widgets/picker_scaffold.dart';

/// One distinct location and where it is already used.
class LocationOption {
  const LocationOption(this.location, this.usedBy);

  final String location;

  /// e.g. "Branch address", "Equipment: Split AC", "3 tickets".
  final List<String> usedBy;
}

/// Distinct locations of [company]: its branch address, then its equipment,
/// then its earlier tickets (case-insensitive, first spelling wins).
List<LocationOption> companyLocations({
  Company? company,
  List<Equipment> equipment = const [],
  List<ServiceTask> tasks = const [],
}) {
  final order = <String>[];
  final names = <String, String>{};
  final sources = <String, List<String>>{};
  final ticketCounts = <String, int>{};
  String? add(String? raw) {
    final location = raw?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (location.isEmpty) return null;
    final key = location.toLowerCase();
    if (!names.containsKey(key)) {
      names[key] = location;
      order.add(key);
      sources[key] = [];
    }
    return key;
  }

  final branch = add(company?.location);
  if (branch != null) sources[branch]!.add('Branch address');
  for (final e in equipment) {
    final key = add(e.location);
    if (key != null) {
      sources[key]!.add('Equipment: ${e.name.isEmpty ? '#${e.id}' : e.name}');
    }
  }
  for (final t in tasks) {
    final companyId = t.company?.id ?? t.equipment?.companyId;
    if (company != null && companyId != company.id) continue;
    final key = add(t.location);
    if (key != null) ticketCounts[key] = (ticketCounts[key] ?? 0) + 1;
  }
  for (final e in ticketCounts.entries) {
    sources[e.key]!.add('${e.value} ticket${e.value == 1 ? '' : 's'}');
  }

  return [for (final k in order) LocationOption(names[k]!, sources[k]!)];
}

/// Full-page searchable list of the locations already used in a company,
/// with a row to use the typed text as a new location. Pops with the
/// location string:
///
/// ```dart
/// final location = await LocationPickerScreen.open(context, company: c);
/// ```
class LocationPickerScreen extends ConsumerWidget {
  const LocationPickerScreen({super.key, this.company, this.selected});

  final Company? company;
  final String? selected;

  static Future<String?> open(
    BuildContext context, {
    Company? company,
    String? selected,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(company: company, selected: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = company?.id;
    final equipment = companyId == null
        ? const AsyncValue<List<Equipment>>.data([])
        : ref.watch(equipmentsProvider(companyId));
    final tasks = ref.watch(tasksProvider);
    final AsyncValue<List<LocationOption>> options = equipment.isLoading
        ? const AsyncValue.loading()
        : AsyncValue.data(
            companyLocations(
              company: company,
              equipment: equipment.valueOrNull ?? const [],
              tasks: tasks.valueOrNull ?? const [],
            ),
          );
    final current = selected?.trim().toLowerCase() ?? '';
    return PickerScaffold<LocationOption>(
      title: 'Select Location',
      searchHint: 'Search or type a new location',
      items: options,
      matches: (o, q) => fuzzyMatches(q, [o.location]),
      onRetry: () {
        if (companyId != null) ref.invalidate(equipmentsProvider(companyId));
        ref.invalidate(tasksProvider);
      },
      emptyText: 'No saved locations yet. Type one in the search box.',
      queryItemBuilder: (context, query) {
        final exists = (options.valueOrNull ?? const <LocationOption>[]).any(
          (o) => o.location.toLowerCase() == query.toLowerCase(),
        );
        if (exists) return null;
        return PickerCard(
          key: const Key('useTypedLocation'),
          icon: Icons.add_location_alt_outlined,
          title: 'Use "$query"',
          lines: const ['New location'],
          onTap: () => Navigator.of(context).pop(query),
        );
      },
      itemBuilder: (context, o) => PickerCard(
        icon: Icons.place_outlined,
        title: o.location,
        selected: o.location.toLowerCase() == current,
        lines: [o.usedBy.join('  •  ')],
        onTap: () => Navigator.of(context).pop(o.location),
      ),
    );
  }
}
