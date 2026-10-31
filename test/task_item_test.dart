import 'package:flutter_test/flutter_test.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';

TaskItem makeTask({
  TaskStatus status = TaskStatus.open,
  TaskPriority priority = TaskPriority.medium,
  DateTime? createdAt,
  DateTime? closedAt,
}) {
  return TaskItem(
    id: 't',
    title: 'T',
    equipment: 'E',
    companyName: 'C',
    ticketNo: '1',
    status: status,
    priority: priority,
    createdAt: createdAt ?? DateTime.now(),
    closedAt: closedAt,
  );
}

void main() {
  group('Task SLA', () {
    test('SLA hours per priority', () {
      expect(TaskPriority.critical.slaHours, 8);
      expect(TaskPriority.high.slaHours, 24);
      expect(TaskPriority.medium.slaHours, 48);
      expect(TaskPriority.low.slaHours, 72);
    });

    test('slaDeadline = createdAt + priority SLA', () {
      final created = DateTime(2026, 1, 1, 0, 0);
      final t = makeTask(priority: TaskPriority.high, createdAt: created);
      expect(t.slaDeadline, created.add(const Duration(hours: 24)));
    });

    test('a fresh task is not overdue', () {
      final t = makeTask(priority: TaskPriority.critical);
      expect(t.isOverdue(), isFalse);
    });

    test('closed tasks are never overdue', () {
      final created = DateTime.now().subtract(const Duration(days: 10));
      final t = makeTask(
        status: TaskStatus.closed,
        priority: TaskPriority.critical,
        createdAt: created,
        closedAt: DateTime.now(),
      );
      expect(t.isOverdue(), isFalse);
    });

    test('hoursToSla is negative once overdue', () {
      final created = DateTime.now().subtract(const Duration(hours: 30));
      final t = makeTask(priority: TaskPriority.high, createdAt: created);
      expect(t.hoursToSla() < 0, isTrue);
    });
  });

  group('Task priority rank ordering', () {
    test('critical outranks high outranks medium outranks low', () {
      expect(TaskPriority.critical.rank, greaterThan(TaskPriority.high.rank));
      expect(TaskPriority.high.rank, greaterThan(TaskPriority.medium.rank));
      expect(TaskPriority.medium.rank, greaterThan(TaskPriority.low.rank));
    });
  });

  group('Resolution time', () {
    test('null when not closed', () {
      expect(makeTask().resolutionHours, isNull);
    });

    test('computed from created->closed', () {
      final created = DateTime(2026, 1, 1, 0, 0);
      final closed = created.add(const Duration(hours: 12));
      final t = makeTask(
        status: TaskStatus.closed,
        createdAt: created,
        closedAt: closed,
      );
      expect(t.resolutionHours, 12);
    });
  });

  group('Task JSON + copyWith', () {
    test('round-trips assignee and rating', () {
      final t = makeTask().copyWith(
        assignee: 'Nazir',
        rating: 5,
      );
      final restored = TaskItem.fromJson(t.toJson());
      expect(restored.assignee, 'Nazir');
      expect(restored.rating, 5);
    });

    test('status/priority/approval keys round-trip', () {
      expect(
        TaskStatusX.fromKey(TaskStatus.inProgress.key),
        TaskStatus.inProgress,
      );
      expect(TaskStatusX.fromKey('In Progress'), TaskStatus.inProgress);
      expect(
        TaskPriorityX.fromKey(TaskPriority.critical.key),
        TaskPriority.critical,
      );
      expect(
        ApprovalStateX.fromKey(ApprovalState.confirmed.key),
        ApprovalState.confirmed,
      );
    });
  });
}
