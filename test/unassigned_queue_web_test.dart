import 'package:evergreen/core/data/evergreen_repository.dart'
    show techniciansProvider;
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/screens/unassigned_queue_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _manager = User(
  id: 'manager-1',
  email: 'manager@example.com',
  name: 'Manager',
  role: UserRole.manager,
);

TaskItem _task({
  required String id,
  required String title,
  String assignee = '-',
}) =>
    TaskItem(
      id: id,
      title: title,
      equipment: 'Pump',
      companyName: 'Evergreen',
      ticketNo: 'T-$id',
      status: TaskStatus.open,
      createdAt: DateTime.now(),
      assignee: assignee,
    );

Future<void> _mouseTap(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  final start = tester.getCenter(target);
  await gesture.addPointer(location: start);
  await gesture.moveTo(start);
  await tester.pump(const Duration(milliseconds: 220));
  final position = tester.getCenter(target);
  await gesture.down(position);
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'web ticket queue tabs, card actions, and cards respond to mouse',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tasks = [
        _task(id: '1', title: 'Unassigned ticket'),
        _task(id: '2', title: 'Assigned ticket', assignee: 'Taylor Technician'),
      ];
      final router = GoRouter(
        initialLocation: Routes.ticketQueue,
        routes: [
          GoRoute(
            path: Routes.ticketQueue,
            builder: (_, __) => const UnassignedQueueScreen(),
          ),
          GoRoute(
            path: '${Routes.taskDetails}/:taskId',
            builder: (_, state) =>
                Text('Ticket details ${state.pathParameters['taskId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(_manager),
            currentUserRoleProvider.overrideWithValue(UserRole.manager),
            taskItemsProvider.overrideWithValue(AsyncData(tasks)),
            taskProvider.overrideWithValue(tasks),
            techniciansProvider.overrideWith((ref) async => const <User>[]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await _mouseTap(tester, find.widgetWithText(ElevatedButton, 'Assign'));
      expect(find.text('Assign Service Engineer'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.ticketQueue,
      );
      await _mouseTap(tester, find.byTooltip('Close'));

      await _mouseTap(tester, find.text('Assigned').first);
      expect(find.text('Unassigned ticket'), findsNothing);
      expect(find.text('Assigned ticket'), findsOneWidget);

      await _mouseTap(tester, find.text('Assigned ticket'));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '${Routes.taskDetails}/2',
      );
      expect(find.text('Ticket details 2'), findsOneWidget);
    },
    skip: !kIsWeb,
  );
}
