import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/permissions.dart';
import '../../core/router/routes.dart';
import '../../features/enquiries/data/enquiries_repository.dart';
import '../../features/enquiries/domain/enquiry.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';

/// Web-only Enquiries page: lists customer repair enquiries submitted through
/// the "Book a Repair" popup. Backend integration is pending, so the screen
/// shows an integration-pending empty state until the API is available.
class WebEnquiriesScreen extends ConsumerStatefulWidget {
  const WebEnquiriesScreen({super.key});

  @override
  ConsumerState<WebEnquiriesScreen> createState() => _WebEnquiriesScreenState();
}

class _WebEnquiriesScreenState extends ConsumerState<WebEnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  EnquiryStatus? _statusFilter; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canViewReports(role)) {
      return const Center(child: Text('Access denied'));
    }

    final repo = ref.watch(enquiriesRepositoryProvider);
    return FutureBuilder<List<Enquiry>>(
      future: repo.fetchEnquiries(search: _search, status: _statusFilter),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
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
        DropdownButton<EnquiryStatus?>(
          value: _statusFilter,
          hint: const Text('All'),
          items: [
            const DropdownMenuItem<EnquiryStatus?>(value: null, child: Text('All')),
            ...EnquiryStatus.values.map(
              (s) => DropdownMenuItem<EnquiryStatus?>(value: s, child: Text(s.label)),
            ),
          ],
          onChanged: (v) => setState(() => _statusFilter = v),
        ),
      ],
    );
  }

  Widget _buildBody(AsyncSnapshot<List<Enquiry>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Enquiries API is not available yet. '
              'Integration pending — please check back once the backend endpoint is ready.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final items = snapshot.data ?? const [];
    if (items.isEmpty) {
      return const Center(child: Text('No enquiries found.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Token ID')),
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
  }

  void _showDetails(Enquiry e) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enquiry ${e.tokenId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('Token ID', e.tokenId),
            _detail('Customer Name', e.customerName),
            _detail('Phone Number', e.phone),
            _detail('Email', e.email ?? '-'),
            _detail('Equipment', e.equipment ?? '-'),
            _detail('Service', e.service ?? '-'),
            _detail('Submission Date', e.submissionDate?.toLocal().toString() ?? '-'),
            _detail('Status', e.status.label),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
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
