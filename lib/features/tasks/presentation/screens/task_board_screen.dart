import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/custom_menu_icon.dart';
import '../../../../web/theme/web_tokens.dart';
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
    if (role == UserRole.technician) {
      scoped = all.where(
        (t) => t.technicianId != null && t.technicianId == user?.backendId,
      );
    } else if (role == UserRole.client) {
      scoped = all.where(
        (t) => t.clientId != null && t.clientId == user?.backendId,
      );
    }

    final visible = scoped.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      return t.matchesQuery(_query);
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

    final title = role == UserRole.technician
        ? 'My Tasks'
        : role.isClientSide
            ? 'My Service Tasks'
            : role == UserRole.seniorTechnician
                ? 'Team Tasks'
                : 'Task Board';

    if (kIsWeb) {
      final searched = scoped.where((t) => t.matchesQuery(_query)).toList();
      return _webBuild(title, searched, visible, role, all, async);
    }

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
              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(title, visible.length, role),
                _searchBar(),
                _filters(),
                const SizedBox(height: 4),
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

  static const _webFilters = <(String, TaskStatus?, IconData, Color)>[
    ('All', null, Icons.dashboard_outlined, Color(0xFF106220)),
    ('Open', TaskStatus.open, Icons.radio_button_unchecked, Color(0xFF2E5AAC)),
    ('Hold', TaskStatus.hold, Icons.pause_circle_outline, Color(0xFFB7791F)),
    ('In Progress', TaskStatus.inProgress, Icons.timelapse, Color(0xFFE08600)),
    ('Closed', TaskStatus.closed, Icons.check_circle_outline, Color(0xFF0F766E)),
  ];

  Widget _webBuild(
    String title,
    List<TaskItem> searched,
    List<TaskItem> visible,
    UserRole role,
    List<TaskItem> all,
    AsyncValue<List<TaskItem>> async,
  ) {
    final Widget body = all.isEmpty && async.isLoading
        ? _loading()
        : all.isEmpty && async.hasError
            ? _error(async.error)
            : visible.isEmpty
                ? _empty()
                : _webList(visible, role);

    return Material(
      color: WebTokens.cream,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              children: [
                _webHeader(title, visible.length, role),
                const SizedBox(height: 18),
                _webStatusTiles(searched),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _green,
              onRefresh: () async {
                ref.invalidate(tasksProvider);
                await ref.read(tasksProvider.future);
              },
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _webHeader(String title, int count, UserRole role) {
    final canCreate = Permissions.canRaiseTasks(role);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WebTokens.line),
        boxShadow: WebTokens.softShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    WebTokens.mint.withValues(alpha: 0.55),
                    WebTokens.mint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: LayoutBuilder(
              builder: (context, c) {
                final heading = Row(
                  children: [
                    if (context.canPop()) ...[
                      _WebCircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [WebTokens.green, WebTokens.greenDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: WebTokens.green.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WebTokens.heading(22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: WebTokens.mintSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                  ],
                );
                final tools = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 300, child: _webSearch()),
                    if (canCreate) ...[
                      const SizedBox(width: 12),
                      _addPill(),
                    ],
                  ],
                );
                if (c.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 14), tools],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    tools,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _webSearch() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search Tasks',
        hintStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Color(0xFF9B9B9B),
        ),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9B9B9B)),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F8F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WebTokens.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.4),
        ),
      ),
    );
  }

  Widget _webStatusTiles(List<TaskItem> searched) {
    int countFor(TaskStatus? s) =>
        s == null ? searched.length : searched.where((t) => t.status == s).length;
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 900 ? 5 : (c.maxWidth >= 560 ? 3 : 2);
        final tileWidth = (c.maxWidth - 14 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final f in _webFilters)
              SizedBox(
                width: tileWidth,
                child: _WebStatusTile(
                  label: f.$1,
                  icon: f.$3,
                  color: f.$4,
                  count: countFor(f.$2),
                  selected: _statusFilter == f.$2,
                  onTap: () => setState(() => _statusFilter = f.$2),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _webList(List<TaskItem> visible, UserRole role) {
    const padding = EdgeInsets.fromLTRB(28, 10, 28, 32);
    if (_statusFilter != TaskStatus.open) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [_webGrid(visible, role)],
      );
    }
    final notAssigned = visible.where((t) => !t.hasAssignee).toList();
    final assigned = visible.where((t) => t.hasAssignee).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (notAssigned.isNotEmpty) ...[
          _sectionHeader('Not Assigned', notAssigned.length, const Color(0xFFD32F2F)),
          _webGrid(notAssigned, role),
          const SizedBox(height: 18),
        ],
        if (assigned.isNotEmpty) ...[
          _sectionHeader('Assigned', assigned.length, const Color(0xFFE08600)),
          _webGrid(assigned, role),
        ],
      ],
    );
  }

  Widget _webGrid(List<TaskItem> tasks, UserRole role) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1050 ? 3 : (c.maxWidth >= 680 ? 2 : 1);
        const gap = 20.0;
        final rows = <Widget>[];
        for (var i = 0; i < tasks.length; i += cols) {
          final cells = <Widget>[];
          for (var j = 0; j < cols; j++) {
            if (j > 0) cells.add(const SizedBox(width: gap));
            final k = i + j;
            cells.add(
              Expanded(
                child: k < tasks.length
                    ? _webTaskCard(tasks[k], role)
                    : const SizedBox.shrink(),
              ),
            );
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells,
                ),
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _webTaskCard(TaskItem t, UserRole role) {
    return _WebTaskCard(
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
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
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

  /// Rounded status chips with "All" first; the active chip is filled green.
  Widget _filters() {
    final chips = <MapEntry<String, TaskStatus?>>[
      const MapEntry('All', null),
      const MapEntry('Open', TaskStatus.open),
      const MapEntry('Hold', TaskStatus.hold),
      const MapEntry('In Progress', TaskStatus.inProgress),
      const MapEntry('Closed', TaskStatus.closed),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final sel = _statusFilter == chips[i].value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _statusFilter = chips[i].value),
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
              child: Text(
                chips[i].key,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF1F1F1F),
                ),
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
          _sectionHeader('Not Assigned', notAssigned.length, const Color(0xFFD32F2F)),
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

class _WebCircleButton extends StatelessWidget {
  const _WebCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: WebTokens.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: WebTokens.ink),
        ),
      ),
    );
  }
}

class _WebStatusTile extends StatefulWidget {
  const _WebStatusTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_WebStatusTile> createState() => _WebStatusTileState();
}

class _WebStatusTileState extends State<_WebStatusTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: sel ? c : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: sel ? c : (_hover ? c.withValues(alpha: 0.4) : WebTokens.line),
            ),
            boxShadow: [
              BoxShadow(
                color: (sel ? c : Colors.black)
                    .withValues(alpha: sel ? 0.25 : (_hover ? 0.07 : 0.04)),
                blurRadius: sel || _hover ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sel
                      ? Colors.white.withValues(alpha: 0.2)
                      : c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 20, color: sel ? Colors.white : c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : WebTokens.ink,
                      ),
                    ),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white.withValues(alpha: 0.9)
                            : WebTokens.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebTaskCard extends StatefulWidget {
  const _WebTaskCard({
    required this.task,
    required this.onTap,
    required this.onReport,
    this.onAssign,
    this.onToggleStar,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onReport;
  final VoidCallback? onAssign;
  final VoidCallback? onToggleStar;

  @override
  State<_WebTaskCard> createState() => _WebTaskCardState();
}

class _WebTaskCardState extends State<_WebTaskCard> {
  static const Color _green = Color(0xFF106220);
  static const Color _red = Color(0xFFD32F2F);
  static const String _fallbackImage = 'assets/images/task_img_1.png';

  bool _hover = false;

  static Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.open:
        return const Color(0xFF2E5AAC);
      case TaskStatus.hold:
        return const Color(0xFFB7791F);
      case TaskStatus.inProgress:
        return const Color(0xFFE08600);
      case TaskStatus.closed:
        return const Color(0xFF0F766E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isHighPriority =
        t.priority == TaskPriority.high || t.priority == TaskPriority.critical;
    final party = t.isIndividual ? t.contactName : t.companyName;
    final statusColor = _statusColor(t.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hover ? _green.withValues(alpha: 0.35) : WebTokens.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.05),
                blurRadius: _hover ? 28 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(t),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0x00000000)],
                          stops: [0, 0.5],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      right: 60,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _pill(t.lifecycleLabel, statusColor, dot: true),
                          if (t.isIndividual)
                            _pill('Individual', const Color(0xFF125420)),
                        ],
                      ),
                    ),
                    Positioned(right: 12, top: 10, child: _star(isHighPriority)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: WebTokens.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF125420), size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              party.isEmpty ? '-' : party,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF125420),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F9F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAF0EB)),
                        ),
                        child: Column(
                          children: [
                            if (t.isIndividual) ...[
                              _infoRow(Icons.place_outlined, 'Address', t.address),
                              _infoRow(Icons.person_outline, 'Contact', t.contactName),
                            ] else ...[
                              _infoRow(
                                Icons.precision_manufacturing_outlined,
                                'Equipment',
                                t.equipment,
                              ),
                              _infoRow(Icons.apartment_outlined, 'Company', t.companyName),
                            ],
                            _infoRow(Icons.tag, 'S.No', t.ticketNo),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Created At : ',
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  TextSpan(
                                    text: TaskBoardCard.formatDate(t.createdAt),
                                    style: const TextStyle(color: WebTokens.ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (t.isOverdue()) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 15, color: _red),
                              const SizedBox(width: 5),
                              Text(
                                'Overdue by ${-t.hoursToSla()}h',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _button('Report', filled: true, onTap: widget.onReport),
                          ),
                          if (widget.onAssign != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _button(
                                t.hasAssignee ? 'Reassign' : 'Assign',
                                filled: false,
                                onTap: widget.onAssign!,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(TaskItem t) {
    final fallback = Image.asset(
      _fallbackImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.build, size: 40, color: Colors.grey.shade400),
      ),
    );
    final url = t.imageUrl;
    final isPhoto = url.startsWith('http://') || url.startsWith('https://');
    return isPhoto ? taskImage(url, fallback: fallback) : fallback;
  }

  Widget _star(bool filled) {
    final star = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        filled ? Icons.star : Icons.star_border,
        color: filled ? Colors.amber : Colors.grey,
        size: 22,
      ),
    );
    if (widget.onToggleStar == null) return star;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggleStar,
      child: star,
    );
  }

  Widget _pill(String label, Color color, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: WebTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, {required bool filled, required VoidCallback onTap}) {
    return Material(
      color: filled ? _green : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: filled ? BorderSide.none : const BorderSide(color: _green, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : _green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
