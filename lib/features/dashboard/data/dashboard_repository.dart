import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../auth/domain/models/user_model.dart';
import '../../notifications/data/notifications_provider.dart';
import '../domain/models/dashboard_data.dart';

/// Task counts by status from `getAllTasksCount` (scoped to the caller like
/// `getAllTasks`: technicians see their own, clients their companies').
class TaskCounts {
  final Map<TaskStatus, int> byStatus;

  const TaskCounts(this.byStatus);

  int of(TaskStatus status) => byStatus[status] ?? 0;
  int get total => byStatus.values.fold(0, (a, b) => a + b);

  /// Open, on hold or in progress.
  int get active =>
      of(TaskStatus.open) + of(TaskStatus.hold) + of(TaskStatus.inProgress);

  /// Completed by a technician or closed by the client.
  int get done => of(TaskStatus.completed) + of(TaskStatus.closed);

  factory TaskCounts.fromJson(dynamic data) {
    final map = data is Map ? data : const {};
    return TaskCounts({
      for (final s in TaskStatus.values) s: _toInt(map[s.key]),
    });
  }
}

/// User counts per backend `access_level` from `getUserStats` (global).
class UserStats {
  final Map<String, int> byAccessLevel;

  const UserStats(this.byAccessLevel);

  int of(String accessLevel) => byAccessLevel[accessLevel] ?? 0;
  int get clients => of('client');
  int get clientAdmins => of('client_admin');
  int get technicians => of('technician');
  int get managers => of('eg_admin');
  int get superAdmins => of('eg_super_admin');
  int get total => byAccessLevel.values.fold(0, (a, b) => a + b);

  factory UserStats.fromRows(List<Map<String, dynamic>> rows) => UserStats({
        for (final r in rows)
          if (r['access_level'] != null) '${r['access_level']}': _toInt(r['count']),
      });
}

/// One month of `companiesStats`: companies created in that month.
class MonthlyCount {
  final DateTime month;
  final int value;

  const MonthlyCount(this.month, this.value);
}

/// One month of `getMonthlyStats`.
class MonthStats {
  final DateTime month;
  final int tasksCreated;
  final int tasksClosed;
  final int companies;
  final int users;

  const MonthStats({
    required this.month,
    this.tasksCreated = 0,
    this.tasksClosed = 0,
    this.companies = 0,
    this.users = 0,
  });

  static MonthStats? fromJson(dynamic json, {DateTime? month}) {
    if (json is! Map) return null;
    final m = month ?? DateTime.tryParse('${json['month']}-01');
    if (m == null) return null;
    return MonthStats(
      month: DateTime(m.year, m.month),
      tasksCreated: _toInt(json['tasks_created']),
      tasksClosed: _toInt(json['tasks_closed']),
      companies: _toInt(json['companies']),
      users: _toInt(json['users']),
    );
  }
}

/// `getMonthlyStats`: the last 12 months (oldest first) plus the current and
/// previous month for "vs last month" trends.
class MonthlyStats {
  final List<MonthStats> months;
  final MonthStats? current;
  final MonthStats? previous;

  const MonthlyStats({required this.months, this.current, this.previous});

  factory MonthlyStats.fromJson(dynamic data) {
    final map = data is Map ? data : const {};
    final rows = map['months'];
    final months = <MonthStats>[
      if (rows is List) ...rows.map((r) => MonthStats.fromJson(r)).whereType<MonthStats>(),
    ]..sort((a, b) => a.month.compareTo(b.month));
    final now = DateTime.now();
    return MonthlyStats(
      months: months,
      current: MonthStats.fromJson(map['current'], month: DateTime(now.year, now.month)),
      previous: MonthStats.fromJson(map['previous'], month: DateTime(now.year, now.month - 1)),
    );
  }

  MonthStats? of(DateTime month) {
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month && current != null) {
      return current;
    }
    for (final m in months) {
      if (m.month.year == month.year && m.month.month == month.month) return m;
    }
    final prev = DateTime(now.year, now.month - 1);
    if (month.year == prev.year && month.month == prev.month) return previous;
    return null;
  }
}

int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class DashboardRepository {
  final EvergreenRepository _repo;

  DashboardRepository(this._repo);

  Future<TaskCounts> getTaskCounts() async {
    final body = unwrap(await _repo.api.post<dynamic>('user/getAllTasksCount', data: {}));
    return TaskCounts.fromJson(body is Map ? body['data'] : null);
  }

  /// Global counts; only call for admins.
  Future<UserStats> getUserStats() async {
    final body = unwrap(await _repo.api.post<dynamic>('user/getUserStats', data: {}));
    return UserStats.fromRows(dataList(body));
  }

  /// Companies onboarded per month for the last 12 months, oldest first.
  /// Global counts; only call for admins.
  Future<List<MonthlyCount>> getCompaniesStats() async {
    final body = unwrap(await _repo.api.post<dynamic>('user/companiesStats', data: {}));
    final out = <MonthlyCount>[];
    for (final row in dataList(body)) {
      final month = DateTime.tryParse('${row['month']}-01');
      if (month != null) out.add(MonthlyCount(month, _toInt(row['value'])));
    }
    out.sort((a, b) => a.month.compareTo(b.month));
    return out;
  }

  /// Admins; senior technicians read-only.
  Future<MonthlyStats> getMonthlyStats() async {
    final body = unwrap(await _repo.api.post<dynamic>('user/getMonthlyStats', data: {}));
    return MonthlyStats.fromJson(body is Map ? body['data'] : null);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(evergreenRepositoryProvider));
});

final taskCountsProvider = FutureProvider.autoDispose<TaskCounts>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTaskCounts();
});

/// Admin-only: watch it only for Super Admin / Manager.
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(dashboardRepositoryProvider).getUserStats();
});

/// Admin-only: watch it only for Super Admin / Manager.
final companiesStatsProvider = FutureProvider.autoDispose<List<MonthlyCount>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getCompaniesStats();
});

/// Admins and senior technicians only; null for everyone else or when the
/// endpoint fails, so callers fall back to the scoped task list.
final monthlyStatsProvider = FutureProvider.autoDispose<MonthlyStats?>((ref) async {
  final role = ref.watch(currentUserRoleProvider);
  if (role != UserRole.superAdmin &&
      role != UserRole.manager &&
      role != UserRole.seniorTechnician) {
    return null;
  }
  try {
    return await ref.watch(dashboardRepositoryProvider).getMonthlyStats();
  } catch (_) {
    return null;
  }
});

/// Users the signed-in role may list through `getAllUser`: everyone for
/// admins, their companies' users for a Client Admin, technicians for field
/// staff. Null when the role can't list users (clients) or the call fails.
final dashboardUsersProvider = FutureProvider.autoDispose<List<User>?>((ref) async {
  final role = ref.watch(currentUserRoleProvider);
  final repo = ref.watch(evergreenRepositoryProvider);
  try {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.manager:
      case UserRole.clientAdmin:
        return await repo.getUsers();
      case UserRole.seniorTechnician:
      case UserRole.technician:
        return await repo.getUsers(accessLevel: 'technician');
      case UserRole.client:
        return null;
    }
  } catch (_) {
    return null;
  }
});

/// Legacy dashboard: the caller's task totals plus their latest notifications
/// as recent activity.
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final counts = await ref.watch(taskCountsProvider.future);
  var recent = const <DashboardActivity>[];
  try {
    final (items, _) = await ref.watch(notificationsRepositoryProvider).getPage(1);
    recent = [
      for (final e in items.take(3))
        DashboardActivity(
          id: '${e.notification.id}',
          title: e.notification.title,
          description: e.notification.description,
          timestamp: e.notification.createdAt ?? DateTime.now(),
          type: e.notification.isRead ? ActivityType.info : ActivityType.success,
        ),
    ];
  } catch (_) {
    // Activity is secondary; the stats still render.
  }
  return DashboardData(
    welcomeMessage: 'Welcome back,',
    stats: DashboardStats(
      totalTasks: counts.total,
      completedTasks: counts.done,
      pendingTasks: counts.active,
    ),
    recentActivities: recent,
  );
});
