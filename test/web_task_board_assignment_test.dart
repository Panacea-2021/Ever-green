import 'package:evergreen/core/data/evergreen_repository.dart'
    show techniciansProvider;
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_task_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTaskActions extends TaskActions {
  _RecordingTaskActions(super._ref, this.onAssigned);

  final ValueChanged<int> onAssigned;

  @override
  Future<void> assign(TaskItem task, int technicianId) async {
    onAssigned(technicianId);
  }
}

TaskItem _task({String assignee = '-'}) => TaskItem(
      id: '1',
      title: 'Pump repair',
      equipment: 'Pump',
      companyName: 'Evergreen',
      ticketNo: 'T-1',
      status: TaskStatus.open,
      createdAt: DateTime(2026, 11, 13),
      assignee: assignee,
    );

const _viewer = User(
  id: '7',
  email: 'manager@example.com',
  name: 'Manager',
  role: UserRole.manager,
);

const _technician = User(
  id: '42',
  email: 'tech@example.com',
  name: 'Taylor Technician',
  role: UserRole.technician,
);

Widget _board({
  required TaskItem task,
  required List<User> technicians,
  required ValueChanged<int> onAssigned,
}) {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.manager),
      currentUserProvider.overrideWithValue(_viewer),
      taskItemsProvider.overrideWithValue(AsyncData([task])),
      techniciansProvider.overrideWith((ref) async => technicians),
      technicianStatsProvider.overrideWithValue(const <TechnicianStats>[]),
      taskActionsProvider.overrideWith(
        (ref) => _RecordingTaskActions(ref, onAssigned),
      ),
    ],
    child: const MaterialApp(home: WebTaskBoardScreen()),
  );
}

void main() {
  testWidgets('Assign opens a centred dialog with close and cancel actions',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _board(
        task: _task(),
        technicians: const [_technician],
        onAssigned: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();

    expect(find.text('Assign Service Engineer'), findsOneWidget);
    expect(find.text('Taylor Technician'), findsOneWidget);
    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.center.dx, closeTo(550, 1));
    expect(dialogRect.center.dy, closeTo(450, 1));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();
    expect(find.text('Assign Service Engineer'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Reassign shows current assignee and selection submits',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    int? assignedTo;
    await tester.pumpWidget(
      _board(
        task: _task(assignee: 'Previous Technician'),
        technicians: const [_technician],
        onAssigned: (id) => assignedTo = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reassign').last);
    await tester.pumpAndSettle();
    expect(find.text('Reassign Service Engineer'), findsOneWidget);
    expect(find.text('Currently: Previous Technician'), findsOneWidget);

    await tester.tap(find.text('Taylor Technician').last);
    await tester.pumpAndSettle();
    expect(assignedTo, 42);
    expect(find.text('Reassigned to Taylor Technician'), findsOneWidget);
  });

  testWidgets('assignment picker shows a validation state with no engineers',
      (tester) async {
    await tester.pumpWidget(
      _board(
        task: _task(),
        technicians: const [],
        onAssigned: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();
    expect(find.text('No active Service Engineers available.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('assignment dialog fits a narrower browser width',
      (tester) async {
    tester.view.physicalSize = const Size(760, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _board(
        task: _task(),
        technicians: const [_technician],
        onAssigned: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign').last);
    await tester.pumpAndSettle();

    final dialogRect = tester
        .getRect(find.byKey(const ValueKey('web-task-assignment-dialog-card')));
    expect(dialogRect.width, lessThanOrEqualTo(500));
    expect(dialogRect.center.dx, closeTo(380, 1));
    expect(tester.takeException(), isNull);
  });
}
