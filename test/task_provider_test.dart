import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart' hide TaskStatus;
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/widgets/task_workflow.dart';

/// A `getAllTasks` row: the latest task_user with the task nested.
Map<String, dynamic> row({
  String status = 'open',
  Map<String, dynamic>? technician,
  String callType = 'breakdown',
  String priority = 'high',
  String approval = 'approved',
  String? createdAt,
  String? acceptedAt,
  String? dueDate,
  int? rating,
  List<Map<String, dynamic>> holds = const [],
}) =>
    {
      'id': 77,
      'status': status,
      'client': {'id': 5, 'name': 'Sunita', 'phone': '900'},
      'technician': technician,
      'manager': {'id': 2, 'name': 'Meera'},
      'updated_at': '2026-10-02T10:00:00Z',
      'task': {
        'id': 12,
        'ticket_no': 'TKT-12',
        'name': 'Fridge not cooling',
        'description': 'Compressor noise',
        'call_type': callType,
        'priority': priority,
        'approval': approval,
        'created_at': createdAt ?? '2026-10-01T10:00:00Z',
        if (acceptedAt != null) 'accepted_at': acceptedAt,
        if (dueDate != null) 'due_date': dueDate,
        if (rating != null) 'rating': rating,
        'image': ['uploads/tasks/a.png'],
        'hold_reason': holds,
        'equipment': {
          'id': 3,
          'name': 'Fridge',
          'eg_serial_number': 'EG-1',
          'company_link': 9,
          'company': {'id': 9, 'name': 'DMart', 'branch_name': 'Pune'},
        },
      },
    };

TaskItem item(Map<String, dynamic> json) =>
    TaskItem.fromService(ServiceTask.fromJson(json));

User user(UserRole role, int id) =>
    User(id: '$id', email: '', name: 'U$id', role: role);

void main() {
  group('TaskItem.fromService', () {
    test('keeps task id and task_user id', () {
      final t = item(row());
      expect(t.id, '12');
      expect(t.taskId, 12);
      expect(t.taskUserId, 77);
      expect(t.ticketNo, 'TKT-12');
      expect(t.companyName, 'DMart - Pune');
      expect(t.companyId, 9);
      expect(t.equipmentId, 3);
      expect(t.clientId, 5);
      expect(t.managerName, 'Meera');
    });

    test('unassigned open ticket', () {
      final t = item(row());
      expect(t.hasAssignee, isFalse);
      expect(t.isUnassigned, isTrue);
      expect(t.lifecycleLabel, 'Not Assigned');
      expect(t.priority, TaskPriority.high);
      expect(t.approval, ApprovalState.approved);
    });

    test('SLA follows the design: due date, else created + priority window',
        () {
      final created = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final fresh = item(row(createdAt: created.toIso8601String()));
      expect(fresh.isOverdue(), isFalse);
      expect(fresh.slaDeadline, fresh.createdAt.add(const Duration(hours: 24)));

      final old = item(row());
      expect(old.isOverdue(), isTrue);

      final due = item(row(dueDate: '2099-01-01T00:00:00Z'));
      expect(due.isOverdue(), isFalse);
    });

    test('completed shows in the closed tab, awaiting client confirmation', () {
      final t = item(
        row(
            status: 'completed',
            approval: 'completed',
            technician: {'id': 4, 'name': 'Nazir'}),
      );
      expect(t.serviceStatus, ServiceStatus.completed);
      expect(t.status, TaskStatus.closed);
      expect(t.isClosed, isTrue);
      expect(t.isOverdue(), isFalse);
      expect(t.technicianId, 4);
    });

    test('assigned but not accepted is awaiting acceptance', () {
      final t = item(row(technician: {'id': 4, 'name': 'Nazir'}));
      expect(t.isAwaitingAcceptance, isTrue);
      final accepted = item(
        row(
            technician: {'id': 4, 'name': 'Nazir'},
            acceptedAt: '2026-10-01T11:00:00Z'),
      );
      expect(accepted.isAwaitingAcceptance, isFalse);
    });
  });

  group('taskActionsFor', () {
    final tech = {'id': 4, 'name': 'Nazir'};

    test('manager assigns an unassigned ticket but cannot start it', () {
      final a = taskActionsFor(item(row()), user(UserRole.manager, 1));
      expect(
          a,
          containsAll([
            TaskAction.serviceReport,
            TaskAction.assign,
            TaskAction.priority,
            TaskAction.status
          ]));
      expect(a, isNot(contains(TaskAction.startWork)));
    });

    test('overdue, unescalated tickets can be escalated by managers', () {
      final a = taskActionsFor(
          item(row(technician: tech)), user(UserRole.manager, 1));
      expect(
          a,
          containsAll(
              [TaskAction.reassign, TaskAction.unassign, TaskAction.escalate]));
    });

    test('assigned technician accepts, then starts, holds and completes', () {
      final me = user(UserRole.technician, 4);
      expect(taskActionsFor(item(row(technician: tech)), me),
          contains(TaskAction.accept));
      final accepted =
          item(row(technician: tech, acceptedAt: '2026-10-01T11:00:00Z'));
      expect(taskActionsFor(accepted, me),
          containsAll([TaskAction.startWork, TaskAction.hold]));
      final working = taskActionsFor(
          item(row(status: 'in_progress', technician: tech)), me);
      expect(
          working,
          containsAll([
            TaskAction.addScreenshot,
            TaskAction.complete,
            TaskAction.hold
          ]));
    });

    test('another technician only sees the service report', () {
      final a = taskActionsFor(
          item(row(technician: tech)), user(UserRole.technician, 99));
      expect(a, [TaskAction.serviceReport]);
    });

    test('admins and senior technicians approve or reject requested tickets',
        () {
      final requested = item(row(approval: 'requested'));
      expect(
        taskActionsFor(requested, user(UserRole.seniorTechnician, 6)),
        containsAll([TaskAction.approve, TaskAction.reject, TaskAction.assign]),
      );
      for (final role in [UserRole.superAdmin, UserRole.manager]) {
        expect(
          taskActionsFor(requested, user(role, 1)),
          containsAll([TaskAction.approve, TaskAction.reject]),
        );
      }
      for (final role in [
        UserRole.technician,
        UserRole.clientAdmin,
        UserRole.client
      ]) {
        expect(taskActionsFor(requested, user(role, 4)),
            isNot(contains(TaskAction.approve)));
      }
    });

    test('client-side roles confirm & rate completed, unrated work', () {
      final done = item(
          row(status: 'completed', approval: 'completed', technician: tech));
      expect(taskActionsFor(done, user(UserRole.clientAdmin, 8)),
          contains(TaskAction.rate));
      final rated = item(row(
          status: 'completed',
          approval: 'completed',
          technician: tech,
          rating: 4));
      expect(taskActionsFor(rated, user(UserRole.clientAdmin, 8)),
          isNot(contains(TaskAction.rate)));
    });

    test('super admin keeps controls on closed tickets; managers do not', () {
      final closed =
          item(row(status: 'closed', approval: 'confirmed', technician: tech));
      expect(taskActionsFor(closed, user(UserRole.superAdmin, 1)),
          contains(TaskAction.status));
      expect(taskActionsFor(closed, user(UserRole.manager, 1)),
          [TaskAction.serviceReport]);
    });

    test('a ticket on hold can be resumed by its technician', () {
      final held = item(
        row(
          status: 'hold',
          technician: tech,
          holds: [
            {
              'id': 30,
              'hold': 'spare_required',
              'is_active': true,
              'spare_part_number': 'SP-1'
            },
          ],
        ),
      );
      expect(held.activeHold?.id, 30);
      final a = taskActionsFor(held, user(UserRole.technician, 4));
      expect(a, contains(TaskAction.startWork));
      expect(a, isNot(contains(TaskAction.hold)));
    });

    test('task details keep every card action and add Delete for managers', () {
      final open = item(row(status: 'in_progress', technician: tech));
      final manager = user(UserRole.manager, 1);
      expect(
        taskDetailActionsFor(open, manager),
        [...taskActionsFor(open, manager), TaskAction.delete],
      );
      for (final role in [
        UserRole.seniorTechnician,
        UserRole.technician,
        UserRole.clientAdmin,
        UserRole.client
      ]) {
        expect(taskDetailActionsFor(open, user(role, 4)),
            isNot(contains(TaskAction.delete)),
            reason: '$role');
      }
    });

    test('task details expose the technician workflow to the assignee', () {
      final me = user(UserRole.technician, 4);
      expect(taskDetailActionsFor(item(row(technician: tech)), me),
          contains(TaskAction.accept));
      final working = item(row(status: 'in_progress', technician: tech));
      expect(
        taskDetailActionsFor(working, me),
        containsAll(
            [TaskAction.addScreenshot, TaskAction.complete, TaskAction.hold]),
      );
    });

    test('task details expose approve / reject, escalate and rate per role',
        () {
      final requested = item(row(approval: 'requested'));
      expect(
        taskDetailActionsFor(requested, user(UserRole.seniorTechnician, 6)),
        containsAll([TaskAction.approve, TaskAction.reject]),
      );
      expect(
        taskDetailActionsFor(
            item(row(technician: tech)), user(UserRole.superAdmin, 1)),
        containsAll([
          TaskAction.escalate,
          TaskAction.unassign,
          TaskAction.status,
          TaskAction.delete
        ]),
      );
      final done = item(
          row(status: 'completed', approval: 'completed', technician: tech));
      expect(taskDetailActionsFor(done, user(UserRole.client, 5)),
          contains(TaskAction.rate));
    });

    test('priority star is editable only for triage roles', () {
      final open = item(row(status: 'in_progress', technician: tech));
      final closed =
          item(row(status: 'closed', approval: 'confirmed', technician: tech));
      expect(canToggleTaskPriority(open, UserRole.manager), isTrue);
      expect(canToggleTaskPriority(open, UserRole.seniorTechnician), isTrue);
      expect(canToggleTaskPriority(open, UserRole.technician), isFalse);
      expect(canToggleTaskPriority(open, UserRole.client), isFalse);
      expect(canToggleTaskPriority(open, UserRole.clientAdmin), isFalse);
      expect(canToggleTaskPriority(closed, UserRole.superAdmin), isTrue);
      expect(canToggleTaskPriority(closed, UserRole.manager), isFalse);
    });

    test('card Assign shows only for assigning roles', () {
      final open = item(row(status: 'in_progress', technician: tech));
      final closed =
          item(row(status: 'closed', approval: 'confirmed', technician: tech));
      expect(canAssignFromCard(open, UserRole.manager), isTrue);
      expect(canAssignFromCard(open, UserRole.seniorTechnician), isTrue);
      expect(canAssignFromCard(open, UserRole.technician), isFalse);
      expect(canAssignFromCard(open, UserRole.client), isFalse);
      expect(canAssignFromCard(closed, UserRole.superAdmin), isTrue);
      expect(canAssignFromCard(closed, UserRole.seniorTechnician), isFalse);
    });

    test('menu items follow the role', () {
      expect(taskMenuFor(UserRole.manager), TaskMenuItem.values);
      expect(taskMenuFor(UserRole.seniorTechnician), [TaskMenuItem.assign]);
      expect(taskMenuFor(UserRole.client), isEmpty);
    });
  });
}
