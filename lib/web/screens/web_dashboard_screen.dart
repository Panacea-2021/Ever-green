import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/data/equipment_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_dashboard_colors.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_panel.dart';
import '../widgets/web_stat_card.dart';
import '../widgets/web_search_state.dart';
import '../widgets/web_table.dart';

/// Authenticated web dashboard — a desktop overview that reuses the same
/// providers as the mobile app (tasks, AMCs, equipment). Shown inside the web
/// module frame (side navigation + top bar).
class WebDashboardScreen extends ConsumerWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final unassigned = ref.watch(unassignedCountProvider);
    final renewals = ref.watch(amcRenewalsProvider);
    final equipmentCount = ref.watch(equipmentCountProvider);
    final role = ref.watch(currentUserRoleProvider);
    final searchQuery = ref.watch(webModuleSearchQueryProvider);

    bool pending(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;
    final tasksLoading = pending(ref.watch(taskItemsProvider));
    final companiesLoading = pending(ref.watch(companiesProvider));
    final equipmentLoading = pending(ref.watch(allEquipmentsProvider));

    final openCount = tasks.where((t) => t.status != TaskStatus.closed).length;

    VoidCallback? open(String route) =>
        Permissions.canAccessRoute(role, route) ? () => context.go(route) : null;

    final cards = [
      WebStatCard(
        label: 'Open Tasks',
        value: '$openCount',
        icon: Icons.checklist_rtl_outlined,
        accent: WebDashboardColors.primary,
        caption: '${tasks.length} total',
        onTap: open(Routes.tasks),
        loading: tasksLoading,
      ),
      WebStatCard(
        label: 'Overdue (SLA)',
        value: '${overdue.length}',
        icon: Icons.warning_amber_rounded,
        accent: WebDashboardColors.coral,
        caption: overdue.isEmpty ? 'All on track' : 'Needs attention',
        onTap: open(Routes.tasks),
        loading: tasksLoading,
      ),
      WebStatCard(
        label: 'Unassigned',
        value: '$unassigned',
        icon: Icons.person_off_outlined,
        accent: WebDashboardColors.amber,
        caption: 'In the queue',
        onTap: open(Routes.ticketQueue),
        loading: tasksLoading,
      ),
      WebStatCard(
        label: 'Renewals Due',
        value: '${renewals.length}',
        icon: Icons.autorenew,
        accent: WebDashboardColors.secondary,
        caption: 'AMC expiring/expired',
        onTap: open(Routes.amcRenewals),
        loading: companiesLoading,
      ),
      WebStatCard(
        label: 'Equipment',
        value: '$equipmentCount',
        icon: Icons.build_outlined,
        accent: WebDashboardColors.blue,
        caption: 'Under service',
        onTap: open(Routes.amcs),
        loading: equipmentLoading,
      ),
    ];
    final visibleCards = cards.where(
      (card) => matchesWebSearchTerms(searchQuery, [
        card.label,
        card.caption,
        card.value,
      ]),
    );

    return Scaffold(
      backgroundColor: WebDashboardColors.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    const gap = 16.0;
                    final cols = c.maxWidth >= 1000
                        ? 5
                        : c.maxWidth >= 640
                            ? 3
                            : c.maxWidth >= 420
                                ? 2
                                : 1;
                    final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final card in visibleCards)
                          SizedBox(width: cardW, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final table = _RecentTasks(
                      tasks: tasks,
                      query: searchQuery,
                      loading: tasksLoading,
                      onViewAll: open(Routes.tasks),
                    );
                    final panel = _RenewalsPanel(
                      renewals: renewals,
                      query: searchQuery,
                      loading: companiesLoading,
                      onViewAll: open(Routes.amcRenewals),
                    );
                    if (c.maxWidth < 1280) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [table, const SizedBox(height: 20), panel],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: table),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: panel),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTasks extends StatelessWidget {
  const _RecentTasks({
    required this.tasks,
    required this.query,
    required this.loading,
    this.onViewAll,
  });
  final List<TaskItem> tasks;
  final String query;
  final bool loading;
  final VoidCallback? onViewAll;

  Color _statusColor(TaskItem t) {
    if (t.isClosed) return WebDashboardColors.success;
    switch (t.status) {
      case TaskStatus.hold:
        return WebDashboardColors.amber;
      case TaskStatus.inProgress:
        return WebDashboardColors.secondary;
      case TaskStatus.open:
        return t.hasAssignee
            ? WebDashboardColors.amber
            : WebDashboardColors.coral;
      case TaskStatus.closed:
        return WebDashboardColors.success;
    }
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.critical => WebDashboardColors.coral,
        TaskPriority.high => WebDashboardColors.amber,
        TaskPriority.medium => WebDashboardColors.blue,
        TaskPriority.low => WebTokens.faint,
      };

  @override
  Widget build(BuildContext context) {
    final recent = [...tasks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visible = recent
        .where((task) => task.matchesAllQueryTerms(query))
        .take(8)
        .toList();

    return WebPanel(
      title: 'Recent Tasks',
      actionLabel: 'View all',
      onAction: onViewAll,
      child: WebTable(
        loading: loading,
        columns: const [
          WebColumn('Task', flex: 4),
          WebColumn('Company', flex: 5),
          WebColumn('Service Engineer', flex: 4),
          WebColumn('Status', flex: 3),
          WebColumn('Priority', flex: 3),
        ],
        onRowTap: (i) => context.push('${Routes.taskDetails}/${visible[i].id}'),
        rows: [
          for (final t in visible)
            [
              WebCellText(t.title, bold: true),
              WebCellText(t.companyName),
              WebCellText(t.hasAssignee ? t.assignee : 'Unassigned'),
              WebCellPill(t.lifecycleLabel, _statusColor(t)),
              WebCellPill(t.priority.label, _priorityColor(t.priority)),
            ],
        ],
      ),
    );
  }
}

class _RenewalsPanel extends StatelessWidget {
  const _RenewalsPanel({
    required this.renewals,
    required this.query,
    required this.loading,
    this.onViewAll,
  });
  final List<AmcContract> renewals;
  final String query;
  final bool loading;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final top = renewals
        .where(
          (contract) => matchesWebSearchTerms(query, [
            contract.companyName,
            contract.branchName,
            contract.pocName,
            contract.mobile,
            contract.email,
            contract.serviceType,
            contract.amcCategory,
          ]),
        )
        .take(5)
        .toList();
    return WebPanel(
      title: 'AMC Renewals Due',
      count: top.isEmpty ? null : top.length,
      actionLabel: top.isEmpty ? null : 'View all',
      onAction: onViewAll,
      padBody: true,
      child: loading
          ? Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: WebTokens.line,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: WebTokens.line,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : top.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(
                color: WebDashboardColors.accentSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: WebDashboardColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    query.isEmpty
                        ? 'No renewals due. Every contract is active.'
                        : 'No renewals match your search.',
                    textAlign: TextAlign.center,
                    style: WebTokens.bodyText(13.5, color: WebTokens.ink),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < top.length; i++)
                  _RenewalRow(contract: top[i], last: i == top.length - 1),
              ],
            ),
    );
  }
}

class _RenewalRow extends StatelessWidget {
  const _RenewalRow({required this.contract, required this.last});
  final AmcContract contract;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final expired = contract.status() == AmcStatus.expired;
    final accent = expired ? WebDashboardColors.coral : WebDashboardColors.amber;
    final days = contract.daysUntilExpiry();
    final sub = expired
        ? 'Expired ${-days} day${days == -1 ? '' : 's'} ago'
        : 'Expires in $days day${days == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.autorenew, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTokens.bodyText(
                    14,
                    color: WebTokens.ink,
                    weight: FontWeight.w700,
                    h: 1.3,
                  ),
                ),
                Text(sub, style: WebTokens.bodyText(12, color: accent, h: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
