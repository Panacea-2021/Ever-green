import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/core/widgets/scaffold_with_bottom_nav.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _admins = [UserRole.superAdmin, UserRole.manager];

Future<void> _pumpShell(
  WidgetTester tester,
  UserRole role, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget page(String name) => Scaffold(body: Center(child: Text('page:$name')));
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      ShellRoute(
        builder: (_, __, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          for (final r in [Routes.home, Routes.tasks, Routes.profile])
            GoRoute(path: r, builder: (_, __) => page(r)),
        ],
      ),
      GoRoute(path: Routes.scanner, builder: (_, __) => page(Routes.scanner)),
      GoRoute(
        path: '${Routes.addTask}/:id',
        builder: (_, __) => page(Routes.addTask),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentUserRoleProvider.overrideWithValue(role)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bottom bar stays bar-sized and the page stays visible',
      (tester) async {
    for (final role in UserRole.values) {
      await _pumpShell(tester, role);
      final bar = tester.getSize(find.byType(SafeArea).last);
      expect(bar.height, lessThan(120), reason: '$role');
      expect(find.text('page:${Routes.home}').hitTestable(), findsOneWidget,
          reason: '$role');
    }
  });

  group('tabsFor', () {
    test('Super Admin / Manager: Home, AMCs, Tasks, Profile, Settings', () {
      for (final role in _admins) {
        expect(
          ScaffoldWithBottomNav.tabsFor(role).map((t) => t.label),
          ['Home', 'AMCs', 'Tasks', 'Profile', 'Settings'],
        );
      }
    });

    test('POC, Client Admin and service engineers: Home, Tasks', () {
      for (final role in UserRole.values.where((r) => !_admins.contains(r))) {
        expect(
          ScaffoldWithBottomNav.tabsFor(role).map((t) => t.label),
          ['Home', 'Tasks'],
          reason: '$role',
        );
      }
    });
  });

  group('quickActionsFor', () {
    test('admins get Scan QR + Add Task', () {
      for (final role in _admins) {
        final actions = ScaffoldWithBottomNav.quickActionsFor(role);
        expect(actions.map((a) => a.label), ['Scan QR', 'Add Task']);
        expect(actions.last.route, '${Routes.addTask}/new');
      }
    });

    test('client roles can also raise tasks', () {
      for (final role in [UserRole.client, UserRole.clientAdmin]) {
        expect(
          ScaffoldWithBottomNav.quickActionsFor(role).map((a) => a.label),
          ['Scan QR', 'Add Task'],
        );
      }
    });

    test('service engineers get no center action', () {
      for (final role in [UserRole.seniorTechnician, UserRole.technician]) {
        expect(ScaffoldWithBottomNav.quickActionsFor(role), isEmpty);
      }
    });
  });

  group('ScaffoldWithBottomNav widget', () {
    for (final role in UserRole.values) {
      testWidgets('${role.name}: tabs and center button render without overflow',
          (tester) async {
        await _pumpShell(tester, role);
        final expected = ScaffoldWithBottomNav.tabsFor(role).map((t) => t.label);
        for (final label in expected) {
          expect(find.text(label), findsOneWidget, reason: '$role $label');
        }
        expect(
          find.byType(FloatingActionButton),
          role.isTechnicianLevel ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('5 tabs + center button fit a narrow phone', (tester) async {
      await _pumpShell(tester, UserRole.manager, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final fab = tester.getCenter(find.byType(FloatingActionButton));
      expect(fab.dx, closeTo(160, 1));
      final tasks = tester.getCenter(find.text('Tasks'));
      final profile = tester.getCenter(find.text('Profile'));
      final settings = tester.getCenter(find.text('Settings'));
      expect(tasks.dx, lessThan(fab.dx));
      expect(profile.dx, greaterThan(fab.dx));
      expect(settings.dx, greaterThan(profile.dx));
    });

    testWidgets('2 tabs sit either side of the center button', (tester) async {
      await _pumpShell(tester, UserRole.client);
      final fab = tester.getCenter(find.byType(FloatingActionButton));
      expect(tester.getCenter(find.text('Home')).dx, lessThan(fab.dx));
      expect(tester.getCenter(find.text('Tasks')).dx, greaterThan(fab.dx));
    });

    testWidgets('center "+" opens the chooser; Scan QR navigates',
        (tester) async {
      await _pumpShell(tester, UserRole.manager);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      await tester.tap(find.text('Scan QR'));
      await tester.pumpAndSettle();
      expect(find.text('page:${Routes.scanner}'), findsOneWidget);
    });

    testWidgets('chooser Add Task opens add-task/new', (tester) async {
      await _pumpShell(tester, UserRole.superAdmin);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      expect(find.text('page:${Routes.addTask}'), findsOneWidget);
    });

    testWidgets('POC chooser offers Add Task', (tester) async {
      await _pumpShell(tester, UserRole.client);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
    });
  });
}
