import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<List<String>> _drawerTitles(WidgetTester tester, UserRole role) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            Scaffold(key: scaffoldKey, drawer: const AppDrawer()),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          User(id: '1', email: 'e', name: 'Tester', role: role),
        ),
        currentUserRoleProvider.overrideWithValue(role),
        companiesProvider.overrideWith((ref) async => const []),
        drawerUsersCountProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();

  return tester
      .widgetList<Text>(
        find.descendant(of: find.byType(Drawer), matching: find.byType(Text)),
      )
      .map((t) => t.data ?? '')
      .toList();
}

void main() {
  const removed = [
    'Analytics',
    'Technicians List',
    'Assign Tasks to Technician',
    'Create AMC',
  ];

  for (final role in UserRole.values) {
    testWidgets('drawer for ${role.name} drops removed items and "Technician"',
        (tester) async {
      final titles = await _drawerTitles(tester, role);
      for (final item in removed) {
        expect(titles, isNot(contains(item)));
      }
      for (final t in titles) {
        expect(t.toLowerCase(), isNot(contains('technician')));
      }
      expect(titles, contains(role.label));
    });
  }

  testWidgets('Create Individual Task sits right after Create Task',
      (tester) async {
    for (final role in [UserRole.superAdmin, UserRole.manager]) {
      final titles = await _drawerTitles(tester, role);
      final i = titles.indexOf('Create Task');
      expect(i, isNot(-1));
      expect(titles[i + 1], 'Create Individual Task');
      expect(titles, contains('Create Company'));
    }
  });

  testWidgets('POC drawer: no Users List / AMC Renewals; has history + password',
      (tester) async {
    final titles = await _drawerTitles(tester, UserRole.client);
    expect(titles, isNot(contains('Users List')));
    expect(titles, isNot(contains('AMC Renewals')));
    expect(titles, contains('Activity History'));
    expect(titles, contains('Change Password'));
  });

  testWidgets('Client Admin drawer keeps users + renewals, adds password',
      (tester) async {
    final titles = await _drawerTitles(tester, UserRole.clientAdmin);
    expect(titles, contains('Users List'));
    expect(titles, contains('AMC Renewals'));
    expect(titles, contains('Activity History'));
    expect(titles, contains('Change Password'));
  });

  testWidgets('service engineer drawer has Activity History + Change Password',
      (tester) async {
    for (final role in [UserRole.seniorTechnician, UserRole.technician]) {
      final titles = await _drawerTitles(tester, role);
      expect(titles, contains('Activity History'), reason: '$role');
      expect(titles, contains('Change Password'), reason: '$role');
      expect(titles, isNot(contains('Users List')), reason: '$role');
      expect(titles, isNot(contains('AMC Renewals')), reason: '$role');
    }
  });

  testWidgets('Super Admin / Manager keep Change Password on Profile only',
      (tester) async {
    for (final role in [UserRole.superAdmin, UserRole.manager]) {
      final titles = await _drawerTitles(tester, role);
      expect(titles, isNot(contains('Change Password')), reason: '$role');
      expect(titles, contains('Activity History'), reason: '$role');
    }
  });

  testWidgets('Create Individual Task hidden for other roles', (tester) async {
    for (final role in [
      UserRole.seniorTechnician,
      UserRole.technician,
      UserRole.clientAdmin,
      UserRole.client,
    ]) {
      final titles = await _drawerTitles(tester, role);
      expect(titles, isNot(contains('Create Individual Task')));
      expect(titles, isNot(contains('Create Company')));
    }
  });
}
