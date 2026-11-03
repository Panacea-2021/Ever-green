import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/count_badge.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/custom_menu_icon.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../widgets/task_action_handler.dart';
import '../widgets/task_board_card.dart';
import '../widgets/task_workflow.dart';

/// A role-aware task board backed by [taskItemsProvider]. Cards carry Report
/// and Assign / Reassign; every other workflow action lives on Task Details.
///
/// - Super Admin / Manager: full board, assign, priority star
/// - Senior Technician: team board, assign, priority star
/// - Technician: only tasks assigned to them
/// - Client: tasks raised for them (Client Admin: their company's)
class TaskBoardScreen extends ConsumerStatefulWidget {
  /// When true the screen is rendered as the root "Tasks" bottom-nav tab:
  /// it shows a drawer menu button instead of a back arrow and provides the
  /// app drawer. When false (pushed), it shows a back arrow.
  final bool isRootTab;

  /// Tab selected when the screen opens (null = All).
  final TaskStatus? initialStatus;

  const TaskBoardScreen({
    super.key,
    this.isRootTab = false,
    this.initialStatus,
  });

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  static const Color _green = Color(0xFF106220);
  String _query = '';
  late TaskStatus? _statusFilter = widget.initialStatus;

  /// The "Deleted" chip (Super Admin / Manager) lists soft-deleted tickets.
  bool _deletedTab = false;

  TaskActionHandler get _handler => TaskActionHandler(
        context,
        ref,
        bottomInset: widget.isRootTab
            ? ScaffoldWithBottomNav.bottomInset(context)
            : 12.0,
      );

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(taskItemsProvider);
    final all = async.value ?? const <TaskItem>[];

    Iterable<TaskItem> scoped = all;
    if (role.isTechnicianLevel && role != UserRole.seniorTechnician) {
      scoped = all.where(
        (t) => t.technicianId != null && t.technicianId == user?.backendId,
      );
    } else if (role == UserRole.client) {
      scoped = all.where(
        (t) => t.clientId != null && t.clientId == user?.backendId,
      );
    }

    final searched = scoped.where((t) => t.matchesQuery(_query)).toList();
    final visible = searched.where((t) {
      return _statusFilter == null || t.status == _statusFilter;
    }).toList()
      ..sort((a, b) {
        // Overdue first, then priority, then newest.
        final ao = a.isOverdue() ? 1 : 0;
        final bo = b.isOverdue() ? 1 : 0;
        if (ao != bo) return bo - ao;
        if (a.priority.rank != b.priority.rank) {
          return b.priority.rank - a.priority.rank;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    final canSeeDeleted =
        role == UserRole.superAdmin || role == UserRole.manager;
    final showDeleted = canSeeDeleted && _deletedTab;
    final deletedCount = canSeeDeleted
        ? ref
            .watch(deletedTasksProvider)
            .valueOrNull
            ?.map(TaskItem.fromService)
            .where((t) => t.matchesQuery(_query))
            .length
        : null;
    final loaded = async.hasValue;
    final counts = <String, int?>{
      'All': loaded ? searched.length : null,
      for (final (label, status) in _statusChips)
        label: loaded ? searched.where((t) => t.status == status).length : null,
      _deletedLabel: deletedCount,
    };
    final selectedLabel = showDeleted
        ? _deletedLabel
        : _statusFilter == null
            ? 'All'
            : _statusChips.firstWhere((c) => c.$2 == _statusFilter).$1;
    final selectedCount = counts[selectedLabel];

    final title = role.isTechnicianLevel && role != UserRole.seniorTechnician
        ? 'My Tasks'
        : role.isClientSide
            ? 'My Service Tasks'
            : role == UserRole.seniorTechnician
                ? 'Team Tasks'
                : 'Task Board';

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: widget.isRootTab ? const AppDrawer() : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.7),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.white),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(title, visible.length, role),
                _searchBar(),
                _filters(canSeeDeleted, counts),
                const SizedBox(height: 4),
                if (selectedCount != null) ...[
                  CountHeader(
                    key: const Key('taskCountHeader'),
                    label: selectedLabel == 'All'
                        ? 'All Tasks'
                        : '$selectedLabel Tasks',
                    count: selectedCount,
                  ),
                  const SizedBox(height: 6),
                ],
                if (showDeleted)
                  Expanded(child: _deletedList())
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: _green,
                      onRefresh: () async {
                        ref.invalidate(tasksProvider);
                        await ref.read(tasksProvider.future);
                      },
                      child: all.isEmpty && async.isLoading
                          ? _loading()
                          : all.isEmpty && async.hasError
                              ? _error(async.error)
                              : visible.isEmpty
                                  ? _empty()
                                  : _buildList(visible, role),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title, int count, UserRole role) {
    final canCreate = Permissions.canRaiseTasks(role);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => widget.isRootTab
                ? CustomMenuIcon(onTap: () => Scaffold.of(ctx).openDrawer())
                : GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
          if (canCreate)
            _addPill()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Green outlined "Add +" pill.
  Widget _addPill() {
    return GestureDetector(
      onTap: () => context.push('${Routes.addTask}/new'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _green, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _green,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration:
                  const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search Tasks',
            prefixIcon: Icon(Icons.search, color: Color(0xFF9B9B9B)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
        ),
      ),
    );
  }

  static const _statusChips = <(String, TaskStatus)>[
    ('Open', TaskStatus.open),
    ('Hold', TaskStatus.hold),
    ('In Progress', TaskStatus.inProgress),
    ('Closed', TaskStatus.closed),
  ];

  /// Rounded status chips with "All" first, then "Deleted" for
  /// [canSeeDeleted]; the active chip is filled green. Each shows its
  /// [counts] entry once loaded.
  Widget _filters(bool canSeeDeleted, Map<String, int?> counts) {
    final chips = <MapEntry<String, TaskStatus?>>[
      const MapEntry('All', null),
      for (final (label, status) in _statusChips) MapEntry(label, status),
      if (canSeeDeleted) const MapEntry(_deletedLabel, null),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isDeletedChip = chips[i].key == _deletedLabel;
          final sel = isDeletedChip
              ? _deletedTab
              : !_deletedTab && _statusFilter == chips[i].value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _deletedTab = isDeletedChip;
              if (!isDeletedChip) _statusFilter = chips[i].value;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel ? _green : const Color(0xFFE0E0E0),
                  width: 1.2,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chips[i].key,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF1F1F1F),
                    ),
                  ),
                  if (counts[chips[i].key] != null) ...[
                    const SizedBox(width: 6),
                    CountBadge(
                      counts[chips[i].key]!,
                      key: Key('taskStatusCount-${chips[i].key}'),
                      onDark: sel,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The list body. In the Open tab, tasks are split into "Not Assigned" and
  /// "Assigned" sections so the full open workload is visible at a glance.
  Widget _buildList(List<TaskItem> visible, UserRole role) {
    final bottomPad =
        widget.isRootTab ? ScaffoldWithBottomNav.bottomInset(context) : 24.0;
    final padding = EdgeInsets.fromLTRB(17, 8, 17, bottomPad);

    if (_statusFilter != TaskStatus.open) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: visible.length,
        itemBuilder: (_, i) => _taskCard(visible[i], role),
      );
    }

    final notAssigned = visible.where((t) => !t.hasAssignee).toList();
    final assigned = visible.where((t) => t.hasAssignee).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (notAssigned.isNotEmpty) ...[
          _sectionHeader(
              'Not Assigned', notAssigned.length, const Color(0xFFD32F2F)),
          for (final t in notAssigned) _taskCard(t, role),
        ],
        if (assigned.isNotEmpty) ...[
          _sectionHeader('Assigned', assigned.length, const Color(0xFFE08600)),
          for (final t in assigned) _taskCard(t, role),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(TaskItem t, UserRole role) {
    return TaskBoardCard(
      task: t,
      onTap: () => context.push('${Routes.taskDetails}/${t.id}'),
      onReport: () => _handler.serviceReport(t),
      onAssign: canAssignFromCard(t, role)
          ? () => _handler.assign(t, reassign: t.hasAssignee)
          : null,
      onToggleStar: canToggleTaskPriority(t, role)
          ? () => _handler.togglePriority(t)
          : null,
    );
  }

  static const String _deletedLabel = 'Deleted';

  Widget _deletedList() {
    final async = ref.watch(deletedTasksProvider);
    final tasks = (async.valueOrNull ?? const [])
        .map(TaskItem.fromService)
        .where((t) => t.matchesQuery(_query))
        .toList()
      ..sort((a, b) {
        final ad = a.source?.deletedAt ?? a.createdAt;
        final bd = b.source?.deletedAt ?? b.createdAt;
        return bd.compareTo(ad);
      });
    final bottomPad =
        widget.isRootTab ? ScaffoldWithBottomNav.bottomInset(context) : 24.0;
    return RefreshIndicator(
      color: _green,
      onRefresh: () async {
        ref.invalidate(deletedTasksProvider);
        await ref.read(deletedTasksProvider.future);
      },
      child: !async.hasValue && async.isLoading
          ? _loading()
          : !async.hasValue && async.hasError
              ? _error(async.error)
              : tasks.isEmpty
                  ? _empty()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(17, 8, 17, bottomPad),
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => DeletedTaskCard(task: tasks[i]),
                    ),
    );
  }

  Widget _loading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: _green)),
      ],
    );
  }

  Widget _error(Object? error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF6B6B6B),
          ),
        ),
        TextButton(
          onPressed: () => ref.invalidate(tasksProvider),
          child: const Text('Retry', style: TextStyle(color: _green)),
        ),
      ],
    );
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No tasks found',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ),
      ],
    );
  }
}

/// A soft-deleted ticket: ticket ID, what it was, who deleted it, when, and
/// why.
class DeletedTaskCard extends StatelessWidget {
  final TaskItem task;
  const DeletedTaskCard({super.key, required this.task});

  static String _fmt(DateTime? d) {
    if (d == null) return '-';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}-${two(l.month)}-${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = task;
    final s = t.source;
    const label = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 12,
      color: Color(0xFF6B6B6B),
    );
    const value = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1F1F1F),
    );
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(k, style: label)),
              Expanded(child: Text(v.isEmpty ? '-' : v, style: value)),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2C4C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFD32F2F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          row('Ticket ID', t.ticketNo),
          row(t.isIndividual ? 'For' : 'Company', t.partyName),
          if (!t.isIndividual) row('Equipment', t.equipment),
          row('Issue type', s?.issueTypeLabel ?? ''),
          row('Deleted by', s?.deletedByName ?? ''),
          row('Deleted on', _fmt(s?.deletedAt)),
          row('Reason', s?.deleteReason ?? ''),
        ],
      ),
    );
  }
}
