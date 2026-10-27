import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/task_provider.dart';
import '../../tasks/domain/models/task_item.dart';

/// Preset windows for the performance report plus a custom range.
enum RangePreset { today, week, month, custom }

extension RangePresetX on RangePreset {
  String get label {
    switch (this) {
      case RangePreset.today:
        return 'Today';
      case RangePreset.week:
        return 'This Week';
      case RangePreset.month:
        return 'This Month';
      case RangePreset.custom:
        return 'Custom';
    }
  }
}

/// An inclusive date window [start, end] (whole days).
@immutable
class DateRange {
  final DateTime start;
  final DateTime end;
  final RangePreset preset;

  const DateRange(this.start, this.end, this.preset);

  factory DateRange.fromPreset(RangePreset preset, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    switch (preset) {
      case RangePreset.today:
        return DateRange(startOfDay, endOfDay, preset);
      case RangePreset.week:
        // Monday as start of week.
        final monday = startOfDay.subtract(Duration(days: today.weekday - 1));
        return DateRange(monday, endOfDay, preset);
      case RangePreset.month:
        final first = DateTime(today.year, today.month, 1);
        return DateRange(first, endOfDay, preset);
      case RangePreset.custom:
        return DateRange(startOfDay, endOfDay, preset);
    }
  }

  factory DateRange.custom(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return DateRange(s, e, RangePreset.custom);
  }

  bool contains(DateTime? d) {
    if (d == null) return false;
    return !d.isBefore(start) && !d.isAfter(end);
  }

  String get summary {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    if (preset != RangePreset.custom) return preset.label;
    return '${fmt(start)} – ${fmt(end)}';
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.start == start &&
      other.end == end &&
      other.preset == preset;

  @override
  int get hashCode => Object.hash(start, end, preset);
}

/// Currently selected performance window (defaults to This Month).
final performanceRangeProvider =
    StateProvider<DateRange>((ref) => DateRange.fromPreset(RangePreset.month));

/// Performance metrics for a person within a date range.
class PerformanceStats {
  final String name;
  final int? personId; // technician / manager backend id
  final int created; // tasks created in range
  final int completed; // tasks closed in range
  final int active; // currently open tasks (not range-bound)
  final int overdue; // currently overdue
  final double avgResolutionHours; // over completed-in-range
  final double avgRating; // over completed-in-range
  final double slaCompliance; // % of completed-in-range closed within SLA

  const PerformanceStats({
    required this.name,
    this.personId,
    required this.created,
    required this.completed,
    required this.active,
    required this.overdue,
    required this.avgResolutionHours,
    required this.avgRating,
    required this.slaCompliance,
  });

  bool get isOverloaded => active >= 3;
}

bool _closedWithinSla(TaskItem t) {
  if (t.closedAt == null) return false;
  return !t.closedAt!.isAfter(t.slaDeadline);
}

PerformanceStats _computeFor(
  String name,
  int? personId,
  List<TaskItem> all,
  DateRange range,
) {
  // Completed in range (by closedAt), created in range (by createdAt).
  final completedInRange =
      all.where((t) => t.isClosed && range.contains(t.closedAt)).toList();
  final createdInRange = all.where((t) => range.contains(t.createdAt)).toList();
  final active = all.where((t) => !t.isClosed).length;
  final overdue = all.where((t) => t.isOverdue()).length;

  final resolutions =
      completedInRange.map((t) => t.resolutionHours).whereType<int>().toList();
  final ratings =
      completedInRange.map((t) => t.rating).whereType<int>().toList();
  final withinSla = completedInRange.where(_closedWithinSla).length;

  return PerformanceStats(
    name: name,
    personId: personId,
    created: createdInRange.length,
    completed: completedInRange.length,
    active: active,
    overdue: overdue,
    avgResolutionHours: resolutions.isEmpty
        ? 0
        : resolutions.reduce((a, b) => a + b) / resolutions.length,
    avgRating:
        ratings.isEmpty ? 0 : ratings.reduce((a, b) => a + b) / ratings.length,
    slaCompliance: completedInRange.isEmpty
        ? 0
        : (withinSla / completedInRange.length) * 100,
  );
}

/// Technician performance for the selected range, grouped by technician id.
final technicianPerformanceProvider =
    Provider.autoDispose<List<PerformanceStats>>((ref) {
  final tasks = ref.watch(taskProvider);
  final range = ref.watch(performanceRangeProvider);
  final byTech = <int, List<TaskItem>>{};
  for (final t in tasks) {
    final id = t.technicianId;
    if (id == null || !t.hasAssignee) continue;
    byTech.putIfAbsent(id, () => []).add(t);
  }
  final stats = byTech.entries
      .map((e) => _computeFor(e.value.first.assignee, e.key, e.value, range))
      .toList()
    ..sort((a, b) => b.completed.compareTo(a.completed));
  return stats;
});

/// Manager performance for the selected range (tasks they oversee), grouped
/// by the ticket's manager.
final managerPerformanceProvider =
    Provider.autoDispose<List<PerformanceStats>>((ref) {
  final tasks = ref.watch(taskProvider);
  final range = ref.watch(performanceRangeProvider);
  final byMgr = <String, List<TaskItem>>{};
  for (final t in tasks) {
    if (t.managerName.isEmpty) continue;
    final key = t.managerId?.toString() ?? t.managerName;
    byMgr.putIfAbsent(key, () => []).add(t);
  }
  final stats = byMgr.values
      .map(
        (list) => _computeFor(
          list.first.managerName,
          list.first.managerId,
          list,
          range,
        ),
      )
      .toList()
    ..sort((a, b) => b.completed.compareTo(a.completed));
  return stats;
});
