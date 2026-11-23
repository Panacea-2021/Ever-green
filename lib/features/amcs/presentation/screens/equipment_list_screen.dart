import 'package:flutter/foundation.dart' show kIsWeb;
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
  static const _green = Color(0xFF106220);
  static const _webLine = Color(0xFFE2E8E3);

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
          company.toLowerCase().contains(q) ||
          (e.make ?? '').toLowerCase().contains(q) ||
          (e.model ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(equipmentsProvider(null));
    return Scaffold(
      backgroundColor: kIsWeb ? const Color(0xFFF7F9F6) : Colors.white,
      appBar: AppBar(
        title: const Text('Equipment List'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (kIsWeb) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _webHeader(),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _webSearchField(),
            ),
            const SizedBox(height: 14),
          ] else ...[
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
          ],
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _green)),
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
                if (kIsWeb) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(equipmentsProvider(null).future),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      itemCount: visible.length,
                      itemBuilder: (context, index) =>
                          _webCard(visible[index]),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(equipmentsProvider(null).future),
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

  Widget _webHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.precision_manufacturing,
              color: _green, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Equipment List',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14201A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'All equipment assigned to your companies',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _webSearchField() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _webLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Search by name, serial number, location...',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              color: Color(0xFF9B9B9B),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.search, color: Color(0xFF6B6B6B), size: 22),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 50),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _webCard(Equipment e) {
    final company = e.company?.name ?? '';
    final branch = e.company?.branchName ?? '';
    final serial = (e.serialNumber ?? '').isNotEmpty
        ? e.serialNumber!
        : e.egSerialNumber;
    final displayName = e.name.trim().isNotEmpty
        ? e.name
        : (serial.isNotEmpty ? serial : 'Equipment #${e.id}');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 460,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.precision_manufacturing,
                          color: _green, size: 22),
                    ),
                    const SizedBox(width: 14),
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF14201A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ID: ${e.id}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF106220),
                                  ),
                                ),
                              ),
                              if (e.status != EquipmentCondition.operational)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDECEA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    e.status.label,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ((e.make ?? '').isNotEmpty || (e.model ?? '').isNotEmpty)
                            _detailLine('Model / Mfr',
                                [if ((e.make ?? '').isNotEmpty) e.make!, if ((e.model ?? '').isNotEmpty) e.model!].join(' - ')),
                          _detailLine('Serial No.', serial.isEmpty ? '—' : serial),
                          if (company.isNotEmpty) _detailLine('Company', company),
                          if (branch.isNotEmpty) _detailLine('Branch', branch),
                          if ((e.type ?? '').isNotEmpty) _detailLine('Type', e.type!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFFE2E8E3)),
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((e.location ?? '').isNotEmpty) ...[
                      const Text(
                        'Location / Address',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF106220),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.location!,
                        softWrap: true,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF14201A),
                          height: 1.4,
                        ),
                      ),
                    ] else
                      const Text(
                        'Location / Address: —',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF14201A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}