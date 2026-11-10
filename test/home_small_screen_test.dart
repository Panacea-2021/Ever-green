import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/dashboard/data/analytics_history_provider.dart';
import 'package:evergreen/features/dashboard/data/dashboard_repository.dart';
import 'package:evergreen/features/dashboard/presentation/screens/home_screen.dart';
import 'package:evergreen/features/notifications/data/notifications_provider.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final role in [
    UserRole.superAdmin,
    UserRole.clientAdmin,
    UserRole.client,
    UserRole.technician,
  ])
    for (final (width, scale) in [(320.0, 1.0), (360.0, 1.0), (360.0, 1.3)]) {
      testWidgets(
          '${role.name} Home has no overflow at ${width.toInt()} px, text x$scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserRoleProvider.overrideWithValue(role),
              currentUserProvider.overrideWithValue(
                User(id: '1', email: 'e', name: 'Super Admin', role: role),
              ),
              taskCountsProvider
                  .overrideWith((ref) async => const TaskCounts({})),
              dashboardUsersProvider.overrideWith((ref) async => const []),
              userStatsProvider.overrideWith(
                (ref) async =>
                    const UserStats({'client_admin': 12, 'client': 40}),
              ),
              monthlyStatsProvider.overrideWith((ref) async => null),
              analyticsHistoryProvider.overrideWith((ref) async => const []),
              companiesProvider.overrideWith((ref) async => const []),
              amcRenewalsProvider.overrideWithValue(const []),
              unassignedTasksProvider.overrideWithValue(const []),
              unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        if (role == UserRole.superAdmin) {
          expect(find.text('Company Managers'), findsWidgets);
        }
      });
    }
}
