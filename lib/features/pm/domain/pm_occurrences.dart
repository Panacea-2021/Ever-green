import 'dart:math' as math;

import '../../../core/models/backend_models.dart';
import 'models/pm_schedule.dart';

/// A recurrence step: either a whole number of days or calendar months.
class PmStep {
  final int days;
  final int months;

  const PmStep.days(this.days) : months = 0;
  const PmStep.months(this.months) : days = 0;

  bool get isDays => days > 0;

  /// The equipment `tm_frequency` step.
  factory PmStep.forTm(TmFrequency f) {
    switch (f) {
      case TmFrequency.daily:
        return const PmStep.days(1);
      case TmFrequency.weekly:
        return const PmStep.days(7);
      case TmFrequency.biweekly:
        return const PmStep.days(14);
      case TmFrequency.monthly:
        return const PmStep.months(1);
      case TmFrequency.biMonthly:
        return const PmStep.months(2);
      case TmFrequency.triMonthly:
      case TmFrequency.quarterly:
        return const PmStep.months(3);
      case TmFrequency.semiAnnual:
        return const PmStep.months(6);
      case TmFrequency.annual:
        return const PmStep.months(12);
    }
  }

  /// The `pm_schedule.frequency` step.
  factory PmStep.forPm(PmFrequency f) => PmStep.months(f.months);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d] plus [months] calendar months; the day clamps to the target month's
/// last day (Jan 31 + 1 month = Feb 28/29), matching the backend's moment.add.
DateTime addMonthsClamped(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(d.day, lastDay));
}

/// The [k]-th occurrence after [anchor]. Month steps are always measured from
/// the anchor, so a clamped month (Feb 28) does not drag later ones (Mar 31).
DateTime pmOccurrence(DateTime anchor, PmStep step, int k) {
  final a = dateOnly(anchor);
  return step.isDays
      ? DateTime(a.year, a.month, a.day + k * step.days)
      : addMonthsClamped(a, k * step.months);
}

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

/// A k index at or before the first occurrence on/after [date].
int _startIndex(DateTime anchor, PmStep step, DateTime date, int kMin) {
  final int k;
  if (step.isDays) {
    k = _daysBetween(anchor, date) ~/ step.days - 1;
  } else {
    final months =
        (date.year * 12 + date.month) - (anchor.year * 12 + anchor.month);
    k = months ~/ step.months - 1;
  }
  return math.max(kMin, k);
}

const _maxIterations = 20000;

/// Occurrences `anchor + k*step` (k >= [kMin]) that fall within [from]..[to]
/// (both inclusive, compared by date).
List<DateTime> pmOccurrencesBetween(
  DateTime anchor,
  PmStep step,
  DateTime from,
  DateTime to, {
  int kMin = 1,
}) {
  final start = dateOnly(from);
  final end = dateOnly(to);
  if (end.isBefore(start)) return const [];
  final out = <DateTime>[];
  var k = _startIndex(anchor, step, start, kMin);
  for (var i = 0; i < _maxIterations; i++, k++) {
    final d = pmOccurrence(anchor, step, k);
    if (d.isAfter(end)) break;
    if (!d.isBefore(start)) out.add(d);
  }
  return out;
}

/// The latest occurrence (k >= [kMin]) strictly before [date], or null.
DateTime? pmLastOccurrenceBefore(
  DateTime anchor,
  PmStep step,
  DateTime date, {
  int kMin = 1,
}) {
  final limit = dateOnly(date);
  DateTime? last;
  var k = _startIndex(anchor, step, limit, kMin);
  for (var i = 0; i < _maxIterations; i++, k++) {
    final d = pmOccurrence(anchor, step, k);
    if (!d.isBefore(limit)) break;
    last = d;
  }
  return last;
}

/// A recorded PM visit for one piece of equipment: a PM task (or generated
/// PM visit). [done] is false while the visit is still open.
class PmVisit {
  final DateTime date;
  final bool done;

  const PmVisit(this.date, {this.done = true});
}

bool _isDone(TaskStatus s) =>
    s == TaskStatus.completed || s == TaskStatus.closed;

/// The latest PM visit per equipment id, from `amc_preventive_maintenance`
/// tasks and generated PM visits. Done visits use their completion date;
/// open ones their due date.
Map<int, PmVisit> lastPmVisits({
  Iterable<ServiceTask> tasks = const [],
  Iterable<PmGeneratedTask> generated = const [],
}) {
  final out = <int, PmVisit>{};
  void add(int? equipmentId, PmVisit visit) {
    if (equipmentId == null) return;
    final current = out[equipmentId];
    final day = dateOnly(visit.date);
    if (current == null ||
        day.isAfter(current.date) ||
        (day == current.date && visit.done && !current.done)) {
      out[equipmentId] = PmVisit(day, done: visit.done);
    }
  }

  for (final t in tasks) {
    if (t.callType != CallType.amcPreventiveMaintenance) continue;
    if (t.approval == ApprovalStage.rejected) continue;
    final done = _isDone(t.status);
    final date = done
        ? (t.resolvedAt ?? t.closedAt ?? t.updatedAt ?? t.dueDate)
        : (t.dueDate ?? t.createdAt);
    if (date == null) continue;
    add(t.equipment?.id, PmVisit(date, done: done));
  }
  for (final g in generated) {
    final status = g.taskStatus;
    final done = status != null && _isDone(status);
    add(g.equipmentId, PmVisit(g.dueDate, done: done));
  }
  return out;
}

/// The date an equipment's PM cycle counts from when no visit is recorded.
DateTime? equipmentPmBaseDate(Equipment e) {
  final created = e.raw['created_at'];
  return e.installedAt ??
      e.manufacturerDate ??
      (created == null ? null : DateTime.tryParse('$created')?.toLocal());
}

/// One upcoming (or overdue) maintenance occurrence for a piece of equipment.
class PmDue {
  final int? equipmentId;
  final String equipmentName;
  final String companyName;
  final String location;
  final String frequencyLabel;
  final DateTime dueDate;
  final bool overdue;

  /// True when an active `pm_schedule` row produced this date.
  final bool fromSchedule;

  /// True when the equipment's own `tm_frequency` produced this date.
  final bool fromEquipment;
  final Equipment? equipment;

  const PmDue({
    required this.equipmentId,
    required this.equipmentName,
    required this.companyName,
    required this.location,
    required this.frequencyLabel,
    required this.dueDate,
    this.overdue = false,
    this.fromSchedule = false,
    this.fromEquipment = false,
    this.equipment,
  });

  bool isToday(DateTime today) => dueDate == dateOnly(today);

  PmDue _merge(PmDue other) => PmDue(
        equipmentId: equipmentId,
        equipmentName:
            equipmentName.isNotEmpty ? equipmentName : other.equipmentName,
        companyName: companyName.isNotEmpty ? companyName : other.companyName,
        location: location.isNotEmpty ? location : other.location,
        frequencyLabel: fromEquipment ? frequencyLabel : other.frequencyLabel,
        dueDate: dueDate,
        overdue: overdue || other.overdue,
        fromSchedule: fromSchedule || other.fromSchedule,
        fromEquipment: fromEquipment || other.fromEquipment,
        equipment: equipment ?? other.equipment,
      );
}

bool _usable(Equipment e) =>
    e.isActive && e.status != EquipmentCondition.retired;

/// Upcoming PM occurrences between [from] and [to] (inclusive) for every
/// active equipment with a `tm_frequency`, plus every active `pm_schedule`,
/// de-duplicated per equipment and date.
///
/// Equipment occurrences step by `tm_frequency` from the last PM visit in
/// [lastVisits] (an open visit counts itself), else [equipmentPmBaseDate].
/// Schedule occurrences step from `next_due` (inclusive).
///
/// With [includeOverdue], each equipment also gets at most one overdue row:
/// the latest missed occurrence before [today]. Equipment without a recorded
/// visit or schedule is never marked overdue, since its history is unknown.
List<PmDue> computePmDue({
  required List<Equipment> equipments,
  List<PmSchedule> schedules = const [],
  Map<int, PmVisit> lastVisits = const {},
  required DateTime from,
  required DateTime to,
  required DateTime today,
  bool includeOverdue = false,
}) {
  final day = dateOnly(today);
  final byId = {for (final e in equipments) e.id: e};
  final upcoming = <String, PmDue>{};
  final overdue = <int, PmDue>{};

  String key(int? id, DateTime d) => '$id|${d.year}-${d.month}-${d.day}';

  void addUpcoming(PmDue due) {
    final k = key(due.equipmentId, due.dueDate);
    final existing = upcoming[k];
    upcoming[k] = existing == null ? due : existing._merge(due);
  }

  void addOverdue(PmDue due) {
    final id = due.equipmentId ?? -1;
    final existing = overdue[id];
    if (existing == null || due.dueDate.isAfter(existing.dueDate)) {
      overdue[id] = due;
    } else if (due.dueDate == existing.dueDate) {
      overdue[id] = existing._merge(due);
    }
  }

  PmDue fromEquipment(Equipment e, DateTime d, {bool late = false}) => PmDue(
        equipmentId: e.id,
        equipmentName: e.name,
        companyName: e.company?.displayName ?? '',
        location: e.location ?? '',
        frequencyLabel: e.tmFrequency!.label,
        dueDate: d,
        overdue: late,
        fromEquipment: true,
        equipment: e,
      );

  for (final e in equipments) {
    final frequency = e.tmFrequency;
    if (frequency == null || !_usable(e)) continue;
    final step = PmStep.forTm(frequency);
    final visit = lastVisits[e.id];
    final anchor = visit?.date ?? equipmentPmBaseDate(e);
    if (anchor == null) continue;
    final kMin = visit != null && !visit.done ? 0 : 1;
    for (final d in pmOccurrencesBetween(anchor, step, from, to, kMin: kMin)) {
      addUpcoming(fromEquipment(e, d));
    }
    if (includeOverdue && visit != null) {
      final late = pmLastOccurrenceBefore(anchor, step, day, kMin: kMin);
      if (late != null) addOverdue(fromEquipment(e, late, late: true));
    }
  }

  for (final s in schedules) {
    if (!s.active) continue;
    final e = s.equipmentId == null ? null : byId[s.equipmentId];
    if (e != null && !_usable(e)) continue;
    final step = PmStep.forPm(s.frequency);
    PmDue build(DateTime d, {bool late = false}) => PmDue(
          equipmentId: s.equipmentId,
          equipmentName: e?.name ?? s.equipmentName,
          companyName: e?.company?.displayName ?? s.companyName,
          location: e?.location ?? '',
          frequencyLabel: s.frequency.label,
          dueDate: d,
          overdue: late,
          fromSchedule: true,
          equipment: e,
        );
    for (final d in pmOccurrencesBetween(s.nextDue, step, from, to, kMin: 0)) {
      addUpcoming(build(d));
    }
    if (includeOverdue) {
      final late = pmLastOccurrenceBefore(s.nextDue, step, day, kMin: 0);
      if (late != null) addOverdue(build(late, late: true));
    }
  }

  int byDate(PmDue a, PmDue b) {
    final c = a.dueDate.compareTo(b.dueDate);
    return c != 0
        ? c
        : a.equipmentName
            .toLowerCase()
            .compareTo(b.equipmentName.toLowerCase());
  }

  // An overdue row only matters when it isn't also listed as upcoming.
  final late = overdue.values
      .where((o) => !upcoming.containsKey(key(o.equipmentId, o.dueDate)))
      .toList()
    ..sort(byDate);
  return [...late, ...(upcoming.values.toList()..sort(byDate))];
}

/// The preset windows on the PM screen.
enum PmWindow { tomorrow, week, month }

extension PmWindowX on PmWindow {
  String get label {
    switch (this) {
      case PmWindow.tomorrow:
        return 'Tomorrow';
      case PmWindow.week:
        return 'This Week';
      case PmWindow.month:
        return 'This Month';
    }
  }

  /// Tomorrow only; today through Sunday (weeks start Monday); today through
  /// the month's last day.
  (DateTime, DateTime) range(DateTime now) {
    final today = dateOnly(now);
    switch (this) {
      case PmWindow.tomorrow:
        final t = DateTime(today.year, today.month, today.day + 1);
        return (t, t);
      case PmWindow.week:
        return (
          today,
          DateTime(today.year, today.month, today.day + (7 - today.weekday)),
        );
      case PmWindow.month:
        return (today, DateTime(today.year, today.month + 1, 0));
    }
  }

  /// Week and month views also surface overdue maintenance.
  bool get includesOverdue => this != PmWindow.tomorrow;
}
