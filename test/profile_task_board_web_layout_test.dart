import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/profile/data/my_companies_provider.dart';
import 'package:evergreen/features/profile/presentation/screens/profile_screen.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/screens/task_board_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _user = User(
  id: 'profile-web-test',
  name: 'Jordan Green',
  email: 'jordan@example.com',
  role: UserRole.superAdmin,
);

void main() {
  testWidgets(
    'web profile scrolls its menu independently and opens a closable company dialog',
    (tester) async {
      await _pumpProfile(tester, const Size(1280, 560));

      final nameY = tester.getTopLeft(find.text(_user.name)).dy;
      final menuScroller = find.byType(Scrollable).first;
      await tester.drag(menuScroller, const Offset(0, -420));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text(_user.name)).dy, nameY);
      await tester.ensureVisible(find.text('Account Settings'));
      expect(
        tester.getRect(find.text('Account Settings')).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );

      await tester.ensureVisible(find.text('Company Profile'));
      await tester.tap(find.text('Company Profile'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('company-profile-close')),
        findsOneWidget,
      );
      expect(find.text('No company linked'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('company-profile-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('company-profile-close')), findsNothing);
    },
    skip: !kIsWeb,
  );

  testWidgets(
    'web profile remains usable in a narrow viewport',
    (tester) async {
      await _pumpProfile(tester, const Size(700, 700));

      expect(find.text(_user.name), findsOneWidget);
      await tester.ensureVisible(find.text('Account Settings'));
      expect(tester.takeException(), isNull);
    },
    skip: !kIsWeb,
  );

  testWidgets(
    'web Task Board keeps heading, search, and Add in its top header',
    (tester) async {
      await _pumpTaskBoard(tester, const Size(900, 800));

      final header = tester.getRect(
        find.byKey(const ValueKey('task-board-web-header')),
      );
      for (final finder in [
        find.text('Task Board'),
        find.byType(TextField),
        find.text('Add'),
      ]) {
        expect(header.contains(tester.getRect(finder).center), isTrue);
      }

      await tester.enterText(find.byType(TextField), 'mixer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add form'), findsOneWidget);
    },
    skip: !kIsWeb,
  );

  testWidgets(
    'web Task Board header controls fit at a narrow desktop width',
    (tester) async {
      await _pumpTaskBoard(tester, const Size(700, 800));

      expect(find.text('Task Board'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !kIsWeb,
  );
}

Future<void> _pumpProfile(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_user),
        currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
        myCompaniesProvider.overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTaskBoard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: Routes.taskBoard,
    routes: [
      GoRoute(
        path: Routes.taskBoard,
        builder: (_, __) => const TaskBoardScreen(),
      ),
      GoRoute(
        path: '${Routes.addTask}/new',
        builder: (_, __) => const Text('Add form'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_user),
        currentUserRoleProvider.overrideWithValue(UserRole.manager),
        taskItemsProvider.overrideWithValue(
          const AsyncData(<TaskItem>[]),
        ),
        deletedTasksProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
