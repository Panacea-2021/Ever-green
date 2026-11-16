import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../features/tasks/presentation/screens/task_board_screen.dart'
    show TaskBoardScope;
import '../../features/tasks/presentation/widgets/task_action_handler.dart';
import '../../features/tasks/presentation/widgets/task_workflow.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_filter_tiles.dart';
import '../widgets/web_table.dart';

/// Web layout of the Task Board: same scoping, filters, sorting, texts and
/// actions as the mobile board, laid out as a desktop toolbar + card grid.
class WebTaskBoardScreen extends ConsumerStatefulWidget {
  const WebTaskBoardScreen({super.key, this.initialStatus, this.scope});

  final TaskStatus? initialStatus;

  /// Optional personal scope (Super Admin "My Tasks" / "My Service Tasks"
  /// modules). Null keeps the default role-based board.
  final TaskBoardScope? scope;

  @override
  ConsumerState<WebTaskBoardScreen> createState() => _WebTaskBoardScreenState();
}

class _WebTaskBoardScreenState extends ConsumerState<WebTaskBoardScreen> {
  static const Color _green = Color(0xFF106220);
  static const Color _red = Color(0xFFD32F2F);
  static const Color _orange = Color(0xFFE08600);

  late TaskStatus? _statusFilter = widget.initialStatus;

  TaskActionHandler get _handler => TaskActionHandler(context, ref);

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(taskItemsProvider);
    final all = async.value ?? const <TaskItem>[];

    Iterable<TaskItem> scoped = all;
    if (widget.scope == TaskBoardScope.assignedToMe) {
      scoped = all.where(
        (t) => t.technicianId != null && t.technicianId == user?.backendId,
      );
    } else if (widget.scope == TaskBoardScope.raisedByMe) {
      scoped = all.where(
        (t) => t.clientId != null && t.clientId == user?.backendId,
      );
    } else if (role == UserRole.technician) {
      scoped = all.where(
        (t) => t.technicianId != null && t.technicianId == user?.backendId,
      );
    } else if (role == UserRole.client) {
      scoped = all.where(
        (t) => t.clientId != null && t.clientId == user?.backendId,
      );
    }

    final visible = scoped
        .where((t) => _statusFilter == null || t.status == _statusFilter)
        .toList()
      ..sort((a, b) {
        final ao = a.isOverdue() ? 1 : 0;
        final bo = b.isOverdue() ? 1 : 0;
        if (ao != bo) return bo - ao;
        if (a.priority.rank != b.priority.rank) {
          return b.priority.rank - a.priority.rank;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    Widget body;
    if (all.isEmpty && async.isLoading) {
      body = const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    } else if (all.isEmpty && async.hasError) {
      body = _error(async.error);
    } else if (visible.isEmpty) {
      body = _empty();
    } else {
      body = _grid(visible, role);
    }

    return Scaffold(
      backgroundColor: WebTokens.cream,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () async {
          ref.invalidate(tasksProvider);
          await ref.read(tasksProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _filters(scoped.toList())),
                      const SizedBox(width: 12),
                      _addButton(role),
                    ],
                  ),
                  const SizedBox(height: 22),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addButton(UserRole role) {
    if (!Permissions.canRaiseTasks(role)) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => context.push('${Routes.addTask}/new'),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: WebTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _filters(List<TaskItem> scoped) {
    const chips = <(String, TaskStatus?, IconData, Color)>[
      ('All', null, Icons.dashboard_outlined, Color(0xFF106220)),
      ('Open', TaskStatus.open, Icons.radio_button_unchecked, Color(0xFF2E5AAC)),
      ('Hold', TaskStatus.hold, Icons.pause_circle_outline, Color(0xFFB7791F)),
      ('In Progress', TaskStatus.inProgress, Icons.timelapse, Color(0xFFE08600)),
      ('Closed', TaskStatus.closed, Icons.check_circle_outline, Color(0xFF0F766E)),
    ];
    return WebFilterTiles(
      options: [
        for (final chip in chips)
          WebFilterOption(
            label: chip.$1,
            icon: chip.$3,
            color: chip.$4,
            count: scoped.isEmpty
                ? null
                : chip.$2 == null
                    ? scoped.length
                    : scoped.where((t) => t.status == chip.$2).length,
            selected: _statusFilter == chip.$2,
            onTap: () => setState(() => _statusFilter = chip.$2),
          ),
      ],
    );
  }

  Widget _grid(List<TaskItem> visible, UserRole role) {
    if (_statusFilter != TaskStatus.open) {
      return _cardGrid(visible, role);
    }
    final notAssigned = visible.where((t) => !t.hasAssignee).toList();
    final assigned = visible.where((t) => t.hasAssignee).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notAssigned.isNotEmpty) ...[
          _sectionHeader('Not Assigned', notAssigned.length, _red),
          _cardGrid(notAssigned, role),
          const SizedBox(height: 26),
        ],
        if (assigned.isNotEmpty) ...[
          _sectionHeader('Assigned', assigned.length, _orange),
          _cardGrid(assigned, role),
        ],
      ],
    );
  }

  Color _statusColor(TaskItem t) {
    if (t.isClosed) return _green;
    switch (t.status) {
      case TaskStatus.hold:
        return _orange;
      case TaskStatus.inProgress:
        return const Color(0xFF1565C0);
      case TaskStatus.open:
        return t.hasAssignee ? _orange : _red;
      case TaskStatus.closed:
        return _green;
    }
  }

  Widget _taskTable(List<TaskItem> tasks, UserRole role) {
    final user = ref.watch(currentUserProvider);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTokens.line),
        boxShadow: WebTokens.softShadow,
      ),
      child: WebTable(
        columns: const [
          WebColumn('Task', flex: 5),
          WebColumn('Company / Contact', flex: 5),
          WebColumn('Status', flex: 3),
          WebColumn('Created', flex: 3),
          WebColumn('', flex: 1),
          WebColumn('Actions', flex: 6),
        ],
        onRowTap: (i) => context.push('${Routes.taskDetails}/${tasks[i].id}'),
        rows: [
          for (final t in tasks)
            [
              _TaskCell(task: t),
              _PartyCell(task: t),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (t.isIndividual)
                    const WebCellPill('Individual', Color(0xFF6B6B6B)),
                  WebCellPill(t.lifecycleLabel, _statusColor(t)),
                ],
              ),
              _CreatedCell(task: t),
              _StarButton(
                filled: t.priority == TaskPriority.high ||
                    t.priority == TaskPriority.critical,
                onTap: canToggleTaskPriority(t, role)
                    ? () => _handler.togglePriority(t)
                    : null,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: _SmallButton(
                      label: 'Report',
                      filled: true,
                      onTap: () => _handler.serviceReport(t),
                    ),
                  ),
                  if (canAssignFromCard(t, role)) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: _SmallButton(
                        label: t.hasAssignee ? 'Reassign' : 'Assign',
                        filled: false,
                        onTap: () => _assign(t, reassign: t.hasAssignee),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  _TaskActionsMenu(
                    task: t,
                    user: user,
                    handler: _handler,
                    onAssign: () => _assign(t, reassign: t.hasAssignee),
                    onDeleted: () => ref.invalidate(tasksProvider),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget _cardGrid(List<TaskItem> tasks, UserRole role) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 900) return _taskTable(tasks, role);
        const gap = 18.0;
        final cols = c.maxWidth >= 1150
            ? 3
            : c.maxWidth >= 720
                ? 2
                : 1;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tasks)
              SizedBox(
                width: w,
                child: _WebTaskCard(
                  task: t,
                  onTap: () => context.push('${Routes.taskDetails}/${t.id}'),
                  onReport: () => _handler.serviceReport(t),
                  onAssign: canAssignFromCard(t, role)
                      ? () => _assign(t, reassign: t.hasAssignee)
                      : null,
                  onToggleStar: canToggleTaskPriority(t, role)
                      ? () => _handler.togglePriority(t)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _assign(TaskItem task, {required bool reassign}) async {
    final picked = await showDialog<(User, TechnicianStats)>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _WebAssignmentDialog(
        task: task,
        reassign: reassign,
      ),
    );
    if (picked == null || !mounted) return;

    final (tech, stats) = picked;
    if (stats.isOverloaded) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Service Engineer is busy',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '${tech.name} already has ${stats.active} active tasks. Assign anyway?',
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TaskDialogButtons([
              TaskDialogButton.cancel(
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              TaskDialogButton(
                label: 'Assign anyway',
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ]),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    await runTaskAction(
      context,
      () => ref.read(taskActionsProvider).assign(task, tech.backendId),
      success: reassign && task.hasAssignee
          ? 'Reassigned to ${tech.name}'
          : 'Assigned to ${tech.name}',
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: WebTokens.heading(16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: WebTokens.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    return _StateBox(
      icon: Icons.cloud_off_outlined,
      child: Column(
        children: [
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: WebTokens.bodyText(14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(tasksProvider),
            child: const Text('Retry', style: TextStyle(color: _green)),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return _StateBox(
      icon: Icons.inbox_outlined,
      child: Text(
        'No tasks found',
        style: WebTokens.bodyText(
          16,
          color: const Color(0xFF6B6B6B),
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskCell extends StatelessWidget {
  const _TaskCell({required this.task});
  final TaskItem task;

  static const String _fallbackImage = 'assets/images/task_img_1.png';

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      _fallbackImage,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.build, size: 18, color: Colors.grey.shade400),
      ),
    );
    final url = task.imageUrl;
    final isPhoto = url.startsWith('http://') || url.startsWith('https://');
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: isPhoto ? taskImage(url, fallback: fallback) : fallback,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WebCellText(
            task.title,
            bold: true,
            subtitle: task.ticketNo.isEmpty ? null : 'S.No ${task.ticketNo}',
          ),
        ),
      ],
    );
  }
}

/// Company (or contact for Individual tasks) with the equipment (or address)
/// beneath, each with an icon and up to two lines so names are not cut off.
class _PartyCell extends StatelessWidget {
  const _PartyCell({required this.task});
  final TaskItem task;

  static const Color _darkGreen = Color(0xFF125420);

  @override
  Widget build(BuildContext context) {
    final t = task;
    final name = t.isIndividual ? t.contactName : t.companyName;
    final detail = t.isIndividual ? t.address : t.equipment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(
          t.isIndividual ? Icons.person_outline : Icons.business_outlined,
          name.isEmpty ? '-' : name,
          WebTokens.bodyText(
            13.5,
            color: _darkGreen,
            weight: FontWeight.w700,
            h: 1.3,
          ),
          _darkGreen,
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          _line(
            t.isIndividual ? Icons.location_on_outlined : Icons.build_outlined,
            detail,
            WebTokens.bodyText(12, color: WebTokens.body, h: 1.35),
            WebTokens.faint,
          ),
        ],
      ],
    );
  }

  Widget _line(IconData icon, String text, TextStyle style, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Tooltip(
            message: text,
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatedCell extends StatelessWidget {
  const _CreatedCell({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final d = task.createdAt.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WebCellText(date),
        if (task.isOverdue()) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  'Overdue by ${-task.hoursToSla()}h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WebTokens.bodyText(
                    11.5,
                    color: const Color(0xFFD32F2F),
                    weight: FontWeight.w600,
                    h: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({required this.filled, this.onTap});
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.star : Icons.star_border,
      color: filled ? Colors.amber : Colors.grey,
      size: 21,
    );
    if (onTap == null) return Align(alignment: Alignment.centerLeft, child: icon);
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: icon,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF106220);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? _green : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: filled ? null : Border.all(color: _green, width: 1.3),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : _green,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTokens.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Desktop task card: same fields, labels, colours and actions as the mobile
/// Task Board card, arranged for a grid.
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
  static const Color _darkGreen = Color(0xFF125420);
  static const Color _red = Color(0xFFD32F2F);
  static const String _fallbackImage = 'assets/images/task_img_1.png';

  bool _hover = false;

  static String _formatDate(DateTime date) {
    final d = date.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isHighPriority =
        t.priority == TaskPriority.high || t.priority == TaskPriority.critical;
    final party = t.isIndividual ? t.contactName : t.companyName;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover ? _green.withValues(alpha: 0.35) : WebTokens.line,
            ),
            boxShadow: _hover ? WebTokens.cardShadow : WebTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(t),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: WebTokens.fontFamily,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            _star(isHighPriority),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: _darkGreen,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                party.isEmpty ? '-' : party,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: WebTokens.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (t.isIndividual) _pill('Individual', dot: false),
                            _pill(t.lifecycleLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (t.isIndividual) ...[
                      _infoRow('Address', t.address),
                      const SizedBox(height: 6),
                      _infoRow('Contact', t.contactName),
                    ] else ...[
                      _infoRow('Equipment', t.equipment),
                      const SizedBox(height: 6),
                      _infoRow('Company', t.companyName),
                    ],
                    const SizedBox(height: 6),
                    _infoRow('S.No', t.ticketNo),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: WebTokens.fontFamily,
                          fontSize: 12.5,
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
                            text: _formatDate(t.createdAt),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (t.isOverdue()) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: _red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Overdue by ${-t.hoursToSla()}h',
                      style: const TextStyle(
                        fontFamily: WebTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _red,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _button(
                      'Report',
                      filled: true,
                      onTap: widget.onReport,
                    ),
                  ),
                  if (widget.onAssign != null) ...[
                    const SizedBox(width: 10),
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
    );
  }

  Widget _image(TaskItem t) {
    final fallback = Image.asset(
      _fallbackImage,
      width: 92,
      height: 92,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.build, size: 34, color: Colors.grey.shade400),
      ),
    );
    final url = t.imageUrl;
    final isPhoto = url.startsWith('http://') || url.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 92,
        height: 92,
        child: isPhoto ? taskImage(url, fallback: fallback) : fallback,
      ),
    );
  }

  Widget _star(bool filled) {
    final icon = Icon(
      filled ? Icons.star : Icons.star_border,
      color: filled ? Colors.amber : Colors.grey,
      size: 22,
    );
    if (widget.onToggleStar == null) {
      return Padding(padding: const EdgeInsets.only(left: 6), child: icon);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggleStar,
      child: Padding(padding: const EdgeInsets.only(left: 6), child: icon),
    );
  }

  Widget _pill(String label, {bool dot = true}) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0EA),
        borderRadius: BorderRadius.circular(48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _darkGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Icon(
          Icons.description_outlined,
          color: Colors.black.withValues(alpha: 0.4),
          size: 14,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: WebTokens.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: value.isEmpty ? '-' : value,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _button(
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? _green : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: _green, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : _green,
            ),
          ),
        ),
      ),
    );
  }
}

/// 3-dots action menu for task rows in the table view.
/// Shows all available actions based on user role and task state.
class _TaskActionsMenu extends StatelessWidget {
  const _TaskActionsMenu({
    required this.task,
    required this.user,
    required this.handler,
    required this.onAssign,
    required this.onDeleted,
  });

  final TaskItem task;
  final User? user;
  final TaskActionHandler handler;
  final VoidCallback onAssign;
  final VoidCallback onDeleted;

  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final actions = taskButtonsFor(task, user);
    // Filter out serviceReport since it's already shown as a button
    final menuActions = actions
        .where((b) => b.action != TaskAction.serviceReport)
        .toList();

    // Add delete action if user can delete (Super Admin / Manager)
    final role = user?.role ?? UserRole.client;
    final canDelete = role == UserRole.superAdmin || role == UserRole.manager;

    return PopupMenuButton<TaskAction>(
      icon: const Icon(
        Icons.more_vert,
        color: Color(0xFF5A6B5E),
        size: 22,
      ),
      tooltip: 'More actions',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      itemBuilder: (context) => [
        // Header
        PopupMenuItem<TaskAction>(
          enabled: false,
          height: 42,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.settings, color: _green, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Actions',
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14201A),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Action items
        for (final button in menuActions)
          PopupMenuItem<TaskAction>(
            value: button.action,
            height: 44,
            child: _ActionMenuItem(
              icon: button.action.icon,
              label: button.action.label,
              color: button.kind == TaskButtonKind.danger ? _danger : null,
            ),
          ),
        // Add delete if allowed and not already in the list
        if (canDelete &&
            !menuActions.any((b) => b.action == TaskAction.delete)) ...[
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<TaskAction>(
            value: TaskAction.delete,
            height: 44,
            child: const _ActionMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete Task',
              color: _danger,
            ),
          ),
        ],
      ],
      onSelected: (action) {
        if (action == TaskAction.assign || action == TaskAction.reassign) {
          onAssign();
        } else {
          handler.run(task, action, onDeleted: onDeleted);
        }
      },
    );
  }
}

/// Single menu item row with icon and label.
class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF3A4A3E);
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c,
            ),
          ),
        ),
      ],
    );
  }
}

class _WebAssignmentDialog extends ConsumerWidget {
  const _WebAssignmentDialog({
    required this.task,
    required this.reassign,
  });

  final TaskItem task;
  final bool reassign;

  static const Color _green = Color(0xFF106220);
  static const Color _ink = Color(0xFF14201A);
  static const Color _muted = Color(0xFF6B6B6B);
  static const Color _danger = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        key: const ValueKey('web-task-assignment-dialog-card'),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reassign
                              ? 'Reassign Service Engineer'
                              : 'Assign Service Engineer',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        if (reassign && task.hasAssignee) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Currently: ${task.assignee}',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TechnicianChoices(
                  builder: (techs, stats) => Column(
                    children: [
                      for (final tech in techs)
                        _technicianTile(
                          context,
                          tech,
                          statsFor(tech, stats),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: Color(0xFFD8D8D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _technicianTile(
    BuildContext context,
    User tech,
    TechnicianStats stats,
  ) {
    final isCurrent = tech.backendId == task.technicianId;
    final isBusy = stats.isOverloaded;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      enabled: !isCurrent,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEBF0EA),
        child: Text(
          tech.name.isNotEmpty ? tech.name[0] : '?',
          style: const TextStyle(color: _green, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        tech.name,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isCurrent ? 'Current assignee' : '${stats.active} active task(s)',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          color: isBusy ? _danger : _muted,
        ),
      ),
      trailing: isCurrent
          ? const Icon(Icons.check, color: _green)
          : isBusy
              ? const Text(
                  'Busy',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: _danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
      onTap: isCurrent ? null : () => Navigator.pop(context, (tech, stats)),
    );
  }
}
