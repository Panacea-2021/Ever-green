import 'package:flutter/material.dart';

import '../../domain/models/task_item.dart';
import 'task_workflow.dart' show taskImage;

/// Reusable task card matching the Figma "Tasks" design: a square equipment
/// thumbnail on the left, title + category (wrench) + status pill, icon rows
/// for Service Engineer / Company (Address for individual tickets) / Ticket
/// No, and a light-green "Created At" footer.
///
/// Used across the task list screens (Task Board, Assign Tasks, Technician
/// Tasks). An optional [trailing] widget sits on the title row (e.g. a small
/// Assign button); an optional [actions] widget renders below the footer
/// (e.g. the Task Board's role-aware action buttons). [onTap] makes the whole
/// card tappable with press feedback.
class TaskListCard extends StatefulWidget {
  final TaskItem task;
  final Widget? trailing;
  final Widget? actions;
  final VoidCallback? onTap;

  /// When set, a 3-dots overflow button is shown in the card's top-right
  /// corner. The callback receives the global position of the tap so the
  /// caller can anchor a floating popup menu next to the dots.
  final void Function(Offset globalPosition)? onMenu;

  const TaskListCard({
    super.key,
    required this.task,
    this.trailing,
    this.actions,
    this.onTap,
    this.onMenu,
  });

  @override
  State<TaskListCard> createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  static const Color _green = Color(0xFF106220);
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final tappable = widget.onTap != null;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: t.isClosed ? _closedCard(t) : _standardCard(t),
      ),
    );
  }

  /// The default card (open / hold / in-progress): thumbnail + details,
  /// green "Created At" footer, priority/escalated, optional actions.
  Widget _standardCard(TaskItem t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.9),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  // Extra right padding so the title never runs under the
                  // top-right chevron.
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumbnail(t),
                      const SizedBox(width: 12),
                      Expanded(child: _details(t)),
                    ],
                  ),
                ),
                _footer(t),
                if (widget.actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: widget.actions!,
                  ),
              ],
            ),
            // Top-right green circle-chevron + optional 3-dots menu.
            Positioned(right: 10, top: 12, child: _topRightControls()),
          ],
        ),
      ),
    );
  }

  /// The top-right corner control: the 3-dots overflow button (when
  /// [TaskListCard.onMenu] is provided). The green circle-chevron was removed.
  Widget _topRightControls() {
    if (widget.onMenu == null) return const SizedBox.shrink();
    Offset tapPos = Offset.zero;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => tapPos = d.globalPosition,
      onTap: () => widget.onMenu?.call(tapPos),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(
          Icons.more_vert,
          size: 20,
          color: Color(0xFF6B6B6B),
        ),
      ),
    );
  }

  /// The Figma "Closed" card variant: no footer / priority / actions, a
  /// filled green circle-chevron in the top-right, and a diagonal red
  /// "CLOSED" rubber-stamp overlapping the bottom-right.
  Widget _closedCard(TaskItem t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.9),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumbnail(t),
                      const SizedBox(width: 12),
                      Expanded(child: _details(t)),
                    ],
                  ),
                ),
                if (widget.actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: widget.actions!,
                  ),
              ],
            ),
            // Diagonal red CLOSED stamp — the exported asset has a white
            // background, so multiply-blend it to keep only the red ink.
            Positioned(
              right: -6,
              bottom: 2,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.22,
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      'assets/images/closed_stamp.png',
                      width: 136,
                      colorBlendMode: BlendMode.multiply,
                      color: Colors.white,
                      errorBuilder: (_, __, ___) => _stampFallback(),
                    ),
                  ),
                ),
              ),
            ),
            // Top-right circular chevron + optional 3-dots menu.
            Positioned(right: 10, top: 12, child: _topRightControls()),
          ],
        ),
      ),
    );
  }

  /// Text-badge fallback if the stamp image is missing.
  Widget _stampFallback() {
    return Transform.rotate(
      angle: -0.22,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD32F2F), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'CLOSED',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Color(0xFFD32F2F),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(TaskItem t) {
    final hasPhoto = t.imageUrl.isNotEmpty &&
        !t.imageUrl.endsWith('login_bg.png') &&
        !t.imageUrl.endsWith('home_bg.png');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 78,
        height: 78,
        child: hasPhoto
            ? taskImage(t.imageUrl, fallback: _thumbPlaceholder(t))
            : _thumbPlaceholder(t),
      ),
    );
  }

  Widget _thumbPlaceholder(TaskItem t) {
    return Container(
      color: const Color(0xFFEBF0EA),
      child: Icon(
        t.isIndividual ? Icons.person_outline : _categoryIcon(t.equipment),
        color: _green,
        size: 30,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('micro')) return Icons.microwave;
    if (c.contains('fridge') ||
        c.contains('refriger') ||
        c.contains('freezer')) {
      return Icons.kitchen;
    }
    if (c.contains('ac') || c.contains('air') || c.contains('condition')) {
      return Icons.ac_unit;
    }
    if (c.contains('wash')) return Icons.local_laundry_service;
    if (c.contains('water') || c.contains('cooler')) return Icons.water_drop;
    if (c.contains('chiller')) return Icons.ac_unit;
    if (c.contains('fan') || c.contains('vent')) return Icons.air;
    return Icons.handyman;
  }

  Widget _details(TaskItem t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                // Leave room for the top-right 3-dots menu.
                padding: EdgeInsets.only(right: widget.onMenu != null ? 30 : 4),
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
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (t.isIndividual) ...[
              _individualPill(),
              const SizedBox(width: 6),
            ] else ...[
              const Icon(Icons.build, size: 15, color: _green),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                t.isIndividual
                    ? (t.contactName.isEmpty ? '-' : t.contactName)
                    : t.equipment.isEmpty
                        ? 'General'
                        : t.equipment,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _statusPill(t),
          ],
        ),
        const SizedBox(height: 8),
        _infoRow(
          Icons.person_outline,
          'Service Engineer',
          t.hasAssignee ? t.assignee : '-',
        ),
        const SizedBox(height: 4),
        if (t.isIndividual)
          _infoRow(
            Icons.location_on_outlined,
            'Address',
            t.address.isEmpty ? '-' : t.address,
          )
        else
          _infoRow(
            Icons.apartment_outlined,
            'Company',
            t.companyName.isEmpty ? '-' : t.companyName,
          ),
        const SizedBox(height: 4),
        _infoRow(
          Icons.confirmation_number_outlined,
          'Ticket No',
          t.ticketNo.isEmpty ? '-' : t.ticketNo,
        ),
        if (overdueLine(t) != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(width: 5),
              Text(
                overdueLine(t)!,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _individualPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Individual',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _green,
        ),
      ),
    );
  }

  String? overdueLine(TaskItem t) {
    if (!t.isOverdue()) return null;
    return 'Overdue by ${-t.hoursToSla()}h (SLA)';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9B9B9B)),
        const SizedBox(width: 6),
        Text(
          '$label : ',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            color: Color(0xFF9B9B9B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A4A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(TaskItem t) {
    final (accent, bg) = _lifecycleColors(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            t.lifecycleLabel,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  /// Accent + background colors for the lifecycle status pill, so Not Assigned
  /// / Assigned / In Progress / Hold / Closed are each visually distinct.
  (Color, Color) _lifecycleColors(TaskItem t) {
    if (t.isClosed) return (_green, const Color(0xFFEBF0EA));
    switch (t.status) {
      case TaskStatus.hold:
        return (const Color(0xFFE08600), const Color(0xFFFFF4E5));
      case TaskStatus.inProgress:
        return (const Color(0xFF1565C0), const Color(0xFFE6EFFB));
      case TaskStatus.open:
        return t.hasAssignee
            ? (const Color(0xFFE08600), const Color(0xFFFFF4E5))
            : (const Color(0xFFD32F2F), const Color(0xFFFDE8E8));
      case TaskStatus.closed:
        return (_green, const Color(0xFFEBF0EA));
    }
  }

  Widget _footer(TaskItem t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF4EE),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Text(
            'Created At : ',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Color(0xFF6B6B6B),
            ),
          ),
          Text(
            _fmtDate(t.createdAt),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const Spacer(),
          if (t.escalated)
            const Text(
              'Escalated',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD32F2F),
              ),
            )
          else
            _priorityText(t.priority),
        ],
      ),
    );
  }

  Widget _priorityText(TaskPriority p) {
    final c = _priorityColor(p);
    return Text(
      p.label,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: c,
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.critical:
        return const Color(0xFFD32F2F);
      case TaskPriority.high:
        return const Color(0xFFE08600);
      case TaskPriority.medium:
        return const Color(0xFF1565C0);
      case TaskPriority.low:
        return const Color(0xFF6B6B6B);
    }
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }
}
