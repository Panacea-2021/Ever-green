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

  String _query = '';
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

    final visible = scoped.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      return t.matchesQuery(_query);
    }).toList()
      ..sort((a, b) {
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
                  _toolbar(title, visible.length, role),
                  const SizedBox(height: 18),
                  _filters(),
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

  Widget _toolbar(String title, int count, UserRole role) {
    final canCreate = Permissions.canRaiseTasks(role);
    final search = SizedBox(
      height: 46,
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        style: WebTokens.bodyText(14, color: WebTokens.ink, h: 1.2),
        decoration: InputDecoration(
          hintText: 'Search Tasks',
          hintStyle: WebTokens.bodyText(14, color: WebTokens.faint, h: 1.2),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF9B9B9B), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WebTokens.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.4),
          ),
        ),
      ),
    );

    final trailing = canCreate
        ? SizedBox(
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
          )
        : null;

    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: WebTokens.heading(22)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: search),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            heading,
            const Spacer(),
            SizedBox(width: 340, child: search),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
          ],
        );
      },
    );
  }

  Widget _filters() {
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

  Widget _cardGrid(List<TaskItem> tasks, UserRole role) {
    return LayoutBuilder(
      builder: (context, c) {
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

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF106220);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1F1F1F),
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
