/// Steps on a ticket's timeline (backend `task_event.event`).
enum TaskEventType {
  raised('raised'),
  assigned('assigned'),
  reassigned('reassigned'),
  unassigned('unassigned'),
  accepted('accepted'),
  approved('approved'),
  rejected('rejected'),
  started('started'),
  hold('hold'),
  resumed('resumed'),
  completed('completed'),
  closed('closed'),
  reopened('reopened'),
  escalated('escalated'),
  deescalated('deescalated'),
  deleted('deleted'),
  unknown('');

  const TaskEventType(this.key);
  final String key;

  static TaskEventType fromKey(Object? key) => TaskEventType.values.firstWhere(
        (t) => t.key == '$key' && t != TaskEventType.unknown,
        orElse: () => TaskEventType.unknown,
      );
}

/// Backend actor role -> display label.
String taskActorRoleLabel(String role) => switch (role) {
      'eg_super_admin' => 'Super Admin',
      'eg_admin' => 'Manager',
      'client_admin' => 'Client Admin',
      'client' => 'POC',
      'technician' => 'Service Engineer',
      'senior_technician' => 'Senior Service Engineer',
      _ => '',
    };

/// One step on a ticket's timeline: what happened, who did it and when.
class TaskEvent {
  final int id;
  final TaskEventType type;
  final int? actorId;
  final String actorName;
  final String actorRole;
  final int? targetId;
  final String? targetName;
  final String? note;
  final DateTime at;

  const TaskEvent({
    required this.id,
    required this.type,
    required this.actorName,
    required this.at,
    this.actorId,
    this.actorRole = '',
    this.targetId,
    this.targetName,
    this.note,
  });

  factory TaskEvent.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    int? integer(Object? v) =>
        v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    return TaskEvent(
      id: integer(json['id']) ?? 0,
      type: TaskEventType.fromKey(json['event']),
      actorId: integer(json['actor_link']),
      actorName: str(json['actor_name']) ?? 'Unknown',
      actorRole: str(json['actor_role']) ?? '',
      targetId: integer(json['target_link']),
      targetName: str(json['target_name']),
      note: str(json['note']),
      at: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  String get title {
    final who = targetName ?? 'service engineer';
    return switch (type) {
      TaskEventType.raised => 'Raised',
      TaskEventType.assigned => 'Assigned to $who',
      TaskEventType.reassigned => 'Reassigned to $who',
      TaskEventType.unassigned => 'Removed $who',
      TaskEventType.accepted => 'Accepted',
      TaskEventType.approved => 'Approved',
      TaskEventType.rejected => 'Rejected',
      TaskEventType.started => 'Work started',
      TaskEventType.hold => 'Put on hold',
      TaskEventType.resumed => 'Work resumed',
      TaskEventType.completed => 'Completed',
      TaskEventType.closed => 'Closed',
      TaskEventType.reopened => 'Reopened',
      TaskEventType.escalated => 'Escalated',
      TaskEventType.deescalated => 'De-escalated',
      TaskEventType.deleted => 'Deleted',
      TaskEventType.unknown => 'Updated',
    };
  }

  /// "Ajay (Super Admin)", or just the name for system actors.
  String get actorLabel {
    final role = taskActorRoleLabel(actorRole);
    return role.isEmpty ? actorName : '$actorName ($role)';
  }
}

/// How long a ticket spent overall, being worked on, and on hold.
class TaskTimelineSummary {
  final Duration total;
  final Duration working;
  final Duration onHold;

  /// Whether the ticket is finished (closed, rejected or deleted), so
  /// [total] stops at that point instead of running to now.
  final bool finished;

  const TaskTimelineSummary({
    required this.total,
    required this.working,
    required this.onHold,
    required this.finished,
  });

  /// Walks [events] (any order): time after started / resumed / reopened
  /// counts as working until the next step; time after a hold counts as on
  /// hold. An open last stage runs to [now].
  factory TaskTimelineSummary.from(List<TaskEvent> events, {DateTime? now}) {
    final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));
    final end = now ?? DateTime.now();
    if (sorted.isEmpty) {
      return const TaskTimelineSummary(
        total: Duration.zero,
        working: Duration.zero,
        onHold: Duration.zero,
        finished: false,
      );
    }
    const workStarts = {
      TaskEventType.started,
      TaskEventType.resumed,
      TaskEventType.reopened,
    };
    const finals = {
      TaskEventType.closed,
      TaskEventType.rejected,
      TaskEventType.deleted,
    };
    var working = Duration.zero;
    var onHold = Duration.zero;
    String state = 'idle';
    DateTime? finishedAt;
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      if (workStarts.contains(e.type)) {
        state = 'working';
      } else if (e.type == TaskEventType.hold) {
        state = 'hold';
      } else if (e.type == TaskEventType.completed ||
          e.type == TaskEventType.unassigned ||
          finals.contains(e.type)) {
        state = 'idle';
      }
      if (finals.contains(e.type)) {
        finishedAt = e.at;
        break;
      }
      final next = i + 1 < sorted.length ? sorted[i + 1].at : end;
      final span = next.difference(e.at);
      if (span.isNegative) continue;
      if (state == 'working') working += span;
      if (state == 'hold') onHold += span;
    }
    final stop = finishedAt ?? end;
    return TaskTimelineSummary(
      total: stop.difference(sorted.first.at).isNegative
          ? Duration.zero
          : stop.difference(sorted.first.at),
      working: working,
      onHold: onHold,
      finished: finishedAt != null,
    );
  }
}

/// Time from each event to the next one (or to [now] for the last one when
/// the ticket isn't finished), keyed by event id.
Map<int, Duration> taskEventDurations(List<TaskEvent> events, {DateTime? now}) {
  final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));
  final end = now ?? DateTime.now();
  const finals = {
    TaskEventType.closed,
    TaskEventType.rejected,
    TaskEventType.deleted,
  };
  final out = <int, Duration>{};
  for (var i = 0; i < sorted.length; i++) {
    final isLast = i + 1 == sorted.length;
    if (isLast && finals.contains(sorted[i].type)) continue;
    final span = (isLast ? end : sorted[i + 1].at).difference(sorted[i].at);
    out[sorted[i].id] = span.isNegative ? Duration.zero : span;
  }
  return out;
}

/// "2d 3h", "3h 05m", "12m", "<1m".
String formatTaskDuration(Duration d) {
  if (d.inMinutes < 1) return '<1m';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  if (d.inHours > 0) {
    return '${d.inHours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes}m';
}

/// The few steps a service report shows (same rules as the backend's
/// `reportTimeline`): raised, latest assignment, acceptance, first start,
/// last completion and closing.
List<(DateTime, String, String)> reportSteps(List<TaskEvent> events) {
  final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));
  TaskEvent? first(Set<TaskEventType> types) {
    for (final e in sorted) {
      if (types.contains(e.type)) return e;
    }
    return null;
  }

  TaskEvent? last(Set<TaskEventType> types) {
    for (final e in sorted.reversed) {
      if (types.contains(e.type)) return e;
    }
    return null;
  }

  final raised = first({TaskEventType.raised});
  final assigned = last({TaskEventType.assigned, TaskEventType.reassigned});
  final accepted = last({TaskEventType.accepted});
  final started = first({TaskEventType.started});
  final completed = last({TaskEventType.completed});
  final closed = last({TaskEventType.closed, TaskEventType.rejected});
  return [
    if (raised != null) (raised.at, 'Raised', 'By ${raised.actorName}'),
    if (assigned != null)
      (
        assigned.at,
        'Assigned',
        'To ${assigned.targetName ?? 'service engineer'} by ${assigned.actorName}',
      ),
    if (accepted != null) (accepted.at, 'Accepted', 'By ${accepted.actorName}'),
    if (started != null)
      (started.at, 'Work started', 'By ${started.actorName}'),
    if (completed != null)
      (completed.at, 'Completed', 'By ${completed.actorName}'),
    if (closed != null)
      (
        closed.at,
        closed.type == TaskEventType.rejected ? 'Rejected' : 'Closed',
        'By ${closed.actorName}',
      ),
  ];
}
