import 'package:flutter_test/flutter_test.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/dashboard/data/analytics_history_provider.dart';
import 'package:evergreen/features/dashboard/data/analytics_provider.dart';
import 'package:evergreen/features/dashboard/data/dashboard_repository.dart';

void main() {
  group('DashboardAnalytics totals + CSV', () {
    final a = DashboardAnalytics(
      usersByRole: usersByRoleOf(
        stats: UserStats.fromRows(const [
          {'access_level': 'eg_super_admin', 'count': 1},
          {'access_level': 'eg_admin', 'count': 3},
          {'access_level': 'technician', 'count': 8},
          {'access_level': 'client', 'count': 9},
        ]),
      ),
      tasksByStatus: tasksByStatusOf(
        TaskCounts.fromJson(const {
          'open': 4,
          'hold': 2,
          'in_progress': 3,
          'completed': 1,
          'closed': 1,
        }),
      ),
      amcsByStatus: const {
        AmcHealth.active: 4,
        AmcHealth.expiringSoon: 1,
        AmcHealth.expired: 1,
      },
      equipmentByStatus: const {
        EquipmentCondition.operational: 9,
        EquipmentCondition.underMaintenance: 2,
        EquipmentCondition.faulty: 1,
        EquipmentCondition.retired: 0,
      },
    );

    test('totals sum their segments', () {
      expect(a.totalUsers, 21);
      expect(a.totalTasks, 11);
      expect(a.totalAmcs, 6);
      expect(a.totalEquipment, 12);
    });

    test('completed tasks count as closed', () {
      expect(a.tasksByStatus['Closed'], 2);
    });

    test('CSV has header + one row per segment + totals', () {
      final csv = a.toCsv();
      final lines = csv.trim().split('\n');
      expect(lines.first, 'Category,Segment,Count');
      expect(csv, contains('Users,Super Admin,1'));
      expect(csv, contains('Tasks,Closed,2'));
      expect(csv, contains('AMCs,Expired,1'));
      expect(csv, contains('Totals,Users,21'));
      expect(csv, contains('Totals,AMCs,6'));
      expect(csv, contains('Equipment,Operational,9'));
      expect(csv, contains('Totals,Equipment,12'));
    });

    test('a user list splits senior and junior technicians', () {
      final counts = usersByRoleOf(
        users: const [
          User(id: '1', email: 'a', name: 'A', role: UserRole.seniorTechnician),
          User(id: '2', email: 'b', name: 'B', role: UserRole.technician),
          User(id: '3', email: 'c', name: 'C', role: UserRole.technician),
        ],
      );
      expect(counts[UserRole.seniorTechnician], 1);
      expect(counts[UserRole.technician], 2);
    });
  });

  group('Analytics history', () {
    final now = DateTime(2026, 10, 15);

    test('covers January two years back through the current month', () {
      final h = buildAnalyticsHistory(now: now);
      expect(h.first.date, DateTime(2024));
      expect(h.last.date, DateTime(2026, 10));
      expect(h.length, 34);
    });

    test('user totals accumulate by created_at', () {
      final h = buildAnalyticsHistory(
        now: now,
        users: [
          User(
              id: '1',
              email: 'a',
              name: 'A',
              role: UserRole.client,
              createdAt: DateTime(2026, 8, 3)),
          User(
              id: '2',
              email: 'b',
              name: 'B',
              role: UserRole.clientAdmin,
              createdAt: DateTime(2026, 10, 1)),
          User(
              id: '3',
              email: 'c',
              name: 'C',
              role: UserRole.technician,
              createdAt: DateTime(2026, 9, 20)),
        ],
      );
      final sep = h[h.length - 2];
      final oct = h.last;
      expect(sep.poc, 1);
      expect(sep.clients, 1);
      expect(sep.technicians, 1);
      expect(oct.clients, 2);
      expect(Trend(oct.clients, sep.clients).percent, 100);
    });

    test('monthly stats drive task flow when available', () {
      final stats = MonthlyStats.fromJson({
        'months': [
          {'month': '2026-09', 'tasks_created': 5, 'tasks_closed': 3},
          {'month': '2026-10', 'tasks_created': 7, 'tasks_closed': 4},
        ],
      });
      final h = buildAnalyticsHistory(now: now, monthlyStats: stats);
      expect(h.last.openTasks, 7);
      expect(h.last.closedTasks, 4);
      expect(h[h.length - 2].openTasks, 5);
    });
  });

  group('Trend', () {
    test('percent change and direction', () {
      expect(const Trend(12, 10).percent, 20);
      expect(const Trend(12, 10).isPositive, isTrue);
      expect(const Trend(8, 10).isPositive, isFalse);
      expect(const Trend(0, 0).label, '0% vs Last Month');
      expect(const Trend(3, 0).percent, 100);
    });
  });
}
