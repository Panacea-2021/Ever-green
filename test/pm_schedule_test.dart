import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/features/pm/domain/models/pm_schedule.dart';

void main() {
  test('frequencies map to the backend pm_frequency values', () {
    expect(PmFrequency.monthly.backendKey, 'monthly');
    expect(PmFrequency.quarterly.backendKey, 'quarterly');
    expect(PmFrequency.halfYearly.backendKey, 'half_yearly');
    expect(PmFrequency.yearly.backendKey, 'yearly');
    expect(PmFrequencyX.fromKey('half_yearly'), PmFrequency.halfYearly);
    expect(PmFrequencyX.fromKey('halfYearly'), PmFrequency.halfYearly);
  });

  test('schedule row from getPmSchedules', () {
    final s = PmSchedule.fromBackend({
      'id': 5,
      'equipment_link': 9,
      'frequency': 'half_yearly',
      'next_due': '2026-11-01T00:00:00.000Z',
      'is_active': false,
      'equipment': {
        'id': 9,
        'name': 'Chiller',
        'company': {'id': 1, 'name': 'Croma', 'branch_name': 'Madhapur'},
      },
    });
    expect(s.id, '5');
    expect(s.equipmentId, 9);
    expect(s.equipmentName, 'Chiller');
    expect(s.companyName, 'Croma - Madhapur');
    expect(s.frequency, PmFrequency.halfYearly);
    expect(s.active, isFalse);
    expect(s.isDue(DateTime(2026, 12, 1)), isFalse);
  });

  test('active schedule past its next due is due', () {
    final s = PmSchedule.fromBackend({
      'id': 1,
      'frequency': 'monthly',
      'next_due': '2026-10-01T00:00:00.000Z',
    });
    expect(s.active, isTrue);
    expect(s.isDue(DateTime(2026, 10, 27)), isTrue);
  });

  test('generated row with flat or nested names', () {
    final flat = PmGeneratedTask.fromBackend({
      'id': 3,
      'schedule_link': 5,
      'task_link': 77,
      'due_date': '2026-10-20T00:00:00.000Z',
      'generated_at': '2026-10-27T00:00:00.000Z',
      'equipment_name': 'Chiller',
      'company_name': 'Croma',
    });
    expect(flat.scheduleId, '5');
    expect(flat.taskId, 77);
    expect(flat.equipmentName, 'Chiller');
    expect(flat.companyName, 'Croma');

    final nested = PmGeneratedTask.fromBackend({
      'id': 4,
      'schedule_link': 5,
      'due_date': '2026-10-20T00:00:00.000Z',
      'schedule': {
        'equipment': {
          'name': 'Oven',
          'company': {'id': 1, 'name': 'DMart'},
        },
      },
    });
    expect(nested.equipmentName, 'Oven');
    expect(nested.companyName, 'DMart');
  });
}
