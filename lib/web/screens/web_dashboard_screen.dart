import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/data/equipment_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';

/// Authenticated web dashboard with charts and visualizations
class WebDashboardScreen extends ConsumerWidget {
  const WebDashboardScreen({super.key});

  static const _green = Color(0xFF106220);
  static const _red = Color(0xFFD32F2F);
  static const _orange = Color(0xFFE08600);
  static const _blue = Color(0xFF1565C0);
  static const _purple = Color(0xFF6A1B9A);
  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final unassigned = ref.watch(unassignedCountProvider);
    final renewals = ref.watch(amcRenewalsProvider);
    final equipmentCount = ref.watch(equipmentCountProvider);
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(currentUserProvider);

    bool pending(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;
    final tasksLoading = pending(ref.watch(taskItemsProvider));
    final companiesLoading = pending(ref.watch(companiesProvider));

    final openCount = tasks.where((t) => t.status != TaskStatus.closed).length;
    final closedCount = tasks.where((t) => t.status == TaskStatus.closed).length;
    final inProgressCount =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final holdCount = tasks.where((t) => t.status == TaskStatus.hold).length;

    VoidCallback? open(String route) =>
        Permissions.canAccessRoute(role, route) ? () => context.go(route) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _WelcomeHeader(userName: user?.name ?? 'User'),
                    const SizedBox(height: 20),

                    // Stats Cards Row
                    _StatsCardsRow(
                      openCount: openCount,
                      overdueCount: overdue.length,
                      unassignedCount: unassigned,
                      renewalsCount: renewals.length,
                      equipmentCount: equipmentCount,
                      loading: tasksLoading,
                      onOpenTasks: open(Routes.tasks),
                      onOverdue: open(Routes.tasks),
                      onUnassigned: open(Routes.ticketQueue),
                      onRenewals: open(Routes.amcRenewals),
                      onEquipment: open(Routes.amcs),
                    ),
                    const SizedBox(height: 20),

                    // Charts Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1100;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _TaskStatusChart(
                                  open: openCount - inProgressCount - holdCount,
                                  inProgress: inProgressCount,
                                  hold: holdCount,
                                  closed: closedCount,
                                  loading: tasksLoading,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 4,
                                child: _TaskPriorityChart(
                                  tasks: tasks,
                                  loading: tasksLoading,
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _TaskStatusChart(
                              open: openCount - inProgressCount - holdCount,
                              inProgress: inProgressCount,
                              hold: holdCount,
                              closed: closedCount,
                              loading: tasksLoading,
                            ),
                            const SizedBox(height: 20),
                            _TaskPriorityChart(
                              tasks: tasks,
                              loading: tasksLoading,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bottom Row: Recent Tasks + Renewals
                    LayoutBuilder(
                      builder: (context, c) {
                        final table = _RecentTasksTable(
                          tasks: tasks,
                          loading: tasksLoading,
                          onViewAll: open(Routes.tasks),
                        );
                        final panel = _RenewalsPanel(
                          renewals: renewals,
                          loading: companiesLoading,
                          onViewAll: open(Routes.amcRenewals),
                        );
                        if (c.maxWidth < 1100) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [table, const SizedBox(height: 20), panel],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: table),
                            const SizedBox(width: 20),
                            Expanded(flex: 4, child: panel),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $userName 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Here\'s what\'s happening with your tasks today.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF666666)),
              const SizedBox(width: 10),
              Text(
                _formatDate(now),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatsCardsRow extends StatelessWidget {
  const _StatsCardsRow({
    required this.openCount,
    required this.overdueCount,
    required this.unassignedCount,
    required this.renewalsCount,
    required this.equipmentCount,
    required this.loading,
    this.onOpenTasks,
    this.onOverdue,
    this.onUnassigned,
    this.onRenewals,
    this.onEquipment,
  });

  final int openCount;
  final int overdueCount;
  final int unassignedCount;
  final int renewalsCount;
  final int equipmentCount;
  final bool loading;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOverdue;
  final VoidCallback? onUnassigned;
  final VoidCallback? onRenewals;
  final VoidCallback? onEquipment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final cols = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 600
                ? 3
                : constraints.maxWidth >= 400
                    ? 2
                    : 1;
        final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;

        final cards = [
          _StatCard(
            title: 'Open Tasks',
            value: '$openCount',
            subtitle: 'Active tasks',
            icon: Icons.checklist_rtl_rounded,
            color: WebDashboardScreen._green,
            trend: openCount > 0 ? '+$openCount active' : 'No active',
            trendUp: openCount > 0,
            onTap: onOpenTasks,
            loading: loading,
          ),
          _StatCard(
            title: 'Overdue (SLA)',
            value: '$overdueCount',
            subtitle: overdueCount > 0 ? 'Needs attention' : 'All on track',
            icon: Icons.warning_amber_rounded,
            color: WebDashboardScreen._red,
            trend: overdueCount > 0 ? '$overdueCount overdue' : 'On schedule',
            trendUp: overdueCount == 0,
            onTap: onOverdue,
            loading: loading,
          ),
          _StatCard(
            title: 'Unassigned',
            value: '$unassignedCount',
            subtitle: 'In the queue',
            icon: Icons.person_off_outlined,
            color: WebDashboardScreen._orange,
            trend: unassignedCount > 0 ? 'Needs assign' : 'All assigned',
            trendUp: unassignedCount == 0,
            onTap: onUnassigned,
            loading: loading,
          ),
          _StatCard(
            title: 'Renewals Due',
            value: '$renewalsCount',
            subtitle: 'AMC expiring',
            icon: Icons.autorenew_rounded,
            color: WebDashboardScreen._blue,
            trend: renewalsCount > 0 ? '$renewalsCount due soon' : 'All active',
            trendUp: renewalsCount == 0,
            onTap: onRenewals,
            loading: loading,
          ),
          _StatCard(
            title: 'Equipment',
            value: '$equipmentCount',
            subtitle: 'Under service',
            icon: Icons.kitchen_outlined,
            color: WebDashboardScreen._purple,
            trend: '$equipmentCount total',
            trendUp: true,
            onTap: onEquipment,
            loading: loading,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: cardW, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
    required this.loading,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? widget.color.withValues(alpha: 0.4) : const Color(0xFFE8E8E8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _hovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.loading
              ? _buildSkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3,),
                          decoration: BoxDecoration(
                            color: widget.trendUp
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.trendUp
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 12,
                                color: widget.trendUp
                                    ? WebDashboardScreen._green
                                    : WebDashboardScreen._red,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.trend,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.trendUp
                                      ? WebDashboardScreen._green
                                      : WebDashboardScreen._red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              width: 50,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 45,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

class _TaskStatusChart extends StatelessWidget {
  const _TaskStatusChart({
    required this.open,
    required this.inProgress,
    required this.hold,
    required this.closed,
    required this.loading,
  });

  final int open;
  final int inProgress;
  final int hold;
  final int closed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final total = open + inProgress + hold + closed;
    final data = [
      _ChartData('Open', open, WebDashboardScreen._orange),
      _ChartData('In Progress', inProgress, WebDashboardScreen._blue),
      _ChartData('On Hold', hold, const Color(0xFF9E9E9E)),
      _ChartData('Closed', closed, WebDashboardScreen._green),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Status Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Distribution of tasks by status',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total total',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (loading)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            SizedBox(
              height: 220,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: data.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) * 1.3,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF333333),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${data[group.x.toInt()].label}\n${data[group.x.toInt()].value}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final labels = ['Open', 'In Progress', 'Hold', 'Closed'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => const FlLine(
                            color: Color(0xFFEEEEEE),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (var i = 0; i < data.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data[i].value.toDouble(),
                                  color: data[i].color,
                                  width: 32,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final d in data) ...[
                          _LegendItem(
                            color: d.color,
                            label: d.label,
                            value: d.value,
                            percentage: total > 0 ? (d.value / total * 100) : 0,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;
  const _ChartData(this.label, this.value, this.color);
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  final Color color;
  final String label;
  final int value;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}

class _TaskPriorityChart extends StatelessWidget {
  const _TaskPriorityChart({
    required this.tasks,
    required this.loading,
  });

  final List<TaskItem> tasks;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final critical =
        tasks.where((t) => t.priority == TaskPriority.critical).length;
    final high = tasks.where((t) => t.priority == TaskPriority.high).length;
    final medium = tasks.where((t) => t.priority == TaskPriority.medium).length;
    final low = tasks.where((t) => t.priority == TaskPriority.low).length;
    final total = critical + high + medium + low;

    final data = [
      _ChartData('Critical', critical, WebDashboardScreen._red),
      _ChartData('High', high, WebDashboardScreen._orange),
      _ChartData('Medium', medium, WebDashboardScreen._blue),
      _ChartData('Low', low, const Color(0xFF9E9E9E)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tasks by priority level',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          if (loading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (final d in data)
                            if (d.value > 0)
                              PieChartSectionData(
                                value: d.value.toDouble(),
                                color: d.color,
                                title: '${(d.value / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                radius: 50,
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in data) ...[
                        _SmallLegend(color: d.color, label: d.label, value: d.value),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallLegend extends StatelessWidget {
  const _SmallLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class _RecentTasksTable extends StatelessWidget {
  const _RecentTasksTable({
    required this.tasks,
    required this.loading,
    this.onViewAll,
  });

  final List<TaskItem> tasks;
  final bool loading;
  final VoidCallback? onViewAll;

  Color _statusColor(TaskItem t) {
    if (t.isClosed) return WebDashboardScreen._green;
    switch (t.status) {
      case TaskStatus.hold:
        return const Color(0xFF9E9E9E);
      case TaskStatus.inProgress:
        return WebDashboardScreen._blue;
      case TaskStatus.open:
        return t.hasAssignee
            ? WebDashboardScreen._orange
            : WebDashboardScreen._red;
      case TaskStatus.closed:
        return WebDashboardScreen._green;
    }
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.critical => WebDashboardScreen._red,
        TaskPriority.high => WebDashboardScreen._orange,
        TaskPriority.medium => WebDashboardScreen._blue,
        TaskPriority.low => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    final recent = [...tasks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top = recent.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (onViewAll != null)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View all'),
                  style: TextButton.styleFrom(
                    foregroundColor: WebDashboardScreen._green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            _buildSkeleton()
          else if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Task', style: _headerStyle)),
                      Expanded(flex: 3, child: Text('Company', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Assignee', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Status', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Priority', style: _headerStyle)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Rows
                for (final t in top)
                  _TaskRow(
                    task: t,
                    statusColor: _statusColor(t),
                    priorityColor: _priorityColor(t.priority),
                    onTap: () => context.push('${Routes.taskDetails}/${t.id}'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF666666),
  );
}

class _TaskRow extends StatefulWidget {
  const _TaskRow({
    required this.task,
    required this.statusColor,
    required this.priorityColor,
    required this.onTap,
  });

  final TaskItem task;
  final Color statusColor;
  final Color priorityColor;
  final VoidCallback onTap;

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF5F7F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: _hovered ? Colors.transparent : const Color(0xFFEEEEEE),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  widget.task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  widget.task.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.task.hasAssignee ? widget.task.assignee : 'Unassigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.task.hasAssignee
                        ? const Color(0xFF666666)
                        : WebDashboardScreen._red,
                    fontStyle:
                        widget.task.hasAssignee ? null : FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _Pill(
                  label: widget.task.lifecycleLabel,
                  color: widget.statusColor,
                ),
              ),
              Expanded(
                flex: 2,
                child: _Pill(
                  label: widget.task.priority.label,
                  color: widget.priorityColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _RenewalsPanel extends StatelessWidget {
  const _RenewalsPanel({
    required this.renewals,
    required this.loading,
    this.onViewAll,
  });

  final List<AmcContract> renewals;
  final bool loading;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final top = renewals.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'AMC Renewals Due',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (renewals.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3,),
                      decoration: BoxDecoration(
                        color: WebDashboardScreen._red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${renewals.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: WebDashboardScreen._red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (onViewAll != null && renewals.isNotEmpty)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(
                    'View all',
                    style: TextStyle(color: WebDashboardScreen._green),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            _buildSkeleton()
          else if (top.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: WebDashboardScreen._green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All contracts active!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No renewals due at this time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < top.length; i++)
                  _RenewalRow(contract: top[i], last: i == top.length - 1),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RenewalRow extends StatefulWidget {
  const _RenewalRow({required this.contract, required this.last});

  final AmcContract contract;
  final bool last;

  @override
  State<_RenewalRow> createState() => _RenewalRowState();
}

class _RenewalRowState extends State<_RenewalRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final expired = widget.contract.status() == AmcStatus.expired;
    final accent =
        expired ? WebDashboardScreen._red : WebDashboardScreen._orange;
    final days = widget.contract.daysUntilExpiry();
    final sub = expired
        ? 'Expired ${-days} day${days == -1 ? '' : 's'} ago'
        : 'Expires in $days day${days == 1 ? '' : 's'}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF5F7F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: widget.last
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.autorenew, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contract.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              expired ? Icons.error_outline : Icons.schedule,
              size: 18,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dashboard background with subtle gradient and pattern
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFFF0F7F4), // Light mint
        Color(0xFFF8FAF9), // Off-white
        Color(0xFFFAFBFC), // Very light
        Color(0xFFF5F9F7), // Light green tint
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Decorative circles in top-right corner
    final circlePaint = Paint()
      ..color = const Color(0xFF106220).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width - 100, -50),
      200,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width + 50, 150),
      180,
      circlePaint..color = const Color(0xFF106220).withValues(alpha: 0.02),
    );

    // Decorative circle in bottom-left
    canvas.drawCircle(
      Offset(-80, size.height - 100),
      220,
      circlePaint..color = const Color(0xFF106220).withValues(alpha: 0.025),
    );

    // Subtle grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFF106220).withValues(alpha: 0.015)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 60.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Top gradient overlay for depth
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3],
    );
    
    final topOverlayPaint = Paint()
      ..shader = topGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.4), topOverlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
