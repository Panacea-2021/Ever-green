import '../../amcs/domain/models/amc_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../auth/domain/models/user_model.dart';
import 'dashboard_repository.dart';

/// AMC contract health derived from each AMC company's end date.
enum AmcHealth {
  active('Active'),
  expiringSoon('Expiring Soon'),
  expired('Expired');

  const AmcHealth(this.label);
  final String label;

  static AmcHealth? of(Company c, DateTime now) {
    if (!c.isAmc) return null;
    final end = c.endDate;
    if (end == null) return AmcHealth.active;
    if (end.isBefore(now)) return AmcHealth.expired;
    if (end.isBefore(now.add(const Duration(days: 30)))) {
      return AmcHealth.expiringSoon;
    }
    return AmcHealth.active;
  }
}

/// Task status buckets shown on the dashboard and analytics screen. The
/// backend's `completed` (awaiting client confirmation) counts as closed.
Map<String, int> tasksByStatusOf(TaskCounts c) => {
      'Open': c.of(TaskStatus.open),
      'Hold': c.of(TaskStatus.hold),
      'In Progress': c.of(TaskStatus.inProgress),
      'Closed': c.done,
    };

/// User counts per role. A full user list gives the exact split (senior vs
/// junior technicians); otherwise the `getUserStats` access levels are used.
Map<UserRole, int> usersByRoleOf({List<User>? users, UserStats? stats}) {
  final counts = {for (final r in UserRole.values) r: 0};
  if (users != null) {
    for (final u in users) {
      counts[u.role] = counts[u.role]! + 1;
    }
  } else if (stats != null) {
    counts[UserRole.superAdmin] = stats.superAdmins;
    counts[UserRole.manager] = stats.managers;
    counts[UserRole.technician] = stats.technicians;
    counts[UserRole.clientAdmin] = stats.clientAdmins;
    counts[UserRole.client] = stats.clients;
  }
  return counts;
}

/// Aggregated analytics computed from the backend: users (`getAllUser` /
/// `getUserStats`), tasks (`getAllTasksCount`), AMCs (`getAllCompanies`) and
/// equipment (`getAllEquipments`).
class DashboardAnalytics {
  final Map<UserRole, int> usersByRole;
  final Map<String, int> tasksByStatus;
  final Map<AmcHealth, int> amcsByStatus;
  final Map<EquipmentCondition, int> equipmentByStatus;

  const DashboardAnalytics({
    required this.usersByRole,
    required this.tasksByStatus,
    required this.amcsByStatus,
    required this.equipmentByStatus,
  });

  int get totalUsers => usersByRole.values.fold(0, (a, b) => a + b);
  int get totalTasks => tasksByStatus.values.fold(0, (a, b) => a + b);
  int get totalAmcs => amcsByStatus.values.fold(0, (a, b) => a + b);
  int get totalEquipment => equipmentByStatus.values.fold(0, (a, b) => a + b);

  /// Render the full analytics snapshot as CSV text for export.
  String toCsv() {
    final b = StringBuffer();
    b.writeln('Category,Segment,Count');
    usersByRole.forEach((role, count) {
      b.writeln('Users,${role.label},$count');
    });
    tasksByStatus.forEach((status, count) {
      b.writeln('Tasks,$status,$count');
    });
    amcsByStatus.forEach((status, count) {
      b.writeln('AMCs,${status.label},$count');
    });
    equipmentByStatus.forEach((status, count) {
      b.writeln('Equipment,${status.label},$count');
    });
    b.writeln('Totals,Users,$totalUsers');
    b.writeln('Totals,Tasks,$totalTasks');
    b.writeln('Totals,AMCs,$totalAmcs');
    b.writeln('Totals,Equipment,$totalEquipment');
    return b.toString();
  }
}

/// Admin-only (uses global stats endpoints).
final dashboardAnalyticsProvider =
    FutureProvider.autoDispose<DashboardAnalytics>((ref) async {
  final results = await Future.wait([
    ref.watch(dashboardUsersProvider.future),
    ref.watch(taskCountsProvider.future),
    ref.watch(companiesProvider.future),
    ref.watch(equipmentsProvider(null).future),
  ]);
  final users = results[0] as List<User>?;
  final companies = results[2] as List<Company>;
  final equipment = results[3] as List<Equipment>;

  final now = DateTime.now();
  final amcs = {for (final h in AmcHealth.values) h: 0};
  for (final c in companies) {
    final h = AmcHealth.of(c, now);
    if (h != null) amcs[h] = amcs[h]! + 1;
  }
  final byCondition = {for (final c in EquipmentCondition.values) c: 0};
  for (final e in equipment) {
    byCondition[e.status] = byCondition[e.status]! + 1;
  }

  return DashboardAnalytics(
    usersByRole: usersByRoleOf(
      users: users,
      stats: users == null ? await ref.watch(userStatsProvider.future) : null,
    ),
    tasksByStatus: tasksByStatusOf(results[1] as TaskCounts),
    amcsByStatus: amcs,
    equipmentByStatus: byCondition,
  );
});
