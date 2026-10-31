import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart' hide TaskStatus;
import 'package:evergreen/features/pickers/presentation/screens/company_picker_screen.dart';
import 'package:evergreen/features/pickers/presentation/screens/equipment_picker_screen.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';

const _tech = {'id': 4, 'name': 'R. Rakesh', 'phone': '9000000004'};

/// A `getAllTasks` row (latest task_user with the task nested).
Map<String, dynamic> row({
  required int id,
  String status = 'open',
  Map<String, dynamic>? technician,
  String? assignedAt,
  String? acceptedAt,
  String? startedAt,
  bool individual = false,
  String updatedAt = '2026-10-02T10:00:00Z',
}) =>
    {
      'id': 100 + id,
      'status': status,
      'technician': technician,
      'updated_at': updatedAt,
      'task': {
        'id': id,
        'ticket_no': 'TKT-$id',
        'name': 'Ticket $id',
        'priority': 'medium',
        'created_at': '2026-10-01T10:00:00Z',
        if (assignedAt != null) 'assigned_at': assignedAt,
        if (acceptedAt != null) 'accepted_at': acceptedAt,
        if (startedAt != null) 'started_at': startedAt,
        if (individual) ...{
          'equipment': null,
          'contact_name': 'Anil Kumar',
          'contact_phone': '+919876543210',
          'address': '12 MG Road, Pune',
        } else
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

void main() {
  group('Ticket queue buckets', () {
    final now = DateTime.utc(2026, 10, 1, 12);
    final tasks = {
      'open, no engineer': item(row(id: 1)),
      'individual, no engineer': item(row(id: 2, individual: true)),
      'assigned, not accepted': item(
        row(id: 3, technician: _tech, assignedAt: '2026-10-01T11:50:00Z'),
      ),
      'assigned, null assigned_at (legacy)':
          item(row(id: 4, technician: _tech)),
      'accepted, not started': item(
        row(id: 5, technician: _tech, acceptedAt: '2026-10-01T11:00:00Z'),
      ),
      'in progress': item(row(id: 6, status: 'in_progress', technician: _tech)),
      'on hold': item(row(id: 7, status: 'hold', technician: _tech)),
      'reassigned while in progress': item(
        row(
          id: 8,
          status: 'in_progress',
          technician: _tech,
          startedAt: '2026-10-01T09:00:00Z',
        ),
      ),
      'completed': item(row(id: 9, status: 'completed', technician: _tech)),
      'closed': item(row(id: 10, status: 'closed', technician: _tech)),
      'engineer without a name': item(
        row(id: 11, technician: {'id': 12, 'name': '', 'phone': ''}),
      ),
      'individual, accepted': item(
        row(
          id: 12,
          individual: true,
          technician: _tech,
          acceptedAt: '2026-10-01T11:00:00Z',
        ),
      ),
    };

    QueueBucket? bucketOf(String name) => tasks[name]!.queueBucket;

    test('each ticket lands in the expected tab', () {
      expect(bucketOf('open, no engineer'), QueueBucket.unassigned);
      expect(bucketOf('individual, no engineer'), QueueBucket.unassigned);
      expect(bucketOf('assigned, not accepted'), QueueBucket.awaiting);
      expect(
        bucketOf('assigned, null assigned_at (legacy)'),
        QueueBucket.awaiting,
      );
      expect(bucketOf('engineer without a name'), QueueBucket.awaiting);
      expect(bucketOf('accepted, not started'), QueueBucket.assigned);
      expect(bucketOf('in progress'), QueueBucket.assigned);
      expect(bucketOf('on hold'), QueueBucket.assigned);
      expect(bucketOf('reassigned while in progress'), QueueBucket.assigned);
      expect(bucketOf('individual, accepted'), QueueBucket.assigned);
      expect(bucketOf('completed'), isNull);
      expect(bucketOf('closed'), isNull);
    });

    test('queueBuckets partitions every unfinished ticket exactly once', () {
      final b = queueBuckets(tasks.values, now);
      final ids = [
        for (final list in b.values)
          for (final t in list) t.id,
      ];
      expect(ids.toSet().length, ids.length);
      expect(b[QueueBucket.unassigned]!.map((t) => t.id),
          unorderedEquals(['1', '2']));
      expect(b[QueueBucket.awaiting]!.map((t) => t.id),
          unorderedEquals(['3', '4', '11']));
      expect(
        b[QueueBucket.assigned]!.map((t) => t.id),
        unorderedEquals(['5', '6', '7', '8', '12']),
      );
    });

    test('an assignment with no assigned_at still counts waiting time', () {
      final legacy = tasks['assigned, null assigned_at (legacy)']!;
      expect(legacy.assignedAt, isNull);
      // Falls back to the assignment row's updated_at (2026-10-02T10:00Z).
      expect(legacy.assignedSince, DateTime.utc(2026, 10, 2, 10).toLocal());
      final later = DateTime.utc(2026, 10, 2, 10, 30);
      expect(legacy.pendingAcceptanceMinutes(later), 30);
      expect(legacy.isAcceptanceOverdue(later), isTrue);

      final fresh = tasks['assigned, not accepted']!;
      expect(fresh.pendingAcceptanceMinutes(now), 10);
    });

    test('awaiting is sorted longest-waiting first', () {
      final b = queueBuckets(tasks.values, DateTime.utc(2026, 10, 2, 11));
      expect(b[QueueBucket.awaiting]!.first.id, '3');
    });

    test('an engineer with no name keeps the ticket assigned', () {
      final t = tasks['engineer without a name']!;
      expect(t.hasAssignee, isTrue);
      expect(t.isUnassigned, isFalse);
      expect(t.assignee, 'Service Engineer #12');
    });
  });

  group('Individual tasks', () {
    final t = item(row(id: 2, individual: true));

    test('parse contact fields and have no company / equipment', () {
      expect(t.isIndividual, isTrue);
      expect(t.contactName, 'Anil Kumar');
      expect(t.contactPhone, '+919876543210');
      expect(t.address, '12 MG Road, Pune');
      expect(t.equipment, '');
      expect(t.companyName, '');
      expect(t.companyId, isNull);
      expect(t.equipmentId, isNull);
      expect(t.partyName, 'Anil Kumar');
    });

    test('equipment tickets are not individual', () {
      expect(item(row(id: 1)).isIndividual, isFalse);
    });

    test('search matches contact name, phone and address', () {
      expect(t.matchesQuery('anil'), isTrue);
      expect(t.matchesQuery('98765'), isTrue);
      expect(t.matchesQuery('mg road'), isTrue);
      expect(t.matchesQuery('dmart'), isFalse);
      expect(item(row(id: 1)).matchesQuery('dmart'), isTrue);
    });

    test('contact fields survive JSON and copyWith', () {
      final restored = TaskItem.fromJson(t.toJson());
      expect(restored.contactName, 'Anil Kumar');
      expect(restored.address, '12 MG Road, Pune');
      expect(t.copyWith(address: 'New').address, 'New');
    });

    test('createTask body has no equipment_link', () {
      final body = TaskActions.individualTaskBody(
        name: 'AC not cooling',
        description: 'Split AC in bedroom',
        callType: CallType.breakdown,
        priority: TaskPriority.high,
        contactName: 'Anil Kumar',
        contactPhone: '+919876543210',
        address: '12 MG Road, Pune',
        images: const ['https://cdn/x.png'],
      );
      expect(body, {
        'name': 'AC not cooling',
        'description': 'Split AC in bedroom',
        'call_type': 'breakdown',
        'priority': 'high',
        'contact_name': 'Anil Kumar',
        'contact_phone': '+919876543210',
        'address': '12 MG Road, Pune',
        'images': ['https://cdn/x.png'],
      });
      expect(body.containsKey('equipment_link'), isFalse);
      expect(body.containsKey('client_link'), isFalse);
    });

    test('optional call type / priority are omitted when unset', () {
      final body = TaskActions.individualTaskBody(
        name: 'n',
        description: '',
        contactName: 'c',
        contactPhone: '9876543210',
        address: 'a',
      );
      expect(body.containsKey('call_type'), isFalse);
      expect(body.containsKey('priority'), isFalse);
      expect(body['images'], isEmpty);
    });
  });

  group('validateContactPhone', () {
    test('accepts 10-15 digits with optional +', () {
      expect(validateContactPhone('9876543210'), isNull);
      expect(validateContactPhone('+919876543210'), isNull);
      expect(validateContactPhone('98765 43210'), isNull);
      expect(validateContactPhone('987-654-3210'), isNull);
      expect(validateContactPhone('123456789012345'), isNull);
    });

    test('rejects empty, short, long or malformed numbers', () {
      expect(validateContactPhone(''), isNotNull);
      expect(validateContactPhone('98765'), isNotNull);
      expect(validateContactPhone('1234567890123456'), isNotNull);
      expect(validateContactPhone('98+76543210'), isNotNull);
      expect(validateContactPhone('98765abcde'), isNotNull);
    });

    test('normalizes spaces and dashes away', () {
      expect(normalizeContactPhone(' +91 98765-43210 '), '+919876543210');
    });
  });

  group('Picker filters', () {
    const company = Company(
      id: 9,
      name: 'DMart',
      branchName: 'Kothrud',
      location: 'Pune',
      gstNumber: '27AAACD1234F1Z5',
    );
    const equipment = Equipment(
      id: 3,
      name: 'Deep Freezer',
      egSerialNumber: 'EG-0042',
      make: 'Voltas',
      model: 'VF-300',
      serialNumber: 'SN-77',
    );

    test('company matches name, branch, location and GST', () {
      for (final q in ['dmart', 'KOTH', 'pune', '27aaacd']) {
        expect(companyMatches(company, q), isTrue, reason: q);
      }
      expect(companyMatches(company, 'reliance'), isFalse);
      expect(companyMatches(company, ''), isTrue);
    });

    test('equipment matches name, make, model and serial', () {
      for (final q in ['freezer', 'voltas', 'vf-3', 'sn-77', 'eg-0042']) {
        expect(equipmentMatches(equipment, q), isTrue, reason: q);
      }
      expect(equipmentMatches(equipment, 'chiller'), isFalse);
    });
  });
}
