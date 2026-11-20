import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/permissions.dart';
import '../../core/router/routes.dart';
import '../../features/enquiries/data/enquiries_repository.dart';
import '../../features/enquiries/domain/enquiry.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';

/// Web-only Enquiries page: lists customer repair enquiries from the backend.
class WebEnquiriesScreen extends ConsumerStatefulWidget {
  const WebEnquiriesScreen({super.key});

  @override
  ConsumerState<WebEnquiriesScreen> createState() => _WebEnquiriesScreenState();
}

class _WebEnquiriesScreenState extends ConsumerState<WebEnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  EnquiryStatus? _statusFilter;
  String? _requestTypeFilter; // null = All
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Enquiry>> _load() async {
    final repo = ref.read(enquiriesRepositoryProvider);
    final results = await Future.wait([
      repo.fetchGuestRepairBookings(page: _page),
      repo.fetchFreeEstimates(),
    ]);
    final seen = <String>{};
    final all = <Enquiry>[];
    for (final e in [...results[0], ...results[1]]) {
      if (seen.add(e.tokenId)) all.add(e);
    }
    return all.where((e) {
      final matchesSearch = _search.trim().isEmpty ||
          e.customerName.toLowerCase().contains(_search.trim().toLowerCase()) ||
          e.phone.toLowerCase().contains(_search.trim().toLowerCase()) ||
          (e.email?.toLowerCase().contains(_search.trim().toLowerCase()) ?? false);
      final matchesStatus = _statusFilter == null || e.status == _statusFilter;
      final norm = (e.requestType ?? '').toLowerCase().trim();
      final matchesType = _requestTypeFilter == null ||
          norm == _requestTypeFilter!.toLowerCase().trim() ||
          (_requestTypeFilter == 'Book a Repair' && norm.contains('repair')) ||
          (_requestTypeFilter == 'Get Estimate' && norm.contains('estimate'));
      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canViewReports(role)) {
      return const Center(child: Text('Access denied'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(),
            const SizedBox(height: 16),
            FutureBuilder<List<Enquiry>>(
              future: _load(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('Failed to load enquiries: ${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('No enquiries found.')),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Token ID')),
                      DataColumn(label: Text('Request Type')),
                      DataColumn(label: Text('Customer Name')),
                      DataColumn(label: Text('Phone Number')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Equipment')),
                      DataColumn(label: Text('Service')),
                      DataColumn(label: Text('Submission Date')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: items.map((e) {
                      return DataRow(cells: [
                        DataCell(Text(e.tokenId)),
                        DataCell(Text(e.requestType ?? '-')),
                        DataCell(Text(e.customerName)),
                        DataCell(Text(e.phone)),
                        DataCell(Text(e.email ?? '-')),
                        DataCell(Text(e.equipment ?? '-')),
                        DataCell(Text(e.service ?? '-')),
                        DataCell(Text(e.submissionDate?.toLocal().toString() ?? '-')),
                        DataCell(Text(e.status.label)),
                        DataCell(TextButton(
                          onPressed: () => _showDetails(e),
                          child: const Text('View Details'),
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name, phone or email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: _requestTypeFilter,
          hint: const Text('All Types'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All Types')),
            DropdownMenuItem<String?>(value: 'Book a Repair', child: Text('Book a Repair')),
            DropdownMenuItem<String?>(value: 'Get Estimate', child: Text('Get Estimate')),
          ],
          onChanged: (v) => setState(() => _requestTypeFilter = v),
        ),
        const SizedBox(width: 12),
        DropdownButton<EnquiryStatus?>(
          value: _statusFilter,
          hint: const Text('All Statuses'),
          items: [
            const DropdownMenuItem<EnquiryStatus?>(value: null, child: Text('All Statuses')),
            ...EnquiryStatus.values.map(
              (s) => DropdownMenuItem<EnquiryStatus?>(value: s, child: Text(s.label)),
            ),
          ],
          onChanged: (v) => setState(() => _statusFilter = v),
        ),
      ],
    );
  }

  void _showDetails(Enquiry e) {
    final isRepair = (e.requestType ?? '').toLowerCase().contains('repair');
    showDialog<void>(
      context: context,
      builder: (ctx) => _EnquiryDetailsDialog(
        enquiry: e,
        isRepair: isRepair,
        onRefresh: () => setState(() {}),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _EnquiryDetailsDialog extends ConsumerStatefulWidget {
  final Enquiry enquiry;
  final bool isRepair;
  final VoidCallback onRefresh;
  const _EnquiryDetailsDialog({
    required this.enquiry,
    required this.isRepair,
    required this.onRefresh,
  });

  @override
  ConsumerState<_EnquiryDetailsDialog> createState() => _EnquiryDetailsDialogState();
}

class _EnquiryDetailsDialogState extends ConsumerState<_EnquiryDetailsDialog> {
  Enquiry? _loaded;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isRepair) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(enquiriesRepositoryProvider);
      final e = await repo.fetchFreeEstimate(widget.enquiry.tokenId);
      if (!mounted) return;
      setState(() {
        _loaded = e;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }

  Enquiry get _e => _loaded ?? widget.enquiry;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete enquiry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(enquiriesRepositoryProvider);
      if (widget.isRepair) {
        await repo.deleteGuestRepairBooking(widget.enquiry.tokenId);
      } else {
        await repo.deleteFreeEstimate(widget.enquiry.tokenId);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh();
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $err')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      );
    }
    final e = _e;
    return AlertDialog(
      title: Text('Enquiry ${e.tokenId}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('Token ID', e.tokenId),
            _detail('Request Type', e.requestType ?? '-'),
            _detail('Customer Name', e.customerName),
            _detail('Phone Number', e.phone),
            _detail('Email', e.email ?? '-'),
            _detail('Equipment', e.equipment ?? '-'),
            _detail('Service', e.service ?? '-'),
            if (e.problemDescription != null && e.problemDescription!.trim().isNotEmpty)
              _detail('Problem Description', e.problemDescription!),
            if (e.photos.isNotEmpty) _detail('Uploaded Photos', e.photos.join(', ')),
            _detail('Submission Date', e.submissionDate?.toLocal().toString() ?? '-'),
            _detail('Status', e.status.label),
            if (widget.isRepair) ...[
              const SizedBox(height: 12),
              DropdownButton<EnquiryStatus>(
                value: e.status,
                items: EnquiryStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (s) async {
                  if (s == null || s == e.status) return;
                  try {
                    final repo = ref.read(enquiriesRepositoryProvider);
                    await repo.updateGuestRepairBookingStatus(widget.enquiry.tokenId, s);
                    if (mounted) {
                      Navigator.pop(context);
                      widget.onRefresh();
                    }
                  } catch (err) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $err')));
                    }
                  }
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text('Failed to refresh: $_error', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _delete, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
