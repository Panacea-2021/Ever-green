import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/data/equipment_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../core/router/routes.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_app_shell.dart';
import '../widgets/web_stat_card.dart';
import '../widgets/web_table.dart';

/// Authenticated web dashboard — a desktop overview that reuses the same
/// providers as the mobile app (tasks, AMCs, equipment). Completely different
/// layout from the phone home screen.
class WebDashboardScreen extends ConsumerWidget {
  const WebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final unassigned = ref.watch(unassignedCountProvider);
    final renewals = ref.watch(amcRenewalsProvider);
    final equipmentCount = ref.watch(equipmentCountProvider);

    final openCount = tasks.where((t) => t.status != TaskStatus.closed).length;

    return WebAppShell(
      activeRoute: Routes.webDashboard,
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: WebTokens.heading(18)),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening across your service operations.",
            style: WebTokens.bodyText(14),
          ),
          const SizedBox(height: 24),

          // KPI grid.
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth < 700
                  ? 1
                  : c.maxWidth < 1050
                      ? 2
                      : 5;
              const gap = 18.0;
              final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
              final cards = [
                WebStatCard(
                  label: 'Open Tasks',
                  value: '$openCount',
                  icon: Icons.checklist_rtl_outlined,
                  accent: WebTokens.green,
                  caption: '${tasks.length} total',
                ),
                WebStatCard(
                  label: 'Overdue (SLA)',
                  value: '${overdue.length}',
                  icon: Icons.warning_amber_rounded,
                  accent: const Color(0xFFD32F2F),
                  caption: overdue.isEmpty ? 'All on track' : 'Needs attention',
                ),
                WebStatCard(
                  label: 'Unassigned',
                  value: '$unassigned',
                  icon: Icons.person_off_outlined,
                  accent: const Color(0xFFE08600),
                  caption: 'In the queue',
                ),
                WebStatCard(
                  label: 'Renewals Due',
                  value: '${renewals.length}',
                  icon: Icons.autorenew,
                  accent: const Color(0xFF1565C0),
                  caption: 'AMC expiring/expired',
                ),
                WebStatCard(
                  label: 'Equipment',
                  value: '$equipmentCount',
                  icon: Icons.build_outlined,
                  accent: const Color(0xFF6A1B9A),
                  caption: 'Under service',
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
          ),
          const SizedBox(height: 28),

          // Content: recent tasks (wide) + renewals panel (narrow).
          LayoutBuilder(
            builder: (context, c) {
              final stack = c.maxWidth < 1000;
              final table = _RecentTasks(tasks: tasks);
              final panel = _RenewalsPanel(renewals: renewals);
              if (stack) {
                return Column(
                  children: [
                    table,
                    const SizedBox(height: 20),
                    panel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: table),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: panel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentTasks extends StatelessWidget {
  const _RecentTasks({required this.tasks});
  final List<TaskItem> tasks;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Tasks', style: WebTokens.heading(17)),
        const SizedBox(height: 14),
        WebTable(
          columns: const [
            WebColumn('Task', flex: 3),
            WebColumn('Company', flex: 2),
            WebColumn('Service Engineer', flex: 2),
            WebColumn('Status', flex: 2),
            WebColumn('Priority', flex: 2),
          ],
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
      ],
    );
  }
}

class _RenewalsPanel extends StatelessWidget {
  const _RenewalsPanel({required this.renewals});
  final List<AmcContract> renewals;

  @override
  Widget build(BuildContext context) {
    final top = renewals.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AMC Renewals Due', style: WebTokens.heading(17)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: WebTokens.softShadow,
          ),
          child: Column(
            children: [
              if (top.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No renewals due. Every contract is active.',
                    style: WebTokens.bodyText(13.5),
                  ),
                )
              else
                for (var i = 0; i < top.length; i++)
                  _RenewalRow(
                    contract: top[i],
                    last: i == top.length - 1,
                  ),
            ],
          ),
        ),
      ],
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
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.companyName,
                  style: WebTokens.bodyText(
                    14,
                    color: WebTokens.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(sub, style: WebTokens.bodyText(12, color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
