import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart' as model;
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/amcs/domain/models/amc_contract.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/dashboard/data/analytics_history_provider.dart';
import 'package:evergreen/features/dashboard/data/analytics_provider.dart';
import 'package:evergreen/features/dashboard/data/dashboard_repository.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _analytics = DashboardAnalytics(
  usersByRole: {
    UserRole.client: 2,
    UserRole.clientAdmin: 3,
    UserRole.manager: 1,
    UserRole.technician: 4,
    UserRole.seniorTechnician: 1,
    UserRole.coldRoomTechnician: 1,
  },
  tasksByStatus: {
    'Open': 2,
    'Hold': 1,
    'In Progress': 3,
    'Closed': 6,
  },
  amcsByStatus: {AmcHealth.active: 5},
  equipmentByStatus: {model.EquipmentCondition.operational: 8},
);

AnalyticsSnapshot _snapshot() => AnalyticsSnapshot(
      date: DateTime(DateTime.now().year, DateTime.now().month),
      poc: 2,
      companyManagers: 3,
      managers: 1,
      technicians: 6,
      openTasks: 4,
      closedTasks: 2,
      amcs: 5,
      equipment: 8,
    );

Widget _dashboard(
  UserRole role, {
  required ValueChanged<bool> onAnalyticsRequested,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(role),
      currentUserProvider.overrideWithValue(
        User(id: '1', email: 'admin@example.com', name: 'Admin', role: role),
      ),
      taskCountsProvider.overrideWith(
        (ref) async => const TaskCounts({
          model.TaskStatus.open: 2,
          model.TaskStatus.hold: 1,
          model.TaskStatus.inProgress: 3,
          model.TaskStatus.completed: 4,
          model.TaskStatus.closed: 2,
        }),
      ),
      companiesProvider.overrideWith((ref) async => const <model.Company>[]),
      amcRenewalsProvider.overrideWithValue(const <AmcContract>[]),
      dashboardAnalyticsProvider.overrideWith((ref) async {
        onAnalyticsRequested(true);
        return _analytics;
      }),
      analyticsHistoryProvider.overrideWith((ref) async => [_snapshot()]),
    ],
    child: router == null
        ? const MaterialApp(home: WebDashboardScreen())
        : MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('POC dashboard card opens the POCs users-list tab',
      (tester) async {
    final router = GoRouter(
      initialLocation: Routes.webDashboard,
      routes: [
        GoRoute(
          path: Routes.webDashboard,
          builder: (context, state) => const WebDashboardScreen(),
        ),
        GoRoute(
          path: Routes.usersList,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return Scaffold(
              body: Text('Users tab ${extra?['tab']}'),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _dashboard(
        UserRole.superAdmin,
        onAnalyticsRequested: (_) {},
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    final pocCard = find.text('POC');
    await tester.ensureVisible(pocCard);
    await tester.tap(pocCard);
    await tester.pumpAndSettle();

    expect(find.text('Users tab 2'), findsOneWidget);
  });

  testWidgets('admin sees organization analytics with mobile role labels',
      (tester) async {
    var analyticsRequested = false;
    await tester.pumpWidget(
      _dashboard(
        UserRole.superAdmin,
        onAnalyticsRequested: (_) => analyticsRequested = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(analyticsRequested, isTrue);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Users by Access Level'), findsOneWidget);
    expect(find.text('EG Manager'), findsOneWidget);
    expect(find.text('Managers'), findsNothing);
    expect(find.text('Company Managers'), findsWidgets);
    expect(find.text('Clients'), findsNothing);
    expect(find.text('Task Status Overview'), findsOneWidget);
    expect(find.text('Priority Distribution'), findsNothing);
    expect(find.text('Tasks by priority level'), findsNothing);
    expect(find.text('Recent Tasks'), findsNothing);
    expect(find.text('No tasks yet'), findsNothing);
    expect(find.text('AMC Renewals Due'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('web-dashboard-open-tasks-card')),
      findsNothing,
    );
    expect(find.text('Overdue (SLA)'), findsNothing);
    expect(find.text('Unassigned'), findsNothing);
    expect(find.text('Renewals Due'), findsNothing);
    expect(find.text('Under service'), findsNothing);
    expect(find.text('Hold'), findsWidgets);
    expect(find.text('On Hold'), findsNothing);
  });

  testWidgets('non-admin does not request or see organization analytics',
      (tester) async {
    var analyticsRequested = false;
    await tester.pumpWidget(
      _dashboard(
        UserRole.client,
        onAnalyticsRequested: (_) => analyticsRequested = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(analyticsRequested, isFalse);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('Users by Access Level'), findsNothing);
    expect(find.text('Task Status Overview'), findsOneWidget);
  });

  testWidgets('reports active tasks and treats completed tasks as closed',
      (tester) async {
    await tester.pumpWidget(
      _dashboard(
        UserRole.superAdmin,
        onAnalyticsRequested: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('web-dashboard-status-Closed')),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('web-report-open-tasks-count')),
          )
          .data,
      '6',
    );
  });

  testWidgets('report filters switch to their corresponding monthly series',
      (tester) async {
    await tester.pumpWidget(
      _dashboard(
        UserRole.superAdmin,
        onAnalyticsRequested: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final tasksFilter = find.widgetWithText(ChoiceChip, 'Tasks');
    await tester.ensureVisible(tasksFilter);
    await tester.pumpAndSettle();
    await tester.tap(tasksFilter);
    await tester.pumpAndSettle();
    expect(find.text('Task Throughput'), findsOneWidget);

    final equipmentFilter = find.widgetWithText(ChoiceChip, 'Equipment');
    await tester.ensureVisible(equipmentFilter);
    await tester.pumpAndSettle();
    await tester.tap(equipmentFilter);
    await tester.pumpAndSettle();
    expect(find.text('Equipment & Contracts'), findsOneWidget);
  });

  testWidgets('renders without layout overflow at tablet and desktop widths',
      (tester) async {
    for (final width in [900.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _dashboard(
          UserRole.superAdmin,
          onAnalyticsRequested: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });
}
