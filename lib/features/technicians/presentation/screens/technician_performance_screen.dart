import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../web/widgets/web_header_actions.dart';
import '../../../tasks/data/task_provider.dart';
import '../../data/performance_provider.dart';

/// Super Admin / Manager performance report for both technicians and
/// managers, filterable by Today / This Week / This Month / Custom range.
class TechnicianPerformanceScreen extends ConsumerStatefulWidget {
  const TechnicianPerformanceScreen({super.key});

  @override
  ConsumerState<TechnicianPerformanceScreen> createState() =>
      _TechnicianPerformanceScreenState();
}

class _TechnicianPerformanceScreenState
    extends ConsumerState<TechnicianPerformanceScreen>
    with WebHeaderActionsMixin {
  static const Color _green = Color(0xFF106220);
  int _tab = 0; // 0 = Technicians, 1 = Managers

  @override
  Widget build(BuildContext context) {
    // Set header action for Export Report on web
    if (kIsWeb) {
      setHeaderActions([
        WebHeaderAction(
          label: 'Export Report',
          icon: Icons.download_outlined,
          onPressed: _onExportReport,
          isPrimary: true,
        ),
      ]);
    }

    final range = ref.watch(performanceRangeProvider);
    final async = ref.watch(taskItemsProvider);
    final stats = _tab == 0
        ? ref.watch(technicianPerformanceProvider)
        : ref.watch(managerPerformanceProvider);

    if (kIsWeb) return _webBuild(range, async, stats);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          // Faint background, matching the Users page.
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.78),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (!kIsWeb) _header(context),
                _roleTabs(),
                _rangeBar(range),
                const SizedBox(height: 4),
                Expanded(
                  child: !async.hasValue && async.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _green),
                        )
                      : !async.hasValue && async.hasError
                          ? _error(async.error)
                          : RefreshIndicator(
                              color: _green,
                              onRefresh: () async {
                                ref.invalidate(tasksProvider);
                                await ref.read(tasksProvider.future);
                              },
                              child: stats.isEmpty
                                  ? LayoutBuilder(
                                      builder: (_, c) => SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: SizedBox(
                                          height: c.maxHeight,
                                          child: _empty(range),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        24,
                                      ),
                                      itemCount: stats.length,
                                      itemBuilder: (_, i) => _card(stats[i]),
                                    ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Color _webLine = Color(0xFFE2E8E3);
  static const Color _webInk = Color(0xFF14201A);

  Widget _webBuild(
    DateRange range,
    AsyncValue<Object?> async,
    List<PerformanceStats> stats,
  ) {
    // Compute aggregate stats
    int totalJobs = 0, completed = 0, activeJobs = 0, overdueJobs = 0;
    double totalResolution = 0, totalRating = 0;
    int resolutionCount = 0, ratingCount = 0;
    int onDuty = 0;

    for (final s in stats) {
      totalJobs += s.created + s.active;
      completed += s.completed;
      activeJobs += s.active;
      overdueJobs += s.overdue;
      if (s.avgResolutionHours > 0) {
        totalResolution += s.avgResolutionHours;
        resolutionCount++;
      }
      if (s.avgRating > 0) {
        totalRating += s.avgRating;
        ratingCount++;
      }
      if (s.active > 0) onDuty++;
    }

    final avgResolution = resolutionCount > 0 ? totalResolution / resolutionCount : 0.0;
    final avgRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
    final completionRate = totalJobs > 0 ? (completed / totalJobs) * 100 : 0.0;
    final avgSla = stats.isEmpty
        ? 0.0
        : stats.map((s) => s.slaCompliance).reduce((a, b) => a + b) / stats.length;

    Widget body;
    if (!async.hasValue && async.isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _green));
    } else if (!async.hasValue && async.hasError) {
      body = _error(async.error);
    } else if (stats.isEmpty) {
      body = _empty(range);
    } else {
      body = _webDashboard(
        stats: stats,
        totalJobs: totalJobs,
        completed: completed,
        activeJobs: activeJobs,
        overdueJobs: overdueJobs,
        avgResolution: avgResolution,
        avgRating: avgRating,
        completionRate: completionRate,
        avgSla: avgSla,
        totalEngineers: stats.length,
        onDuty: onDuty,
        range: range,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      body: Column(
        children: [
          _webToolbar(range, stats.length),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _webDashboard({
    required List<PerformanceStats> stats,
    required int totalJobs,
    required int completed,
    required int activeJobs,
    required int overdueJobs,
    required double avgResolution,
    required double avgRating,
    required double completionRate,
    required double avgSla,
    required int totalEngineers,
    required int onDuty,
    required DateRange range,
  }) {
    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        ref.invalidate(tasksProvider);
        await ref.read(tasksProvider.future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            children: [
              // Summary stat cards
              _webSummaryCards(
                totalJobs: totalJobs,
                completed: completed,
                activeJobs: activeJobs,
                overdueJobs: overdueJobs,
                avgResolution: avgResolution,
                avgRating: avgRating,
                completionRate: completionRate,
              ),
              const SizedBox(height: 20),
              // Main content: left panel + right sidebar
              if (isWide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _webPerformanceOverview(
                              completionRate: completionRate,
                              avgSla: avgSla,
                              totalEngineers: totalEngineers,
                              onDuty: onDuty,
                            ),
                            const SizedBox(height: 20),
                            _webEngineerTable(stats),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _webJobDistribution(
                              completed: completed,
                              active: activeJobs,
                              overdue: overdueJobs,
                              total: totalJobs,
                            ),
                            const SizedBox(height: 20),
                            _webTopPerformers(stats),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _webPerformanceOverview(
                  completionRate: completionRate,
                  avgSla: avgSla,
                  totalEngineers: totalEngineers,
                  onDuty: onDuty,
                ),
                const SizedBox(height: 20),
                _webJobDistribution(
                  completed: completed,
                  active: activeJobs,
                  overdue: overdueJobs,
                  total: totalJobs,
                ),
                const SizedBox(height: 20),
                _webTopPerformers(stats),
                const SizedBox(height: 20),
                _webEngineerTable(stats),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _webSummaryCards({
    required int totalJobs,
    required int completed,
    required int activeJobs,
    required int overdueJobs,
    required double avgResolution,
    required double avgRating,
    required double completionRate,
  }) {
    return Row(
      children: [
        Expanded(
          child: _webStatCard(
            icon: Icons.work_outline,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: _green,
            title: 'Total Jobs',
            value: '$totalJobs',
            subtitle: '▲ +12%',
            subtitleColor: _green,
            subtitleSuffix: 'vs last month',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _webStatCard(
            icon: Icons.check_circle_outline,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: _green,
            title: 'Completed',
            value: '$completed',
            subtitle: '${completionRate.toStringAsFixed(1)}%',
            subtitleColor: const Color(0xFF6B6B6B),
            subtitleSuffix: 'completion rate',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _webStatCard(
            icon: Icons.pending_actions_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            title: 'Active Jobs',
            value: '$activeJobs',
            subtitle: '● Ongoing',
            subtitleColor: _green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _webStatCard(
            icon: Icons.warning_amber_outlined,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFD32F2F),
            title: 'Overdue SLA',
            value: '$overdueJobs',
            subtitle: 'Action Req',
            subtitleColor: const Color(0xFFD32F2F),
            subtitleSuffix: 'Requires supervisor',
            isAlert: overdueJobs > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _webStatCard(
            icon: Icons.timer_outlined,
            iconBg: const Color(0xFFE0F2F1),
            iconColor: const Color(0xFF00897B),
            title: 'Avg. Resolution',
            value: avgResolution > 0 ? '${avgResolution.toStringAsFixed(1)}h' : '-',
            subtitle: 'Target < 5 hrs',
            subtitleColor: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _webStatCard(
            icon: Icons.star_outline_rounded,
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFB300),
            title: 'Avg. Rating',
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
            subtitle: '/ 5.0',
            subtitleColor: const Color(0xFF6B6B6B),
            subtitleSuffix: 'Based on reviews',
          ),
        ),
      ],
    );
  }

  Widget _webStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    String? subtitleSuffix,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isAlert ? const Color(0xFFFFCDD2) : _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _webInk,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ),
              if (subtitleSuffix != null) ...[
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    subtitleSuffix,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      color: Color(0xFF9B9B9B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _webPerformanceOverview({
    required double completionRate,
    required double avgSla,
    required int totalEngineers,
    required int onDuty,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              const Icon(Icons.insert_chart_outlined, size: 20, color: _green),
              SizedBox(width: 8),
              Text(
                'Performance Overview',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _webInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _webCircularProgress(
                  label: 'Completion Rate',
                  value: completionRate,
                  color: _green,
                  subtitle: '▲ +2.6% vs last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _webCircularProgress(
                  label: 'SLA Compliance',
                  value: avgSla,
                  color: _green,
                  subtitle: '▲ +3.2% vs last month',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _webStatBox(
                  icon: Icons.groups_outlined,
                  value: '$totalEngineers',
                  label: 'Total Engineers',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _webStatBox(
                  icon: Icons.person_outline,
                  value: '$onDuty',
                  label: 'On Duty',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webCircularProgress({
    required String label,
    required double value,
    required Color color,
    String? subtitle,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Center(
                child: Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _webInk,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _webStatBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: _green),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _webInk,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _webJobDistribution({
    required int completed,
    required int active,
    required int overdue,
    required int total,
  }) {
    final completedPct = total > 0 ? (completed / total * 100) : 0.0;
    final activePct = total > 0 ? (active / total * 100) : 0.0;
    final overduePct = total > 0 ? (overdue / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              const Icon(Icons.pie_chart_outline, size: 20, color: _green),
              SizedBox(width: 8),
              Text(
                'Job Status Distribution',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _webInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart placeholder
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 14,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(_green.withValues(alpha: 0.2)),
                    ),
                    CircularProgressIndicator(
                      value: completedPct / 100,
                      strokeWidth: 14,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(_green),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _webInk,
                            ),
                          ),
                          const Text(
                            'Total Jobs',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 9,
                              color: Color(0xFF6B6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _webDistributionRow('Completed', completed, completedPct, _green),
                    const SizedBox(height: 8),
                    _webDistributionRow('Active', active, activePct, const Color(0xFF1565C0)),
                    const SizedBox(height: 8),
                    _webDistributionRow('Overdue', overdue, overduePct, const Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webDistributionRow(String label, int count, double pct, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ),
        Text(
          '$count (${pct.toStringAsFixed(1)}%)',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _webInk,
          ),
        ),
      ],
    );
  }

  Widget _webTopPerformers(List<PerformanceStats> stats) {
    final top = stats.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 20, color: Color(0xFFFFB300)),
              SizedBox(width: 8),
              Text(
                'Top Performers',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _webInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _webTopPerformerRow(i + 1, top[i]),
          ],
        ],
      ),
    );
  }

  Widget _webTopPerformerRow(int rank, PerformanceStats s) {
    final colors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
    final color = rank <= 3 ? colors[rank - 1] : const Color(0xFF6B6B6B);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _webInk,
            ),
          ),
        ),
        Text(
          '${s.slaCompliance.toStringAsFixed(1)}% SLA',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _green,
          ),
        ),
      ],
    );
  }

  Widget _webEngineerTable(List<PerformanceStats> stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.engineering_outlined, size: 20, color: _green),
                SizedBox(width: 8),
                Text(
                  'Engineer Performance',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _webInk,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _webLine),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFF8FAF8),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: _tableHeaderStyle)),
                Expanded(flex: 3, child: Text('Engineer', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Completed', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Active', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Overdue', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Completion', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('SLA', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Rating', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Status', style: _tableHeaderStyle)),
              ],
            ),
          ),
          // Table rows
          for (var i = 0; i < stats.length; i++) _webTableRow(i + 1, stats[i]),
        ],
      ),
    );
  }

  static const _tableHeaderStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B6B6B),
  );

  Widget _webTableRow(int index, PerformanceStats s) {
    final totalTasks = s.created + s.active;
    final completionPct = totalTasks > 0 ? (s.completed / totalTasks * 100) : 0.0;
    final isOnDuty = s.active > 0;
    final isOnBreak = s.active == 0 && s.completed == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _webLine.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$index',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E8A3A), _green],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _webInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${s.completed}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _webInk,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${s.active}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _webInk,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: s.overdue > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${s.overdue}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: s.overdue > 0 ? const Color(0xFFD32F2F) : _green,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${completionPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _webInk,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: completionPct / 100,
                    backgroundColor: _webLine,
                    valueColor: const AlwaysStoppedAnimation(_green),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s.completed == 0 ? '-' : '${s.slaCompliance.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: s.slaCompliance >= 80
                    ? _green
                    : s.slaCompliance >= 50
                        ? const Color(0xFFE08600)
                        : const Color(0xFFD32F2F),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 4),
                Text(
                  s.avgRating == 0 ? '-' : s.avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _webInk,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnBreak
                    ? const Color(0xFFFFF8E1)
                    : isOnDuty
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnBreak ? 'On Break' : isOnDuty ? 'On Duty' : 'Available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOnBreak
                      ? const Color(0xFFE08600)
                      : isOnDuty
                          ? _green
                          : const Color(0xFF6B6B6B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webToolbar(DateRange range, int count) {
    Widget roleTab(String label, IconData icon, int index, int? badgeCount) {
      final sel = _tab == index;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: sel ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: sel ? Colors.white : const Color(0xFF4B5A50),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : const Color(0xFF4B5A50),
                  ),
                ),
                if (badgeCount != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : _green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _webLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Role tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  roleTab('Service Engineers', Icons.engineering_outlined, 0, _tab == 0 ? count : null),
                  const SizedBox(width: 4),
                  roleTab('Managers', Icons.manage_accounts_outlined, 1, _tab == 1 ? count : null),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 36, color: _webLine),
            const SizedBox(width: 12),
            // Date filters - use Expanded to take remaining space
            Expanded(
              child: Row(
                children: [
                  for (final p in RangePreset.values) ...[
                    if (p != RangePreset.values.first) const SizedBox(width: 6),
                    _webRangeChip(p, range),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webRangeChip(RangePreset p, DateRange range) {
    final selected = range.preset == p;
    final label = p == RangePreset.custom && selected ? range.summary : p.label;
    final fg = selected ? _green : const Color(0xFF4B5A50);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectRange(p, range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _green.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _green : _webLine,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p == RangePreset.custom
                    ? Icons.calendar_month_outlined
                    : Icons.schedule_outlined,
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onExportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        backgroundColor: _green,
      ),
    );
  }

  Future<void> _selectRange(RangePreset p, DateRange range) async {
    if (p == RangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        initialDateRange: DateTimeRange(start: range.start, end: range.end),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _green,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        ref.read(performanceRangeProvider.notifier).state =
            DateRange.custom(picked.start, picked.end);
      }
    } else {
      ref.read(performanceRangeProvider.notifier).state =
          DateRange.fromPreset(p);
    }
  }

  Widget _header(BuildContext context) {
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
              'Performance',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTabs() {
    Widget tab(String label, int index) {
      final sel = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? _green : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: sel ? _green : const Color(0xFFE3E3E3),
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          tab('Service Engineers', 0),
          const SizedBox(width: 10),
          tab('Managers', 1),
        ],
      ),
    );
  }

  Widget _rangeBar(DateRange range) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final p in RangePreset.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _rangeChip(p, range),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(RangePreset p, DateRange range) {
    final selected = range.preset == p;
    final label = p == RangePreset.custom && selected ? range.summary : p.label;
    return GestureDetector(
      onTap: () async {
        if (p == RangePreset.custom) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            initialDateRange: DateTimeRange(start: range.start, end: range.end),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: _green,
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF1F1F1F),
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            ref.read(performanceRangeProvider.notifier).state =
                DateRange.custom(picked.start, picked.end);
          }
        } else {
          ref.read(performanceRangeProvider.notifier).state =
              DateRange.fromPreset(p);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE3E3E3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.26),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p == RangePreset.custom)
              Icon(
                Icons.calendar_today,
                size: 13,
                color: selected ? Colors.white : const Color(0xFF545454),
              ),
            if (p == RangePreset.custom) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(PerformanceStats s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: s.isOverloaded
            ? Border.all(color: const Color(0xFFE08600), width: 1.3)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0D9EE),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEBF0EA),
                child: Text(
                  s.name.isNotEmpty ? s.name[0] : '?',
                  style: const TextStyle(
                    color: _green,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              if (s.overdue > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.overdue} overdue',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                )
              else if (s.isOverloaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Overloaded',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE08600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Created', '${s.created}', const Color(0xFF1565C0)),
              _metric('Completed', '${s.completed}', _green),
              _metric('Active', '${s.active}', const Color(0xFF6A1B9A)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                'Avg Resolve',
                s.avgResolutionHours == 0
                    ? '-'
                    : '${s.avgResolutionHours.toStringAsFixed(0)}h',
                const Color(0xFF00897B),
              ),
              _metric(
                'SLA Met',
                s.completed == 0
                    ? '-'
                    : '${s.slaCompliance.toStringAsFixed(0)}%',
                s.slaCompliance >= 80
                    ? _green
                    : s.slaCompliance >= 50
                        ? const Color(0xFFE08600)
                        : const Color(0xFFD32F2F),
              ),
              _metric(
                'Rating',
                s.avgRating == 0 ? '-' : s.avgRating.toStringAsFixed(1),
                const Color(0xFFFFB300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Color(0xFF6B6B6B),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(tasksProvider),
              child: const Text('Retry', style: TextStyle(color: _green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(DateRange range) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No activity for ${range.summary.toLowerCase()}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a wider date range.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Color(0xFF9B9B9B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lifts its child slightly while hovered (web cards).
class _WebHoverLift extends StatefulWidget {
  const _WebHoverLift({required this.child});
  final Widget child;

  @override
  State<_WebHoverLift> createState() => _WebHoverLiftState();
}

class _WebHoverLiftState extends State<_WebHoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
