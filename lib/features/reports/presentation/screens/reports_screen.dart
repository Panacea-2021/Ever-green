import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reports_provider.dart';
import '../../domain/models/report_models.dart';

/// Reports & Analytics center for Super Admin
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const Color _green = Color(0xFF106220);
  static const Color _cream = Color(0xFFFBFCFA);

  int _selectedReport = 0; // 0=Dashboard, 1=Tasks, 2=Technicians, 3=AMCs, 4=Equipment, 5=SLA

  static const _reportTypes = [
    ('Dashboard', Icons.dashboard_outlined),
    ('Task Summary', Icons.assignment_outlined),
    ('Technician Performance', Icons.engineering_outlined),
    ('AMC Status', Icons.handshake_outlined),
    ('Equipment Health', Icons.precision_manufacturing_outlined),
    ('SLA Compliance', Icons.verified_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webBuild();
    return _mobileBuild();
  }

  Widget _webBuild() {
    return Scaffold(
      backgroundColor: _cream,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 280,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3ECE5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _webSectionLabel('REPORTS'),
                const SizedBox(height: 12),
                for (var i = 0; i < _reportTypes.length; i++)
                  _webSideItem(
                    label: _reportTypes[i].$1,
                    icon: _reportTypes[i].$2,
                    selected: _selectedReport == i,
                    onTap: () => setState(() => _selectedReport = i),
                  ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE3ECE5)),
                const SizedBox(height: 16),
                _webSectionLabel('DATE RANGE'),
                const SizedBox(height: 12),
                _webDateRangeSelector(),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: _webContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black.withValues(alpha: 0.4),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _webSideItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF106220), Color(0xFF1A801A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: _green.withValues(alpha: 0.06),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selected
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFF2F7F3),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? Colors.white : _green,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webDateRangeSelector() {
    final range = ref.watch(reportDateRangeProvider);
    final ranges = [
      ('This Month', ReportDateRange.thisMonth),
      ('Last Month', ReportDateRange.lastMonth),
      ('Last 30 Days', ReportDateRange.last30Days),
      ('Last 90 Days', ReportDateRange.last90Days),
      ('This Year', ReportDateRange.thisYear),
    ];

    return Column(
      children: [
        for (final r in ranges)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ref.read(reportDateRangeProvider.notifier).state = r.$2();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _isSameRange(range, r.$2())
                      ? _green.withValues(alpha: 0.1)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: _isSameRange(range, r.$2())
                          ? _green
                          : Colors.black.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r.$1,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: _isSameRange(range, r.$2())
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _isSameRange(range, r.$2())
                            ? _green
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isSameRange(ReportDateRange a, ReportDateRange b) {
    return a.from.day == b.from.day &&
        a.from.month == b.from.month &&
        a.from.year == b.from.year &&
        a.to.day == b.to.day &&
        a.to.month == b.to.month &&
        a.to.year == b.to.year;
  }

  Widget _webContent() {
    return switch (_selectedReport) {
      0 => _webDashboard(),
      1 => _webTaskSummary(),
      2 => _webTechnicianPerformance(),
      3 => _webAmcStatus(),
      4 => _webEquipmentHealth(),
      5 => _webSlaCompliance(),
      _ => _webDashboard(),
    };
  }

  Widget _webDashboard() {
    final async = ref.watch(reportsDashboardProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webDashboardContent(data),
    );
  }

  Widget _webDashboardContent(ReportsDashboard data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('Reports Dashboard', 'Overview of key metrics'),
          const SizedBox(height: 24),
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Total Tasks',
                  '${data.tasksSummary.total}',
                  Icons.assignment_outlined,
                  const Color(0xFF1565C0),
                  '${data.tasksSummary.open} open',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  'Technicians',
                  '${data.techniciansSummary.total}',
                  Icons.engineering_outlined,
                  const Color(0xFF6A4BC4),
                  '${data.techniciansSummary.active} active',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  'Active AMCs',
                  '${data.amcsSummary.active}',
                  Icons.handshake_outlined,
                  const Color(0xFFE08600),
                  '${data.amcsSummary.expiringSoon} expiring soon',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  'SLA Compliance',
                  '${data.slaCompliance}%',
                  Icons.verified_outlined,
                  _green,
                  'Last 30 days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Second row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _dashboardCard(
                  'Tasks Overview',
                  Icons.pie_chart_outline,
                  child: _tasksPieChart(data.tasksSummary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _dashboardCard(
                  'Recent Activity',
                  Icons.history,
                  child: _recentActivityList(data.recentActivity),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Equipment & AMC row
          Row(
            children: [
              Expanded(
                child: _dashboardCard(
                  'Equipment Status',
                  Icons.precision_manufacturing_outlined,
                  child: _equipmentStatus(data.equipmentSummary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dashboardCard(
                  'AMC Summary',
                  Icons.handshake_outlined,
                  child: _amcSummary(data.amcsSummary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3F15), Color(0xFF1A801A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.analytics_outlined, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          _exportButton(),
        ],
      ),
    );
  }

  Widget _exportButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showExportDialog(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.download_outlined, size: 18, color: _green),
                SizedBox(width: 8),
                Text(
                  'Export',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Export Report',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportOption(Icons.table_chart, 'Export as CSV', () {
              Navigator.pop(ctx);
              _showSnack('CSV export coming soon');
            }),
            const SizedBox(height: 8),
            _exportOption(Icons.picture_as_pdf, 'Export as PDF', () {
              Navigator.pop(ctx);
              _showSnack('PDF export coming soon');
            }),
            const SizedBox(height: 8),
            _exportOption(Icons.grid_on, 'Export as Excel', () {
              Navigator.pop(ctx);
              _showSnack('Excel export coming soon');
            }),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3ECE5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _green, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14201A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(String title, IconData icon, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _green),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14201A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _tasksPieChart(TasksSummary data) {
    final segments = [
      ('Open', data.open, const Color(0xFFE08600)),
      ('Completed', data.completed, _green),
      ('Overdue', data.overdue, const Color(0xFFD32F2F)),
    ];
    final total = data.total > 0 ? data.total : 1;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    segments.map((s) => (s.$2 / total, s.$3)).toList(),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.total}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14201A),
                    ),
                  ),
                  Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: s.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.$1,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  '${s.$2}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recentActivityList(List<RecentActivity> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Text(
          'No recent activity',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final a in activities.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _activityIcon(a.type),
                    size: 16,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        a.type,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _relativeTime(a.timestamp),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _activityIcon(String type) {
    if (type.contains('created')) return Icons.add_circle_outline;
    if (type.contains('updated')) return Icons.edit_outlined;
    if (type.contains('deleted')) return Icons.delete_outline;
    if (type.contains('assigned')) return Icons.assignment_ind_outlined;
    return Icons.history;
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _equipmentStatus(EquipmentSummary data) {
    return Column(
      children: [
        _statusRow('Operational', data.operational, _green),
        const SizedBox(height: 12),
        _statusRow('Needs Attention', data.needsAttention, const Color(0xFFD32F2F)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${data.total}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14201A),
                ),
              ),
              const Text(
                ' equipment',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _amcSummary(AmcsSummary data) {
    return Column(
      children: [
        _statusRow('Active', data.active, _green),
        const SizedBox(height: 12),
        _statusRow('Expiring Soon', data.expiringSoon, const Color(0xFFE08600)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${data.total}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14201A),
                ),
              ),
              const Text(
                ' AMCs',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Task Summary Report
  Widget _webTaskSummary() {
    final async = ref.watch(taskSummaryReportProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webTaskSummaryContent(data),
    );
  }

  Widget _webTaskSummaryContent(TaskSummaryReport data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('Task Summary Report', 'Detailed task analytics'),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              Expanded(child: _statCard('Total', data.totalTasks, Icons.assignment)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Open', data.openTasks, Icons.pending_actions, color: const Color(0xFFE08600))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('In Progress', data.inProgressTasks, Icons.autorenew, color: const Color(0xFF1565C0))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Completed', data.completedTasks, Icons.check_circle_outline, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Overdue', data.overdueCount, Icons.warning_amber, color: const Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dashboardCard(
                  'Tasks by Status',
                  Icons.pie_chart,
                  child: _chartDataList(data.tasksByStatus),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dashboardCard(
                  'Tasks by Priority',
                  Icons.flag_outlined,
                  child: _chartDataList(data.tasksByPriority),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dashboardCard(
                  'Tasks by Type',
                  Icons.category_outlined,
                  child: _chartDataList(data.tasksByCallType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _dashboardCard(
            'Daily Trend (Last 14 Days)',
            Icons.trending_up,
            child: _trendChart(data.dailyTrend),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, dynamic value, IconData icon, {Color color = _green}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3ECE5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartDataList(List<ChartData> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    final total = data.fold<int>(0, (sum, d) => sum + d.value);
    final colors = [_green, const Color(0xFF1565C0), const Color(0xFFE08600), const Color(0xFF6A4BC4), const Color(0xFFD32F2F)];

    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatLabel(data[i].label),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      '${data[i].value}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? data[i].value / total : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(colors[i % colors.length]),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatLabel(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Widget _trendChart(List<TrendData> data) {
    if (data.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No data')));
    }
    final maxValue = data.fold<int>(0, (max, d) => d.created > max ? d.created : (d.completed > max ? d.completed : max));
    const height = 150.0;

    return SizedBox(
      height: height + 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: maxValue > 0 ? (data[i].created / maxValue) * height : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 8,
                        height: maxValue > 0 ? (data[i].completed / maxValue) * height : 0,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data[i].date.substring(5),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Technician Performance Report
  Widget _webTechnicianPerformance() {
    final async = ref.watch(technicianPerformanceReportProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webTechnicianContent(data),
    );
  }

  Widget _webTechnicianContent(TechnicianPerformanceReport data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('Technician Performance', 'Service engineer analytics'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard('Avg Resolution', '${data.averageResolutionTime}h', Icons.timer_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('SLA Compliance', '${data.overallSlaCompliance}%', Icons.verified, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Technicians', '${data.technicians.length}', Icons.engineering)),
            ],
          ),
          const SizedBox(height: 24),
          _dashboardCard(
            'Performance Table',
            Icons.table_chart,
            child: _technicianTable(data.technicians),
          ),
        ],
      ),
    );
  }

  Widget _technicianTable(List<TechnicianPerformance> technicians) {
    if (technicians.isEmpty) {
      return const Center(child: Text('No technicians'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF14201A),
        ),
        dataTextStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Assigned'), numeric: true),
          DataColumn(label: Text('Completed'), numeric: true),
          DataColumn(label: Text('Avg Hours'), numeric: true),
          DataColumn(label: Text('Rating'), numeric: true),
          DataColumn(label: Text('SLA %'), numeric: true),
        ],
        rows: technicians.map((t) => DataRow(cells: [
          DataCell(Text(t.name)),
          DataCell(Text('${t.totalAssigned}')),
          DataCell(Text('${t.completed}')),
          DataCell(Text('${t.avgResolutionHours}')),
          DataCell(Text(t.avgRating != null ? '${t.avgRating}' : '-')),
          DataCell(Text('${t.slaCompliance}%')),
        ],),).toList(),
      ),
    );
  }

  // AMC Status Report
  Widget _webAmcStatus() {
    final async = ref.watch(amcStatusReportProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webAmcContent(data),
    );
  }

  Widget _webAmcContent(AmcStatusReport data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('AMC Status Report', 'Contract analytics'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard('Total', data.totalAmcs, Icons.handshake)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Active', data.activeAmcs, Icons.check_circle, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Expiring', data.expiringSoon, Icons.warning, color: const Color(0xFFE08600))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Expired', data.expired, Icons.cancel, color: const Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: 24),
          if (data.expiringContracts.isNotEmpty)
            _dashboardCard(
              'Expiring Soon',
              Icons.notification_important,
              child: _expiringList(data.expiringContracts),
            ),
        ],
      ),
    );
  }

  Widget _expiringList(List<ExpiringContract> contracts) {
    return Column(
      children: contracts.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE08600).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business, size: 20, color: Color(0xFFE08600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.companyName,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Expires: ${c.endDate}',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE08600).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${c.daysRemaining} days',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE08600),
                ),
              ),
            ),
          ],
        ),
      ),).toList(),
    );
  }

  // Equipment Health Report
  Widget _webEquipmentHealth() {
    final async = ref.watch(equipmentHealthReportProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webEquipmentContent(data),
    );
  }

  Widget _webEquipmentContent(EquipmentHealthReport data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('Equipment Health', 'Equipment status analytics'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard('Total', data.totalEquipment, Icons.precision_manufacturing)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Operational', data.operational, Icons.check_circle, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Maintenance', data.underMaintenance, Icons.build, color: const Color(0xFFE08600))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Faulty', data.faulty, Icons.error, color: const Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dashboardCard(
                  'By Status',
                  Icons.pie_chart,
                  child: _chartDataList(data.equipmentByStatus),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dashboardCard(
                  'By Service Type',
                  Icons.category,
                  child: _chartDataList(data.equipmentByServiceType),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SLA Compliance Report
  Widget _webSlaCompliance() {
    final async = ref.watch(slaComplianceReportProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _green)),
      error: (e, _) => _errorState('$e'),
      data: (data) => _webSlaContent(data),
    );
  }

  Widget _webSlaContent(SlaComplianceReport data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader('SLA Compliance', 'Service level analytics'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard('Compliance', '${data.complianceRate}%', Icons.verified, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Within SLA', data.withinSla, Icons.check_circle, color: _green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Breached', data.slaBreached, Icons.cancel, color: const Color(0xFFD32F2F))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Avg Response', '${data.avgResponseTime}h', Icons.timer)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dashboardCard(
                  'By Priority',
                  Icons.flag,
                  child: _priorityComplianceList(data.complianceByPriority),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dashboardCard(
                  'Breach Reasons',
                  Icons.report_problem,
                  child: _chartDataList(data.breachReasons),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityComplianceList(List<PriorityCompliance> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    return Column(
      children: data.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text(
              _formatLabel(p.priority),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              '${p.rate}%',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.rate >= 80 ? _green : (p.rate >= 60 ? const Color(0xFFE08600) : const Color(0xFFD32F2F)),
              ),
            ),
          ],
        ),
      ),).toList(),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load report',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileBuild() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Reports are optimized for web.\nPlease use a desktop browser.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<(double, Color)> segments;

  _PieChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -1.5708; // -90 degrees in radians

    for (final segment in segments) {
      final sweepAngle = segment.$1 * 6.2832; // 2*pi
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
