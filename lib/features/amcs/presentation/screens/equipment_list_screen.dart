import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';

/// Standalone Equipment List for Company Manager: aggregates equipment across
/// all companies assigned to the logged-in user. Backend scopes the result.
class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> _filtered(List<Equipment> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((e) {
      final company = e.company?.name ?? '';
      return e.name.toLowerCase().contains(q) ||
          (e.serialNumber ?? '').toLowerCase().contains(q) ||
          (e.egSerialNumber).toLowerCase().contains(q) ||
          (e.location ?? '').toLowerCase().contains(q) ||
          company.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(equipmentsProvider(null));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Equipment List'),
        backgroundColor: const Color(0xFF106220),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search equipment',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load equipment: $e'),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(equipmentsProvider(null)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final visible = _filtered(items);
                if (visible.isEmpty) {
                  return const Center(child: Text('No equipment found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(equipmentsProvider(null).future),
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final e = visible[index];
                      return ListTile(
                        leading: const Icon(Icons.precision_manufacturing),
                        title: Text(e.name),
                        subtitle: Text(
                          '${e.company?.name ?? ''} • ${e.serialNumber ?? e.egSerialNumber}',
                        ),
                        trailing: Text(e.location ?? ''),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}