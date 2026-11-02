import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/tasks/data/task_provider.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../features/tasks/presentation/widgets/task_action_handler.dart';
import '../../features/tasks/presentation/widgets/task_workflow.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_table.dart';

/// Web layout of the Task Board: same scoping, filters, sorting, texts and
/// actions as the mobile board, laid out as a desktop toolbar + card grid.
class WebTaskBoardScreen extends ConsumerStatefulWidget {
  const WebTaskBoardScreen({super.key, this.initialStatus});

  final TaskStatus? initialStatus;

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
    if (role == UserRole.technician) {
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
    final chips = <MapEntry<String, TaskStatus?>>[
      const MapEntry('All', null),
      const MapEntry('Open', TaskStatus.open),
      const MapEntry('Hold', TaskStatus.hold),
      const MapEntry('In Progress', TaskStatus.inProgress),
      const MapEntry('Closed', TaskStatus.closed),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WebTokens.line),
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final chip in chips)
              _FilterTab(
                label: chip.key,
                count: scoped.isEmpty
                    ? null
                    : chip.value == null
                        ? scoped.length
                        : scoped.where((t) => t.status == chip.value).length,
                selected: _statusFilter == chip.value,
                onTap: () => setState(() => _statusFilter = chip.value),
              ),
          ],
        ),
      ),
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
          WebColumn('Actions', flex: 4),
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
                  Expanded(
                    child: _SmallButton(
                      label: 'Report',
                      filled: true,
                      onTap: () => _handler.serviceReport(t),
                    ),
                  ),
                  if (canAssignFromCard(t, role)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallButton(
                        label: t.hasAssignee ? 'Reassign' : 'Assign',
                        filled: false,
                        onTap: () =>
                            _handler.assign(t, reassign: t.hasAssignee),
                      ),
                    ),
                  ],
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
                      ? () => _handler.assign(t, reassign: t.hasAssignee)
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

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  static const Color _green = Color(0xFF106220);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1F1F1F),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : WebTokens.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : WebTokens.body,
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
