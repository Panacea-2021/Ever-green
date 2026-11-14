import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/dashboard/data/analytics_history_provider.dart';
import '../../features/dashboard/data/analytics_provider.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
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
    final renewals = ref.watch(amcRenewalsProvider);
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(currentUserProvider);
    final taskCountsAsync = ref.watch(taskCountsProvider);
    final taskCounts = taskCountsAsync.valueOrNull;
    final statusCounts = tasksByStatusOf(taskCounts ?? const TaskCounts({}));

    bool pending(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;
    final taskCountsLoading = pending(taskCountsAsync);
    final companiesLoading = pending(ref.watch(companiesProvider));

    final openStatusCount = statusCounts['Open'] ?? 0;
    final closedCount = statusCounts['Closed'] ?? 0;
    final inProgressCount = statusCounts['In Progress'] ?? 0;
    final holdCount = statusCounts['Hold'] ?? 0;

    VoidCallback? open(String route, {Object? extra}) =>
        Permissions.canAccessRoute(role, route)
            ? () => context.go(route, extra: extra)
            : null;

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

                    if (taskCountsAsync.hasError) ...[
                      _DashboardDataError(
                        message: 'Task totals could not be loaded.',
                        onRetry: () => ref.invalidate(taskCountsProvider),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (Permissions.canViewOrgOverview(role)) ...[
                      _WebOrganizationSections(
                        onOpenUsers: open(Routes.usersList),
                        onOpenPocs: open(Routes.usersList, extra: {'tab': 2}),
                        onOpenCompanyManagers:
                            open(Routes.usersList, extra: {'tab': 1}),
                        onOpenManagers:
                            open(Routes.usersList, extra: {'tab': 4}),
                        onOpenServiceEngineers: open(Routes.techniciansList) ??
                            open(Routes.usersList, extra: {'tab': 3}),
                        onOpenAmcs: open(Routes.amcs),
                        onOpenTasks: open(Routes.tasks),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _TaskStatusChart(
                      open: openStatusCount,
                      inProgress: inProgressCount,
                      hold: holdCount,
                      closed: closedCount,
                      loading: taskCountsLoading,
                    ),
                    const SizedBox(height: 20),

                    _RenewalsPanel(
                      renewals: renewals,
                      loading: companiesLoading,
                      onViewAll: open(Routes.amcRenewals),
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

class _WebOrganizationSections extends ConsumerWidget {
  const _WebOrganizationSections({
    required this.onOpenUsers,
    required this.onOpenPocs,
    required this.onOpenCompanyManagers,
    required this.onOpenManagers,
    required this.onOpenServiceEngineers,
    required this.onOpenAmcs,
    required this.onOpenTasks,
  });

  final VoidCallback? onOpenUsers;
  final VoidCallback? onOpenPocs;
  final VoidCallback? onOpenCompanyManagers;
  final VoidCallback? onOpenManagers;
  final VoidCallback? onOpenServiceEngineers;
  final VoidCallback? onOpenAmcs;
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);
    final history = ref.watch(analyticsHistoryProvider);

    if (analytics.hasError || history.hasError) {
      return _DashboardDataError(
        message: 'Organization analytics could not be loaded.',
        error: analytics.error ?? history.error,
        onRetry: () {
          ref.invalidate(dashboardAnalyticsProvider);
          ref.invalidate(analyticsHistoryProvider);
        },
      );
    }

    final data = analytics.valueOrNull;
    final snapshots = history.valueOrNull;
    if (data == null || snapshots == null) {
      return const _DashboardAnalyticsLoading();
    }

    final users = data.usersByRole;
    final serviceEngineers = (users[UserRole.seniorTechnician] ?? 0) +
        (users[UserRole.technician] ?? 0) +
        (users[UserRole.coldRoomTechnician] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WebDashboardSectionHeading(
          title: 'Business Summary',
          subtitle: 'Current totals',
        ),
        const SizedBox(height: 12),
        _WebDashboardMetricGrid(
          desktopColumns: 3,
          children: [
            _WebDashboardMetricCard(
              title: 'Users',
              value: data.totalUsers,
              subtitle: 'Across access levels',
              icon: Icons.groups_outlined,
              color: WebDashboardScreen._blue,
              onTap: onOpenUsers,
            ),
            _WebDashboardMetricCard(
              title: 'AMCs',
              value: data.totalAmcs,
              subtitle: 'Service contracts',
              icon: Icons.verified_outlined,
              color: WebDashboardScreen._green,
              onTap: onOpenAmcs,
            ),
            _WebDashboardMetricCard(
              title: 'Tasks',
              value: data.totalTasks,
              subtitle: 'All statuses',
              icon: Icons.checklist_rtl_outlined,
              color: WebDashboardScreen._purple,
              onTap: onOpenTasks,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _WebDashboardSectionHeading(
          title: 'Overview',
          subtitle: 'This month',
        ),
        const SizedBox(height: 12),
        _WebDashboardMetricGrid(
          desktopColumns: 4,
          children: [
            _OverviewMetricCard(
              title: 'POC',
              value: users[UserRole.client] ?? 0,
              metric: TrendMetric.poc,
              icon: Icons.person_outline,
              color: const Color(0xFF2E8B45),
              onTap: onOpenPocs,
            ),
            _OverviewMetricCard(
              title: 'Company Managers',
              value: users[UserRole.clientAdmin] ?? 0,
              metric: TrendMetric.companyManagers,
              icon: Icons.groups_outlined,
              color: const Color(0xFF775DAC),
              onTap: onOpenCompanyManagers,
            ),
            _OverviewMetricCard(
              title: 'Managers',
              value: users[UserRole.manager] ?? 0,
              metric: TrendMetric.managers,
              icon: Icons.admin_panel_settings_outlined,
              color: const Color(0xFF9E663B),
              onTap: onOpenManagers,
            ),
            _OverviewMetricCard(
              title: 'Service Engineers',
              value: serviceEngineers,
              metric: TrendMetric.technicians,
              icon: Icons.build_outlined,
              color: const Color(0xFF5B899E),
              onTap: onOpenServiceEngineers,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _WebDashboardReports(
          analytics: data,
          onOpenTasks: onOpenTasks,
        ),
      ],
    );
  }
}

class _WebDashboardSectionHeading extends StatelessWidget {
  const _WebDashboardSectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _WebDashboardMetricGrid extends StatelessWidget {
  const _WebDashboardMetricGrid({
    required this.children,
    required this.desktopColumns,
  });

  final List<Widget> children;
  final int desktopColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth >= 1100
                ? desktopColumns
                : constraints.maxWidth >= 620
                    ? 2
                    : 1)
            .clamp(1, children.length)
            .toInt();
        const gap = 14.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _WebDashboardMetricCard extends StatelessWidget {
  const _WebDashboardMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.invertTrend = false,
    this.onTap,
    this.valueKey,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Trend? trend;
  final bool invertTrend;
  final VoidCallback? onTap;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final positive = trend == null
        ? null
        : (invertTrend ? !trend!.isPositive : trend!.isPositive);
    final trendColor = positive == null
        ? null
        : positive
            ? WebDashboardScreen._green
            : WebDashboardScreen._red;

    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                key: valueKey,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              if (trend != null)
                Row(
                  children: [
                    Icon(
                      positive! ? Icons.arrow_upward : Icons.arrow_downward,
                      color: trendColor,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${trend!.percent}% vs last month',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                )
              else if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMetricCard extends ConsumerWidget {
  const _OverviewMetricCard({
    required this.title,
    required this.value,
    required this.metric,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final int value;
  final TrendMetric metric;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _WebDashboardMetricCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      trend: ref.watch(trendProvider(metric)),
      onTap: onTap,
    );
  }
}

enum _DashboardReportMetric {
  users('Users'),
  tasks('Tasks'),
  equipment('Equipment');

  const _DashboardReportMetric(this.label);
  final String label;
}

class _WebDashboardReports extends ConsumerStatefulWidget {
  const _WebDashboardReports({
    required this.analytics,
    required this.onOpenTasks,
  });

  final DashboardAnalytics analytics;
  final VoidCallback? onOpenTasks;

  @override
  ConsumerState<_WebDashboardReports> createState() =>
      _WebDashboardReportsState();
}

class _WebDashboardReportsState extends ConsumerState<_WebDashboardReports> {
  _DashboardReportMetric _metric = _DashboardReportMetric.users;
  int _selectedYear = DateTime.now().year;

  TrendMetric get _barMetric => switch (_metric) {
        _DashboardReportMetric.users => TrendMetric.technicians,
        _DashboardReportMetric.tasks => TrendMetric.openTasks,
        _DashboardReportMetric.equipment => TrendMetric.equipment,
      };

  TrendMetric get _lineMetric => switch (_metric) {
        _DashboardReportMetric.users => TrendMetric.companyManagers,
        _DashboardReportMetric.tasks => TrendMetric.closedTasks,
        _DashboardReportMetric.equipment => TrendMetric.amcs,
      };

  String get _chartTitle => switch (_metric) {
        _DashboardReportMetric.users => 'Users by Access Level',
        _DashboardReportMetric.tasks => 'Task Throughput',
        _DashboardReportMetric.equipment => 'Equipment & Contracts',
      };

  (String, String) get _legendLabels => switch (_metric) {
        _DashboardReportMetric.users => (
            'Service Engineers',
            'Company Managers'
          ),
        _DashboardReportMetric.tasks => ('Open', 'Closed'),
        _DashboardReportMetric.equipment => ('Equipment', 'AMCs'),
      };

  @override
  Widget build(BuildContext context) {
    final yearOptions = ref.watch(analyticsYearsProvider);
    final years = yearOptions.isEmpty ? [DateTime.now().year] : yearOptions;
    final selectedYear =
        years.contains(_selectedYear) ? _selectedYear : years.last;
    final snapshots = ref.watch(yearSnapshotsProvider(selectedYear));
    final reportSnapshots = snapshots.length <= 7
        ? snapshots
        : snapshots.sublist(snapshots.length - 7);
    final bars = [
      for (final snapshot in reportSnapshots)
        snapshot.metric(_barMetric).toDouble(),
    ];
    final line = [
      for (final snapshot in reportSnapshots)
        snapshot.metric(_lineMetric).toDouble(),
    ];
    final labels = reportSnapshots.map(snapshotMonthLabel).toList();
    final labelsForLegend = _legendLabels;
    final openTasks = (widget.analytics.tasksByStatus['Open'] ?? 0) +
        (widget.analytics.tasksByStatus['Hold'] ?? 0) +
        (widget.analytics.tasksByStatus['In Progress'] ?? 0);
    final openTrend = ref.watch(trendProvider(TrendMetric.openTasks));
    final closedTrend = ref.watch(trendProvider(TrendMetric.closedTasks));

    return Container(
      padding: const EdgeInsets.all(20),
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
          const _WebDashboardSectionHeading(
            title: 'Reports',
            subtitle: 'Monthly trends',
          ),
          const SizedBox(height: 14),
          _WebDashboardMetricGrid(
            desktopColumns: 2,
            children: [
              _WebDashboardMetricCard(
                title: 'Open Tasks',
                value: openTasks,
                icon: Icons.assignment_outlined,
                color: WebDashboardScreen._green,
                trend: openTrend,
                invertTrend: true,
                onTap: widget.onOpenTasks,
                valueKey: const ValueKey('web-report-open-tasks-count'),
              ),
              _WebDashboardMetricCard(
                title: 'Closed (mo)',
                value: closedTrend.current,
                icon: Icons.task_alt,
                color: const Color(0xFF5B899E),
                trend: closedTrend,
                onTap: widget.onOpenTasks,
                valueKey: const ValueKey('web-report-closed-tasks-count'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              DropdownButton<int>(
                value: selectedYear,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(10),
                items: [
                  for (final year in years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (year) {
                  if (year != null) setState(() => _selectedYear = year);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _ReportLegend(
                color: WebDashboardScreen._green,
                label: labelsForLegend.$1,
              ),
              _ReportLegend(
                color: WebDashboardScreen._blue,
                label: labelsForLegend.$2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in _DashboardReportMetric.values)
                ChoiceChip(
                  label: Text(metric.label),
                  selected: _metric == metric,
                  selectedColor: WebTokens.mintSoft,
                  labelStyle: TextStyle(
                    color: _metric == metric
                        ? WebTokens.greenDark
                        : const Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _metric = metric),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: _buildCombinedChart(context, bars, line, labels),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedChart(
    BuildContext context,
    List<double> bars,
    List<double> line,
    List<String> labels,
  ) {
    if (labels.isEmpty) {
      return const Center(
        child: Text(
          'No monthly data for this year',
          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
        ),
      );
    }

    final maxValue = [...bars, ...line, 1.0].reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue * 1.25).ceilToDouble();
    final interval =
        (maxY / 4).ceilToDouble().clamp(1.0, double.infinity).toDouble();
    final maxX = labels.length > 1 ? (labels.length - 1).toDouble() : 1.0;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 450);

    return Stack(
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            minY: 0,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1A1A1A),
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${labels[group.x]}\n${rod.toY.round()}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: interval,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: index >= labels.length - 2
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: index >= labels.length - 2
                              ? WebDashboardScreen._green
                              : const Color(0xFF777777),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFEEEEEE),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var index = 0; index < labels.length; index++)
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: index < bars.length ? bars[index] : 0,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF3AA05A), WebTokens.green],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration: duration,
        ),
        IgnorePointer(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: maxX,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: WebDashboardScreen._blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: spot.x == labels.length - 1 ? 4.5 : 0,
                      color: WebDashboardScreen._blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        WebDashboardScreen._blue.withValues(alpha: 0.18),
                        WebDashboardScreen._blue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  spots: [
                    for (var index = 0; index < labels.length; index++)
                      FlSpot(
                        index.toDouble(),
                        index < line.length ? line[index] : 0,
                      ),
                  ],
                ),
              ],
            ),
            duration: duration,
          ),
        ),
      ],
    );
  }
}

class _ReportLegend extends StatelessWidget {
  const _ReportLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _DashboardAnalyticsLoading extends StatelessWidget {
  const _DashboardAnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: WebTokens.green),
      ),
    );
  }
}

class _DashboardDataError extends StatelessWidget {
  const _DashboardDataError({
    required this.message,
    required this.onRetry,
    this.error,
  });

  final String message;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: WebDashboardScreen._red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B241C),
                  ),
                ),
                if (error != null)
                  Text(
                    '$error',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B241C),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
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
              const Icon(Icons.calendar_today,
                  size: 18, color: Color(0xFF666666)),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
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
      _ChartData('Hold', hold, const Color(0xFF9E9E9E)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    Icon(Icons.inbox_outlined,
                        size: 48, color: Colors.grey.shade400),
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
                        maxY: data
                                .map((e) => e.value.toDouble())
                                .reduce((a, b) => a > b ? a : b) *
                            1.3,
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
                                final labels = [
                                  'Open',
                                  'In Progress',
                                  'Hold',
                                  'Closed'
                                ];
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
                            key: ValueKey('web-dashboard-status-${d.label}'),
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
    super.key,
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
                        horizontal: 8,
                        vertical: 3,
                      ),
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
      ..shader = topGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.4), topOverlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
