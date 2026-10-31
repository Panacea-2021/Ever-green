import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/router/routes.dart';
import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/data/equipment_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_panel.dart';
import '../widgets/web_stat_card.dart';
import '../widgets/web_table.dart';

/// Authenticated web dashboard — a desktop overview that reuses the same
/// providers as the mobile app (tasks, AMCs, equipment). Shown inside the web
/// module frame (side navigation + top bar).
class WebDashboardScreen extends ConsumerWidget {
  const WebDashboardScreen({super.key});

  static const _red = Color(0xFFD32F2F);
  static const _orange = Color(0xFFE08600);
  static const _blue = Color(0xFF1565C0);
  static const _purple = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final unassigned = ref.watch(unassignedCountProvider);
    final renewals = ref.watch(amcRenewalsProvider);
    final equipmentCount = ref.watch(equipmentCountProvider);
    final role = ref.watch(currentUserRoleProvider);

    final openCount = tasks.where((t) => t.status != TaskStatus.closed).length;

    VoidCallback? open(String route) =>
        Permissions.canAccessRoute(role, route) ? () => context.go(route) : null;

    final cards = [
      WebStatCard(
        label: 'Open Tasks',
        value: '$openCount',
        icon: Icons.checklist_rtl_outlined,
        accent: WebTokens.green,
        caption: '${tasks.length} total',
        onTap: open(Routes.tasks),
      ),
      WebStatCard(
        label: 'Overdue (SLA)',
        value: '${overdue.length}',
        icon: Icons.warning_amber_rounded,
        accent: _red,
        caption: overdue.isEmpty ? 'All on track' : 'Needs attention',
        onTap: open(Routes.tasks),
      ),
      WebStatCard(
        label: 'Unassigned',
        value: '$unassigned',
        icon: Icons.person_off_outlined,
        accent: _orange,
        caption: 'In the queue',
        onTap: open(Routes.ticketQueue),
      ),
      WebStatCard(
        label: 'Renewals Due',
        value: '${renewals.length}',
        icon: Icons.autorenew,
        accent: _blue,
        caption: 'AMC expiring/expired',
        onTap: open(Routes.amcRenewals),
      ),
      WebStatCard(
        label: 'Equipment',
        value: '$equipmentCount',
        icon: Icons.build_outlined,
        accent: _purple,
        caption: 'Under service',
        onTap: open(Routes.amcs),
      ),
    ];

    return Scaffold(
      backgroundColor: WebTokens.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: WebTokens.heading(22)),
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening across your service operations.",
                  style: WebTokens.bodyText(14),
                ),
                const SizedBox(height: 22),
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
                        for (final card in cards)
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
                      onViewAll: open(Routes.tasks),
                    );
                    final panel = _RenewalsPanel(
                      renewals: renewals,
                      onViewAll: open(Routes.amcRenewals),
                    );
                    if (c.maxWidth < 1000) {
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
  const _RecentTasks({required this.tasks, this.onViewAll});
  final List<TaskItem> tasks;
  final VoidCallback? onViewAll;

  Color _statusColor(TaskItem t) {
    if (t.isClosed) return WebTokens.green;
    switch (t.status) {
      case TaskStatus.hold:
        return const Color(0xFFE08600);
      case TaskStatus.inProgress:
        return const Color(0xFF1565C0);
      case TaskStatus.open:
        return t.hasAssignee
            ? const Color(0xFFE08600)
            : const Color(0xFFD32F2F);
      case TaskStatus.closed:
        return WebTokens.green;
    }
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.critical => const Color(0xFFD32F2F),
        TaskPriority.high => const Color(0xFFE08600),
        TaskPriority.medium => const Color(0xFF1565C0),
        TaskPriority.low => const Color(0xFF6B6B6B),
      };

  @override
  Widget build(BuildContext context) {
    final recent = [...tasks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top = recent.take(8).toList();

    return WebPanel(
      title: 'Recent Tasks',
      actionLabel: 'View all',
      onAction: onViewAll,
      child: WebTable(
        columns: const [
          WebColumn('Task', flex: 3),
          WebColumn('Company', flex: 3),
          WebColumn('Service Engineer', flex: 3),
          WebColumn('Status', flex: 2),
          WebColumn('Priority', flex: 2),
        ],
        onRowTap: (i) => context.push('${Routes.taskDetails}/${top[i].id}'),
        rows: [
          for (final t in top)
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
  const _RenewalsPanel({required this.renewals, this.onViewAll});
  final List<AmcContract> renewals;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final top = renewals.take(5).toList();
    return WebPanel(
      title: 'AMC Renewals Due',
      count: renewals.isEmpty ? null : renewals.length,
      actionLabel: renewals.isEmpty ? null : 'View all',
      onAction: onViewAll,
      padBody: true,
      child: top.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(
                color: WebTokens.mintSoft.withValues(alpha: 0.6),
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
                      color: WebTokens.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No renewals due. Every contract is active.',
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
    final accent = expired ? const Color(0xFFD32F2F) : const Color(0xFFE08600);
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
