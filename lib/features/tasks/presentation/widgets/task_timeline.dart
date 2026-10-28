import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/task_provider.dart';
import '../../domain/models/task_event.dart';

const _green = Color(0xFF106220);
const _blueTitle = Color(0xFF2B4C7E);
const _muted = Color(0xFF6B7280);

/// Task Details "Timeline" card: every step on the ticket (who raised it and
/// why, assignments, acceptance, work, holds, completion, closing) with the
/// time spent in each stage and totals for working / on hold.
class TaskTimelineCard extends ConsumerWidget {
  const TaskTimelineCard({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskTimelineProvider(taskId));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: _blueTitle),
              SizedBox(width: 8),
              Text(
                'Timeline',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _blueTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: _green)),
            ),
            error: (e, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load the timeline. $e',
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(taskTimelineProvider(taskId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (events) => events.isEmpty
                ? const Text(
                    'No history recorded yet.',
                    style: TextStyle(fontSize: 13, color: _muted),
                  )
                : TaskTimelineView(events: events),
          ),
        ],
      ),
    );
  }
}

/// The summary chips and the list of steps for [events].
class TaskTimelineView extends StatelessWidget {
  const TaskTimelineView({super.key, required this.events, this.now});

  final List<TaskEvent> events;

  /// Clock for durations of a still-open stage (tests pin it).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));
    final summary = TaskTimelineSummary.from(sorted, now: now);
    final durations = taskEventDurations(sorted, now: now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              Icons.schedule_rounded,
              summary.finished ? 'Total' : 'Open for',
              summary.total,
              _blueTitle,
            ),
            _chip(Icons.build_rounded, 'Working', summary.working, _green),
            _chip(
              Icons.pause_circle_outline_rounded,
              'On hold',
              summary.onHold,
              const Color(0xFFE08A00),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < sorted.length; i++)
          _TimelineStep(
            event: sorted[i],
            duration: durations[sorted[i].id],
            isLast: i == sorted.length - 1,
          ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Duration value, Color color) {
    return Container(
      key: Key('timelineSummary-$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$label ${formatTaskDuration(value)}',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.event,
    required this.duration,
    required this.isLast,
  });

  final TaskEvent event;
  final Duration? duration;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style(event.type);
    final note = event.note;
    final spent = _durationText();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      if (spent != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          spent,
                          key: Key('timelineDuration-${event.id}'),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${event.actorLabel} · ${_fmt(event.at)}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_notePrefix(event.type)}$note',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Time spent in this step before the next one (or so far, when last).
  String? _durationText() {
    final d = duration;
    return d == null ? null : formatTaskDuration(d);
  }

  static String _notePrefix(TaskEventType type) => switch (type) {
        TaskEventType.raised => 'Issue: ',
        TaskEventType.hold ||
        TaskEventType.rejected ||
        TaskEventType.escalated ||
        TaskEventType.deleted =>
          'Reason: ',
        _ => 'Note: ',
      };

  static (IconData, Color) _style(TaskEventType type) => switch (type) {
        TaskEventType.raised => (Icons.flag_rounded, const Color(0xFF2563EB)),
        TaskEventType.assigned || TaskEventType.reassigned => (
            Icons.person_add_alt_1_rounded,
            const Color(0xFF7C3AED)
          ),
        TaskEventType.unassigned => (Icons.person_remove_alt_1_rounded, _muted),
        TaskEventType.accepted || TaskEventType.approved => (
            Icons.task_alt_rounded,
            const Color(0xFF7C3AED)
          ),
        TaskEventType.started ||
        TaskEventType.resumed ||
        TaskEventType.reopened =>
          (Icons.play_arrow_rounded, _green),
        TaskEventType.hold => (Icons.pause_rounded, const Color(0xFFE08A00)),
        TaskEventType.completed => (
            Icons.done_all_rounded,
            const Color(0xFF0F766E)
          ),
        TaskEventType.closed => (Icons.lock_rounded, _green),
        TaskEventType.escalated => (
            Icons.trending_up_rounded,
            const Color(0xFFD32F2F)
          ),
        TaskEventType.deescalated => (Icons.trending_down_rounded, _muted),
        TaskEventType.rejected || TaskEventType.deleted => (
            Icons.cancel_rounded,
            const Color(0xFFD32F2F)
          ),
        TaskEventType.unknown => (Icons.circle_outlined, _muted),
      };

  static String _fmt(DateTime d) {
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
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}, '
        '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
