import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/pm/domain/models/pm_schedule.dart';
import 'package:evergreen/features/pm/domain/pm_occurrences.dart';

Equipment eq(
  int id, {
  TmFrequency? frequency,
  DateTime? installedAt,
  DateTime? manufacturerDate,
  String? createdAt,
  bool active = true,
  EquipmentCondition status = EquipmentCondition.operational,
}) {
  return Equipment(
    id: id,
    name: 'Equipment $id',
    egSerialNumber: 'EG-$id',
    location: 'Floor $id',
    tmFrequency: frequency,
    installedAt: installedAt,
    manufacturerDate: manufacturerDate,
    isActive: active,
    status: status,
    company: const Company(id: 1, name: 'Croma', branchName: 'Madhapur'),
    companyId: 1,
    raw: {if (createdAt != null) 'created_at': createdAt},
  );
}

void main() {
  group('frequency steps', () {
    final anchor = DateTime(2026, 1, 15);
    final expected = {
      TmFrequency.daily: DateTime(2026, 1, 16),
      TmFrequency.weekly: DateTime(2026, 1, 22),
      TmFrequency.biweekly: DateTime(2026, 1, 29),
      TmFrequency.monthly: DateTime(2026, 2, 15),
      TmFrequency.biMonthly: DateTime(2026, 3, 15),
      TmFrequency.triMonthly: DateTime(2026, 4, 15),
      TmFrequency.quarterly: DateTime(2026, 4, 15),
      TmFrequency.semiAnnual: DateTime(2026, 7, 15),
      TmFrequency.annual: DateTime(2027, 1, 15),
    };
    for (final entry in expected.entries) {
      test('${entry.key.key} steps one cycle', () {
        expect(
          pmOccurrence(anchor, PmStep.forTm(entry.key), 1),
          entry.value,
        );
      });
    }

    test('every tm_frequency has a step', () {
      expect(expected.keys.toSet(), TmFrequency.values.toSet());
    });

    test('pm_schedule frequencies step by months', () {
      expect(
        pmOccurrence(anchor, PmStep.forPm(PmFrequency.halfYearly), 1),
        DateTime(2026, 7, 15),
      );
      expect(
        pmOccurrence(anchor, PmStep.forPm(PmFrequency.yearly), 2),
        DateTime(2028, 1, 15),
      );
    });

    test('day steps cross month and year ends', () {
      expect(
        pmOccurrence(DateTime(2026, 12, 25), const PmStep.days(14), 1),
        DateTime(2027, 1, 8),
      );
    });
  });

  group('month-end edge cases', () {
    const monthly = PmStep.months(1);

    test('Jan 31 clamps to Feb 28 without dragging later months', () {
      final anchor = DateTime(2026, 1, 31);
      expect(pmOccurrence(anchor, monthly, 1), DateTime(2026, 2, 28));
      expect(pmOccurrence(anchor, monthly, 2), DateTime(2026, 3, 31));
      expect(pmOccurrence(anchor, monthly, 3), DateTime(2026, 4, 30));
    });

    test('leap years clamp to Feb 29 / Feb 28', () {
      expect(
        pmOccurrence(DateTime(2028, 1, 31), monthly, 1),
        DateTime(2028, 2, 29),
      );
      expect(
        pmOccurrence(DateTime(2028, 2, 29), const PmStep.months(12), 1),
        DateTime(2029, 2, 28),
      );
    });

    test('quarterly from Nov 30 lands on Feb 28 then May 30', () {
      final anchor = DateTime(2025, 11, 30);
      expect(
        pmOccurrencesBetween(
          anchor,
          const PmStep.months(3),
          DateTime(2026, 1, 1),
          DateTime(2026, 12, 31),
        ),
        [
          DateTime(2026, 2, 28),
          DateTime(2026, 5, 30),
          DateTime(2026, 8, 30),
          DateTime(2026, 11, 30),
        ],
      );
    });

    test('time of day is ignored', () {
      expect(
        pmOccurrence(DateTime(2026, 3, 31, 23, 59), monthly, 1),
        DateTime(2026, 4, 30),
      );
    });
  });

  group('range filtering', () {
    test('weekly occurrences inside an inclusive range', () {
      expect(
        pmOccurrencesBetween(
          DateTime(2026, 10, 1),
          const PmStep.days(7),
          DateTime(2026, 10, 15),
          DateTime(2026, 10, 29),
        ),
        [
          DateTime(2026, 10, 15),
          DateTime(2026, 10, 22),
          DateTime(2026, 10, 29),
        ],
      );
    });

    test('the anchor itself only counts with kMin 0', () {
      final a = DateTime(2026, 10, 8);
      expect(pmOccurrencesBetween(a, const PmStep.days(7), a, a), isEmpty);
      expect(pmOccurrencesBetween(a, const PmStep.days(7), a, a, kMin: 0), [a]);
    });

    test('old anchors skip ahead to the range', () {
      expect(
        pmOccurrencesBetween(
          DateTime(2015, 1, 1),
          const PmStep.days(1),
          DateTime(2026, 10, 27),
          DateTime(2026, 10, 28),
        ),
        [DateTime(2026, 10, 27), DateTime(2026, 10, 28)],
      );
      expect(
        pmOccurrencesBetween(
          DateTime(2010, 6, 15),
          const PmStep.months(1),
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 31),
        ),
        [DateTime(2026, 10, 15)],
      );
    });

    test('a range before the first occurrence or reversed is empty', () {
      expect(
        pmOccurrencesBetween(
          DateTime(2026, 10, 1),
          const PmStep.months(1),
          DateTime(2026, 9, 1),
          DateTime(2026, 10, 31),
        ),
        isEmpty,
      );
      expect(
        pmOccurrencesBetween(
          DateTime(2026, 10, 1),
          const PmStep.days(1),
          DateTime(2026, 10, 10),
          DateTime(2026, 10, 9),
        ),
        isEmpty,
      );
    });

    test('last occurrence before a date', () {
      final anchor = DateTime(2026, 1, 1);
      expect(
        pmLastOccurrenceBefore(
          anchor,
          const PmStep.months(1),
          DateTime(2026, 3, 15),
        ),
        DateTime(2026, 3, 1),
      );
      expect(
        pmLastOccurrenceBefore(
          anchor,
          const PmStep.months(1),
          DateTime(2026, 3, 1),
        ),
        DateTime(2026, 2, 1),
      );
      expect(
        pmLastOccurrenceBefore(
          anchor,
          const PmStep.months(1),
          DateTime(2026, 1, 20),
        ),
        isNull,
      );
    });
  });

  group('computePmDue', () {
    final today = DateTime(2026, 10, 27, 9);
    final from = DateTime(2026, 10, 27);
    final to = DateTime(2026, 11, 30);

    test('skips equipment without frequency, inactive or retired', () {
      final due = computePmDue(
        equipments: [
          eq(1, installedAt: DateTime(2026, 1, 1)),
          eq(
            2,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2026, 1, 1),
            active: false,
          ),
          eq(
            3,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2026, 1, 1),
            status: EquipmentCondition.retired,
          ),
          eq(
            4,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2026, 1, 5),
          ),
        ],
        from: from,
        to: to,
        today: today,
      );
      expect(due.map((d) => d.equipmentId), [4]);
      expect(due.single.dueDate, DateTime(2026, 11, 5));
      expect(due.single.frequencyLabel, 'Monthly');
      expect(due.single.companyName, 'Croma - Madhapur');
      expect(due.single.location, 'Floor 4');
    });

    test('anchor falls back from visit to installed, manufacturer, created',
        () {
      List<DateTime> dates(
        Equipment e, [
        Map<int, PmVisit> visits = const {},
      ]) =>
          computePmDue(
            equipments: [e],
            lastVisits: visits,
            from: from,
            to: to,
            today: today,
          ).map((d) => d.dueDate).toList();

      final base = eq(
        1,
        frequency: TmFrequency.monthly,
        installedAt: DateTime(2026, 1, 3),
        manufacturerDate: DateTime(2025, 1, 4),
        createdAt: '2025-01-05T00:00:00.000Z',
      );
      expect(dates(base, {1: PmVisit(DateTime(2026, 10, 10))}), [
        DateTime(2026, 11, 10),
      ]);
      expect(dates(base), [DateTime(2026, 11, 3)]);
      expect(
        dates(
          eq(
            1,
            frequency: TmFrequency.monthly,
            manufacturerDate: DateTime(2025, 1, 4),
            createdAt: '2025-01-05T00:00:00.000Z',
          ),
        ),
        [DateTime(2026, 11, 4)],
      );
      expect(
        dates(
          eq(
            1,
            frequency: TmFrequency.monthly,
            createdAt: '2025-01-05T12:00:00.000',
          ),
        ),
        [DateTime(2026, 11, 5)],
      );
      expect(dates(eq(1, frequency: TmFrequency.monthly)), isEmpty);
    });

    test('schedule rows merge with equipment dates per equipment and day', () {
      final schedule = PmSchedule(
        id: '9',
        equipmentName: 'Old name',
        companyName: 'Croma',
        frequency: PmFrequency.monthly,
        nextDue: DateTime(2026, 11, 5),
        equipmentId: 4,
      );
      final due = computePmDue(
        equipments: [
          eq(
            4,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2026, 1, 5),
          ),
        ],
        schedules: [
          schedule,
          schedule.copyWith(
            id: '10',
            active: false,
            nextDue: DateTime(2026, 11, 6),
          ),
        ],
        from: from,
        to: to,
        today: today,
      );
      expect(due, hasLength(1));
      expect(due.single.fromEquipment, isTrue);
      expect(due.single.fromSchedule, isTrue);
      expect(due.single.equipmentName, 'Equipment 4');
    });

    test('schedules for unknown equipment still list', () {
      final due = computePmDue(
        equipments: const [],
        schedules: [
          PmSchedule(
            id: '1',
            equipmentName: 'Chiller',
            companyName: 'DMart',
            frequency: PmFrequency.quarterly,
            nextDue: DateTime(2026, 11, 1),
            equipmentId: 77,
          ),
        ],
        from: from,
        to: to,
        today: today,
      );
      expect(due.single.equipmentName, 'Chiller');
      expect(due.single.dueDate, DateTime(2026, 11, 1));
    });

    test('overdue needs a recorded visit and lists first', () {
      final due = computePmDue(
        equipments: [
          eq(
            1,
            frequency: TmFrequency.weekly,
            installedAt: DateTime(2026, 1, 1),
          ),
          eq(
            2,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2020, 1, 1),
          ),
        ],
        lastVisits: {2: PmVisit(DateTime(2026, 8, 20))},
        from: from,
        to: DateTime(2026, 11, 1),
        today: today,
        includeOverdue: true,
      );
      final overdue = due.where((d) => d.overdue).toList();
      expect(overdue, hasLength(1));
      expect(overdue.single.equipmentId, 2);
      expect(overdue.single.dueDate, DateTime(2026, 10, 20));
      expect(due.first.overdue, isTrue);
      expect(due.where((d) => d.equipmentId == 1).map((d) => d.dueDate), [
        DateTime(2026, 10, 29),
      ]);
    });

    test('an open PM visit counts itself as due', () {
      final due = computePmDue(
        equipments: [
          eq(
            1,
            frequency: TmFrequency.monthly,
            installedAt: DateTime(2026, 1, 1),
          ),
        ],
        lastVisits: {1: PmVisit(DateTime(2026, 10, 28), done: false)},
        from: from,
        to: to,
        today: today,
      );
      expect(due.map((d) => d.dueDate), [
        DateTime(2026, 10, 28),
        DateTime(2026, 11, 28),
      ]);
    });

    test('overdue schedule next_due is reported once', () {
      final due = computePmDue(
        equipments: const [],
        schedules: [
          PmSchedule(
            id: '1',
            equipmentName: 'Chiller',
            companyName: 'DMart',
            frequency: PmFrequency.monthly,
            nextDue: DateTime(2026, 10, 1),
            equipmentId: 5,
          ),
        ],
        from: from,
        to: to,
        today: today,
        includeOverdue: true,
      );
      expect(due.map((d) => (d.dueDate, d.overdue)), [
        (DateTime(2026, 10, 1), true),
        (DateTime(2026, 11, 1), false),
      ]);
    });

    test('today is highlighted', () {
      final due = computePmDue(
        equipments: [
          eq(
            1,
            frequency: TmFrequency.daily,
            installedAt: DateTime(2026, 10, 1),
          ),
        ],
        from: from,
        to: from,
        today: today,
      );
      expect(due.single.isToday(today), isTrue);
    });
  });

  group('lastPmVisits', () {
    ServiceTask task(
      int id,
      int equipmentId, {
      CallType callType = CallType.amcPreventiveMaintenance,
      TaskStatus status = TaskStatus.completed,
      ApprovalStage approval = ApprovalStage.completed,
      DateTime? due,
      DateTime? resolved,
    }) =>
        ServiceTask(
          id: id,
          ticketNo: 'T$id',
          status: status,
          callType: callType,
          approval: approval,
          dueDate: due,
          resolvedAt: resolved,
          equipment: eq(equipmentId),
        );

    test('uses the latest non-rejected PM task per equipment', () {
      final visits = lastPmVisits(
        tasks: [
          task(1, 1, resolved: DateTime(2026, 9, 1)),
          task(2, 1, resolved: DateTime(2026, 10, 2, 15)),
          task(
            3,
            1,
            callType: CallType.breakdown,
            resolved: DateTime(2026, 10, 20),
          ),
          task(
            4,
            1,
            approval: ApprovalStage.rejected,
            due: DateTime(2026, 10, 21),
          ),
          task(5, 2, status: TaskStatus.open, due: DateTime(2026, 11, 3)),
        ],
      );
      expect(visits[1]!.date, DateTime(2026, 10, 2));
      expect(visits[1]!.done, isTrue);
      expect(visits[2]!.date, DateTime(2026, 11, 3));
      expect(visits[2]!.done, isFalse);
    });

    test('includes generated PM visits', () {
      final g = PmGeneratedTask.fromBackend({
        'id': 1,
        'schedule_link': 2,
        'task_link': 3,
        'due_date': '2026-11-10T00:00:00.000',
        'task': {'id': 3, 'status': 'open'},
        'schedule': {
          'equipment_link': 8,
          'equipment': {'id': 8, 'name': 'Oven'},
        },
      });
      expect(g.equipmentId, 8);
      expect(g.taskStatus, TaskStatus.open);
      final visits = lastPmVisits(generated: [g]);
      expect(visits[8]!.date, DateTime(2026, 11, 10));
      expect(visits[8]!.done, isFalse);
    });
  });

  group('PmWindow', () {
    // 2026-10-27 is a Tuesday.
    final now = DateTime(2026, 10, 27, 18);

    test('tomorrow, this week (to Sunday) and this month', () {
      expect(
        PmWindow.tomorrow.range(now),
        (DateTime(2026, 10, 28), DateTime(2026, 10, 28)),
      );
      expect(
        PmWindow.week.range(now),
        (DateTime(2026, 10, 27), DateTime(2026, 11, 1)),
      );
      expect(
        PmWindow.month.range(now),
        (DateTime(2026, 10, 27), DateTime(2026, 10, 31)),
      );
    });

    test('Sunday and month/year ends', () {
      expect(
        PmWindow.week.range(DateTime(2026, 11, 1)),
        (DateTime(2026, 11, 1), DateTime(2026, 11, 1)),
      );
      expect(
        PmWindow.tomorrow.range(DateTime(2026, 12, 31)),
        (DateTime(2027, 1, 1), DateTime(2027, 1, 1)),
      );
      expect(
        PmWindow.month.range(DateTime(2028, 2, 10)).$2,
        DateTime(2028, 2, 29),
      );
    });

    test('only tomorrow hides overdue', () {
      expect(PmWindow.tomorrow.includesOverdue, isFalse);
      expect(PmWindow.week.includesOverdue, isTrue);
      expect(PmWindow.month.includesOverdue, isTrue);
    });
  });
}
