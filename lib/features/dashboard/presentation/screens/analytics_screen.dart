import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/analytics_provider.dart';
import '../../data/dashboard_repository.dart';

/// Super Admin / Manager analytics overview with a CSV export action.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const Color _green = Color(0xFF106220);

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(dashboardUsersProvider)
      ..invalidate(userStatsProvider)
      ..invalidate(taskCountsProvider)
      ..invalidate(companiesProvider)
      ..invalidate(equipmentsProvider(null));
    try {
      await ref.read(dashboardAnalyticsProvider.future);
    } catch (_) {
      // Rendered as the error state.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, ref, analytics.valueOrNull),
            Expanded(
              child: RefreshIndicator(
                color: _green,
                onRefresh: () => _refresh(ref),
                child: analytics.when(
                  skipLoadingOnRefresh: true,
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                  error: (e, _) => _errorState(e, () => _refresh(ref)),
                  data: _content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(DashboardAnalytics a) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _totalsRow(a),
        const SizedBox(height: 16),
        _section(
          'Users by Access Level',
          a.totalUsers,
          [
            for (final e in a.usersByRole.entries)
              _Bar(e.key.label, e.value, _roleColor(e.key)),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          'Tasks by Status',
          a.totalTasks,
          [
            for (final e in a.tasksByStatus.entries)
              _Bar(e.key, e.value, _taskColor(e.key)),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          'AMCs by Status',
          a.totalAmcs,
          [
            for (final e in a.amcsByStatus.entries)
              _Bar(e.key.label, e.value, _amcColor(e.key)),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          'Equipment by Status',
          a.totalEquipment,
          [
            for (final e in a.equipmentByStatus.entries)
              _Bar(e.key.label, e.value, _equipmentColor(e.key)),
          ],
        ),
      ],
    );
  }

  Widget _errorState(Object error, VoidCallback onRetry) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Couldn't load analytics",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Color(0xFF9B9B9B),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, DashboardAnalytics? a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Analytics',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          GestureDetector(
            onTap: a == null ? null : () => _exportCsv(context, a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Export',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsRow(DashboardAnalytics a) {
    return Row(
      children: [
        _totalCard(
          'Users',
          a.totalUsers,
          const Color(0xFFEAF2FF),
          const Color(0xFF1565C0),
        ),
        const SizedBox(width: 10),
        _totalCard(
          'Tasks',
          a.totalTasks,
          const Color(0xFFF1E9FF),
          const Color(0xFF6A1B9A),
        ),
        const SizedBox(width: 10),
        _totalCard('AMCs', a.totalAmcs, const Color(0xFFEBF0EA), _green),
      ],
    );
  }

  Widget _totalCard(String label, int value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, int total, List<_Bar> bars) {
    final maxVal =
        bars.fold<int>(1, (m, b) => b.value > m ? b.value : m).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 14),
          for (final bar in bars) ...[
            _barRow(bar, maxVal),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _barRow(_Bar bar, double maxVal) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            bar.label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Color(0xFF545454),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: maxVal == 0 ? 0 : bar.value / maxVal,
              minHeight: 16,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(bar.color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '${bar.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context, DashboardAnalytics a) async {
    final csv = a.toCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: _green),
                SizedBox(width: 8),
                Text(
                  'CSV copied to clipboard',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                csv,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole r) => switch (r) {
        UserRole.superAdmin => const Color(0xFF106220),
        UserRole.manager => const Color(0xFF1565C0),
        UserRole.seniorTechnician => const Color(0xFFC25E00),
        UserRole.technician => const Color(0xFFE08600),
        UserRole.clientAdmin => const Color(0xFF4A148C),
        UserRole.client => const Color(0xFF6A1B9A),
      };

  Color _taskColor(String status) => switch (status) {
        'Open' => const Color(0xFF1565C0),
        'Hold' => const Color(0xFFE08600),
        'In Progress' => const Color(0xFF6A1B9A),
        'Closed' => const Color(0xFF106220),
        _ => Colors.grey,
      };

  Color _amcColor(AmcHealth s) => switch (s) {
        AmcHealth.active => const Color(0xFF106220),
        AmcHealth.expiringSoon => const Color(0xFFE08600),
        AmcHealth.expired => const Color(0xFFD32F2F),
      };

  Color _equipmentColor(EquipmentCondition s) => switch (s) {
        EquipmentCondition.operational => const Color(0xFF106220),
        EquipmentCondition.underMaintenance => const Color(0xFFE08600),
        EquipmentCondition.faulty => const Color(0xFFD32F2F),
        EquipmentCondition.retired => const Color(0xFF6B6B6B),
      };
}

class _Bar {
  final String label;
  final int value;
  final Color color;
  const _Bar(this.label, this.value, this.color);
}
