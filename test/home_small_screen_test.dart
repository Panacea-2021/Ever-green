import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/dashboard/data/analytics_history_provider.dart';
import 'package:evergreen/features/dashboard/data/dashboard_repository.dart';
import 'package:evergreen/features/dashboard/presentation/screens/home_screen.dart';
import 'package:evergreen/features/notifications/data/notifications_provider.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/users/data/user_provider.dart';
import 'package:evergreen/features/users/presentation/screens/users_list_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('users list includes an All Users filter tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) async => [
                const User(
                  id: '1',
                  email: 'admin@example.com',
                  name: 'Admin User',
                  role: UserRole.superAdmin,
                ),
                const User(
                  id: '2',
                  email: 'pm@example.com',
                  name: 'Company Manager',
                  role: UserRole.clientAdmin,
                ),
                const User(
                  id: '3',
                  email: 'poc@example.com',
                  name: 'POC User',
                  role: UserRole.client,
                ),
                const User(
                  id: '4',
                  email: 'tech@example.com',
                  name: 'Tech User',
                  role: UserRole.technician,
                ),
              ]),
        ],
        child: const MaterialApp(home: UsersListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All Users'), findsWidgets);
    expect(find.text('Company Managers'), findsWidgets);
  });

  testWidgets('POC dashboard card opens the POCs tab', (tester) async {
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.usersList,
          builder: (_, state) => UsersListScreen(
            initialTab:
                (state.extra as Map<String, dynamic>?)?['tab'] as int? ?? 0,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
          currentUserProvider.overrideWithValue(
            const User(
              id: '1',
              email: 'admin@example.com',
              name: 'Admin User',
              role: UserRole.superAdmin,
            ),
          ),
          taskCountsProvider.overrideWith((ref) async => const TaskCounts({})),
          dashboardUsersProvider.overrideWith(
            (ref) async => const [
              User(
                id: '2',
                email: 'manager@example.com',
                name: 'Company Manager User',
                role: UserRole.clientAdmin,
              ),
            ],
          ),
          userStatsProvider.overrideWith(
            (ref) async => const UserStats({'client_admin': 1, 'client': 0}),
          ),
          usersListProvider.overrideWith(
            (ref) async => const [
              User(
                id: '2',
                email: 'manager@example.com',
                name: 'Company Manager User',
                role: UserRole.clientAdmin,
              ),
            ],
          ),
          monthlyStatsProvider.overrideWith((ref) async => null),
          analyticsHistoryProvider.overrideWith((ref) async => const []),
          companiesProvider.overrideWith((ref) async => const []),
          amcRenewalsProvider.overrideWithValue(const []),
          unassignedTasksProvider.overrideWithValue(const []),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final pocCard = find.ancestor(
      of: find.text('POC'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(pocCard.first);
    await tester.tap(pocCard.first);
    await tester.pumpAndSettle();

    expect(find.text('POCs'), findsWidgets);
    expect(find.text('No users found'), findsOneWidget);
    expect(find.text('Company Manager User'), findsNothing);
  });

  testWidgets('opening an empty POCs tab does not switch to Company Managers',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersListProvider.overrideWith(
            (ref) async => const [
              User(
                id: '2',
                email: 'manager@example.com',
                name: 'Company Manager User',
                role: UserRole.clientAdmin,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: UsersListScreen(initialTab: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No users found'), findsOneWidget);
    expect(find.text('Company Manager User'), findsNothing);
  });

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
