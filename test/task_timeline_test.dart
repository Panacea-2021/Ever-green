import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/tasks/domain/models/task_event.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/widgets/task_timeline.dart';
import 'package:evergreen/features/tasks/presentation/widgets/task_workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 10, 1, 9);

TaskEvent _event(
  int id,
  TaskEventType type,
  int minutes, {
  String actor = 'Ajay',
  String role = 'eg_super_admin',
  String? target,
  String? note,
}) =>
    TaskEvent(
      id: id,
      type: type,
      actorName: actor,
      actorRole: role,
      targetName: target,
      note: note,
      at: _t0.add(Duration(minutes: minutes)),
    );

final _events = [
  _event(
    1,
    TaskEventType.raised,
    0,
    actor: 'Priya',
    role: 'client',
    note: 'AC not cooling',
  ),
  _event(2, TaskEventType.assigned, 10, target: 'Ravi'),
  _event(3, TaskEventType.accepted, 20, actor: 'Ravi', role: 'technician'),
  _event(4, TaskEventType.started, 30, actor: 'Ravi', role: 'technician'),
  _event(
    5,
    TaskEventType.hold,
    90,
    actor: 'Ravi',
    role: 'technician',
    note: 'Spare Required',
  ),
  _event(6, TaskEventType.resumed, 150, actor: 'Ravi', role: 'technician'),
  _event(7, TaskEventType.completed, 210, actor: 'Ravi', role: 'technician'),
  _event(8, TaskEventType.closed, 240, actor: 'Priya', role: 'client'),
];

TaskItem _task({
  String assignee = 'Ravi',
  TaskStatus status = TaskStatus.inProgress,
  ApprovalState approval = ApprovalState.inService,
}) =>
    TaskItem(
      id: '5',
      title: 'T',
      equipment: 'E',
      companyName: 'C',
      ticketNo: '5',
      status: status,
      priority: TaskPriority.medium,
      createdAt: _t0,
      assignee: assignee,
      approval: approval,
    );

User _user(UserRole role) =>
    User(id: '9', email: 'u@x.com', name: 'U', role: role);

void main() {
  group('TaskEvent', () {
    test('fromJson reads the backend row', () {
      final e = TaskEvent.fromJson({
        'id': 3,
        'event': 'reassigned',
        'actor_link': 1,
        'actor_name': 'Ajay',
        'actor_role': 'eg_admin',
        'target_link': 7,
        'target_name': 'Ravi',
        'note': '  ',
        'created_at': '2026-10-01T09:00:00.000Z',
      });
      expect(e.type, TaskEventType.reassigned);
      expect(e.title, 'Reassigned to Ravi');
      expect(e.actorLabel, 'Ajay (Manager)');
      expect(e.note, isNull);
      expect(e.at, DateTime.utc(2026, 10, 1, 9).toLocal());
    });

    test('unknown events and system actors', () {
      final e = TaskEvent.fromJson({
        'id': 1,
        'event': 'something_new',
        'actor_name': 'Automatic assignment',
        'actor_role': 'system',
        'created_at': '2026-10-01T09:00:00Z',
      });
      expect(e.type, TaskEventType.unknown);
      expect(e.title, 'Updated');
      expect(e.actorLabel, 'Automatic assignment');
    });
  });

  group('durations', () {
    test('summary splits working and hold time and stops at closing', () {
      final s = TaskTimelineSummary.from(
        _events,
        now: _t0.add(const Duration(days: 3)),
      );
      expect(s.finished, isTrue);
      expect(s.total, const Duration(minutes: 240));
      expect(s.working, const Duration(minutes: 120));
      expect(s.onHold, const Duration(minutes: 60));
    });

    test('an open hold runs to now', () {
      final s = TaskTimelineSummary.from(
        _events.take(5).toList(),
        now: _t0.add(const Duration(minutes: 120)),
      );
      expect(s.finished, isFalse);
      expect(s.onHold, const Duration(minutes: 30));
      expect(s.total, const Duration(minutes: 120));
    });

    test('per-step durations skip a final last step', () {
      final d = taskEventDurations(_events);
      expect(d[5], const Duration(minutes: 60));
      expect(d.containsKey(8), isFalse);
      final open = taskEventDurations(
        _events.take(2).toList(),
        now: _t0.add(const Duration(minutes: 25)),
      );
      expect(open[2], const Duration(minutes: 15));
    });

    test('formatTaskDuration', () {
      expect(formatTaskDuration(const Duration(seconds: 30)), '<1m');
      expect(formatTaskDuration(const Duration(minutes: 12)), '12m');
      expect(formatTaskDuration(const Duration(minutes: 185)), '3h 05m');
      expect(formatTaskDuration(const Duration(hours: 51)), '2d 3h');
    });
  });

  test('reportSteps keeps only the minimal steps', () {
    final steps = reportSteps([
      ..._events,
      _event(9, TaskEventType.reassigned, 15, actor: 'Ajay', target: 'Kiran'),
    ]);
    expect(steps.map((s) => s.$2), [
      'Raised',
      'Assigned',
      'Accepted',
      'Work started',
      'Completed',
      'Closed',
    ]);
    expect(steps[0].$3, 'By Priya');
    expect(steps[1].$3, 'To Kiran by Ajay');
    expect(steps.last.$3, 'By Priya');
  });

  group('complete / close permissions', () {
    test('super admin, manager, POC and client admin once assigned', () {
      for (final role in [
        UserRole.superAdmin,
        UserRole.manager,
        UserRole.client,
        UserRole.clientAdmin,
      ]) {
        expect(canFinishTask(_task(), role), isTrue, reason: '$role');
        final actions =
            taskButtonsFor(_task(), _user(role)).map((b) => b.action);
        expect(actions, contains(TaskAction.markCompleted), reason: '$role');
        expect(actions, contains(TaskAction.closeTask), reason: '$role');
      }
      expect(canFinishTask(_task(), UserRole.technician), isFalse);
    });

    test('not before assignment or once closed', () {
      expect(canFinishTask(_task(assignee: ''), UserRole.manager), isFalse);
      expect(
        canFinishTask(
          _task(status: TaskStatus.closed, approval: ApprovalState.confirmed),
          UserRole.manager,
        ),
        isFalse,
      );
    });

    test('completed tasks only offer closing', () {
      final done = _task(
        status: TaskStatus.closed,
        approval: ApprovalState.completed,
      );
      final actions =
          taskButtonsFor(done, _user(UserRole.manager)).map((b) => b.action);
      expect(actions, isNot(contains(TaskAction.markCompleted)));
      expect(actions, contains(TaskAction.closeTask));
    });
  });

  testWidgets('finish dialog returns the note', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result =
                await askTaskFinishNote(context, _task(), closing: true),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('finishNoteField')),
      '  Fixed  ',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pumpAndSettle();
    expect(result, 'Fixed');
  });

  testWidgets('timeline view shows steps, actors and durations',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskTimelineView(
              events: _events,
              now: _t0.add(const Duration(days: 1)),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Assigned to Ravi'), findsOneWidget);
    expect(find.text('Put on hold'), findsOneWidget);
    expect(find.textContaining('Priya (POC)'), findsWidgets);
    expect(find.textContaining('On hold for 1h 00m'), findsOneWidget);
    expect(find.byKey(const Key('timelineSummary-Working')), findsOneWidget);
  });
}
