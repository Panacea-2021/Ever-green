import '../../amcs/domain/models/amc_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../auth/domain/models/user_model.dart';
import 'dashboard_repository.dart';

/// A single month of the key counts, used to compute real trends ("vs last
/// month"), sparklines and the Reports chart.
///
/// User, AMC and equipment figures are totals at the end of the month (from
/// each row's `created_at`). Task figures are that month's flow: tickets
/// opened and tickets closed (`getMonthlyStats` for admins and senior
/// technicians, otherwise derived from the caller's scoped task list).
class AnalyticsSnapshot {
  final DateTime date;
  final int poc;
  final int clients;
  final int managers;
  final int technicians;
  final int openTasks;
  final int closedTasks;
  final int amcs;
  final int equipment;

  const AnalyticsSnapshot({
    required this.date,
    required this.poc,
    required this.clients,
    required this.managers,
    required this.technicians,
    required this.openTasks,
    required this.closedTasks,
    required this.amcs,
    required this.equipment,
  });

  int metric(TrendMetric m) {
    switch (m) {
      case TrendMetric.poc:
        return poc;
      case TrendMetric.clients:
        return clients;
      case TrendMetric.managers:
        return managers;
      case TrendMetric.technicians:
        return technicians;
      case TrendMetric.openTasks:
        return openTasks;
      case TrendMetric.closedTasks:
        return closedTasks;
      case TrendMetric.amcs:
        return amcs;
      case TrendMetric.equipment:
        return equipment;
    }
  }
}

enum TrendMetric {
  poc,
  clients,
  managers,
  technicians,
  openTasks,
  closedTasks,
  amcs,
  equipment,
}

/// A computed trend: current value, previous-period value, and % change.
class Trend {
  final int current;
  final int previous;
  const Trend(this.current, this.previous);

  bool get isPositive => current >= previous;

  /// Percent change vs the previous period (0 when previous is 0).
  int get percent {
    if (previous == 0) return current == 0 ? 0 : 100;
    return (((current - previous) / previous) * 100).round().abs();
  }

  String get label => '$percent% vs Last Month';
}

/// How many years of history the Reports year dropdown offers.
const int analyticsYearsBack = 2;

DateTime? _createdAt(Map<String, dynamic> raw) =>
    DateTime.tryParse('${raw['created_at'] ?? ''}')?.toLocal();

bool _sameMonth(DateTime? d, DateTime month) =>
    d != null && d.year == month.year && d.month == month.month;

/// Builds monthly snapshots from January [analyticsYearsBack] years ago up to
/// the current month. Every source is optional: one that the role can't read
/// (or that fails) contributes zeros instead of breaking the dashboard.
List<AnalyticsSnapshot> buildAnalyticsHistory({
  required DateTime now,
  List<User>? users,
  MonthlyStats? monthlyStats,
  List<ServiceTask>? tasks,
  List<Company>? companies,
  List<Equipment>? equipment,
}) {
  final out = <AnalyticsSnapshot>[];
  final amcCompanies =
      (companies ?? const <Company>[]).where((c) => c.isAmc).toList();

  for (var m = DateTime(now.year - analyticsYearsBack);
      !m.isAfter(DateTime(now.year, now.month));
      m = DateTime(m.year, m.month + 1)) {
    final end = DateTime(m.year, m.month + 1);
    bool existed(DateTime? created) => created == null || created.isBefore(end);

    final alive = (users ?? const <User>[]).where((u) => existed(u.createdAt));
    int roles(bool Function(UserRole) test) =>
        alive.where((u) => test(u.role)).length;

    var opened = 0;
    var closed = 0;
    final stats = monthlyStats?.of(m);
    if (stats != null) {
      opened = stats.tasksCreated;
      closed = stats.tasksClosed;
    } else if (tasks != null) {
      for (final t in tasks) {
        if (_sameMonth(t.createdAt, m)) opened++;
        final closedAt = t.closedAt ??
            t.resolvedAt ??
            (t.status == TaskStatus.closed || t.status == TaskStatus.completed
                ? t.updatedAt
                : null);
        if (_sameMonth(closedAt, m)) closed++;
      }
    }

    out.add(
      AnalyticsSnapshot(
        date: m,
        poc: roles((r) => r == UserRole.client),
        clients: roles((r) => r.isClientSide),
        managers: roles((r) => r == UserRole.manager),
        technicians: roles((r) => r.isTechnicianLevel),
        openTasks: opened,
        closedTasks: closed,
        amcs: amcCompanies
            .where((c) => existed(_createdAt(c.raw) ?? c.startDate))
            .length,
        equipment: (equipment ?? const <Equipment>[])
            .where((e) => existed(_createdAt(e.raw)))
            .length,
      ),
    );
  }
  return out;
}

Future<T?> _orNull<T>(Future<T> future) async {
  try {
    return await future;
  } catch (_) {
    return null;
  }
}

final analyticsHistoryProvider =
    FutureProvider.autoDispose<List<AnalyticsSnapshot>>((ref) async {
  final monthly = await ref.watch(monthlyStatsProvider.future);
  final usersF = _orNull(ref.watch(dashboardUsersProvider.future));
  final tasksF = monthly == null
      ? _orNull(ref.watch(tasksProvider.future))
      : Future<List<ServiceTask>?>.value();
  final companiesF = _orNull(ref.watch(companiesProvider.future));
  final equipmentF = _orNull(ref.watch(equipmentsProvider(null).future));
  return buildAnalyticsHistory(
    now: DateTime.now(),
    users: await usersF,
    monthlyStats: monthly,
    tasks: await tasksF,
    companies: await companiesF,
    equipment: await equipmentF,
  );
});

List<AnalyticsSnapshot> _sorted(Ref ref) {
  final history = ref.watch(analyticsHistoryProvider).valueOrNull ?? const [];
  return [...history]..sort((a, b) => a.date.compareTo(b.date));
}

/// Trend for a metric: this month's snapshot vs the previous month's.
final trendProvider =
    Provider.autoDispose.family<Trend, TrendMetric>((ref, metric) {
  final sorted = _sorted(ref);
  if (sorted.isEmpty) return const Trend(0, 0);
  final current = sorted.last.metric(metric);
  final previous =
      sorted.length >= 2 ? sorted[sorted.length - 2].metric(metric) : current;
  return Trend(current, previous);
});

/// The monthly values of a metric, oldest-first — drives sparklines and the
/// Reports chart's bars.
final metricSeriesProvider =
    Provider.autoDispose.family<List<int>, TrendMetric>((ref, metric) {
  return _sorted(ref).map((s) => s.metric(metric)).toList();
});

const _monthAbbr = [
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

/// Month labels aligned with [metricSeriesProvider], oldest-first.
final metricMonthsProvider = Provider.autoDispose<List<String>>((ref) {
  return _sorted(ref).map((s) => _monthAbbr[s.date.month - 1]).toList();
});

/// Years offered by the Reports year dropdown, oldest-first.
final analyticsYearsProvider = Provider.autoDispose<List<int>>((ref) {
  final year = DateTime.now().year;
  return [for (var y = year - analyticsYearsBack; y <= year; y++) y];
});

/// Snapshots of one calendar year (up to the current month), oldest-first.
final yearSnapshotsProvider =
    Provider.autoDispose.family<List<AnalyticsSnapshot>, int>((ref, year) {
  return _sorted(ref).where((s) => s.date.year == year).toList();
});

/// Month label for a snapshot.
String snapshotMonthLabel(AnalyticsSnapshot s) => _monthAbbr[s.date.month - 1];
