import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/amcs/data/equipment_provider.dart';
import 'package:evergreen/features/amcs/domain/models/equipment_item.dart';

void main() {
  group('EquipmentItem.fromEquipment', () {
    test('maps backend row, status, type and installed_at', () {
      final item = EquipmentItem.fromEquipment(
        Equipment.fromJson({
          'id': 7,
          'name': 'Fridge',
          'make': 'LG',
          'model': 'X1',
          'eg_serial_number': 'EG-ABC',
          'status': 'under_maintenance',
          'type': 'Refrigeration',
          'installed_at': '2026-01-15T00:00:00.000Z',
          'company': {'id': 2, 'name': 'DMart', 'branch_name': 'Kukatpally'},
        }),
      );
      expect(item.id, '7');
      expect(item.type, 'Refrigeration');
      expect(item.serialNumber, 'EG-ABC');
      expect(item.companyName, 'DMart - Kukatpally');
      expect(item.status, EquipmentStatus.underMaintenance);
      expect(item.status.label, 'Under Maintenance');
      expect(item.installedAt.toUtc(), DateTime.utc(2026, 1, 15));
    });

    test('every backend status maps to its design status', () {
      const expected = {
        'operational': EquipmentStatus.operational,
        'under_maintenance': EquipmentStatus.underMaintenance,
        'faulty': EquipmentStatus.faulty,
        'retired': EquipmentStatus.retired,
      };
      expected.forEach((key, status) {
        final item = EquipmentItem.fromEquipment(
          Equipment.fromJson({'id': 1, 'name': 'AC', 'status': key}),
        );
        expect(item.status, status);
        expect(item.status.condition.key, key);
      });
    });

    test('missing status and type fall back to operational and make/model', () {
      final item = EquipmentItem.fromEquipment(
        Equipment.fromJson({
          'id': 1,
          'name': 'AC',
          'make': 'Daikin',
          'eg_serial_number': 'EG-1',
        }),
      );
      expect(item.status, EquipmentStatus.operational);
      expect(item.status.label, 'Operational');
      expect(item.type, 'Daikin');
    });
  });

  group('parseEquipmentCode', () {
    test('bare id as encoded by the backend sticker', () {
      expect(parseEquipmentCode(' 42 '), '42');
    });

    test('serial numbers pass through', () {
      expect(parseEquipmentCode('EG-26Q48TZZL0'), 'EG-26Q48TZZL0');
    });

    test('URLs use the id query parameter or last path segment', () {
      expect(parseEquipmentCode('https://x.com/equipment?id=9'), '9');
      expect(parseEquipmentCode('https://x.com/equipment/15'), '15');
    });

    test('JSON payloads', () {
      expect(parseEquipmentCode('{"equipment_link": 3}'), '3');
      expect(parseEquipmentCode('{"foo": 1}'), isNull);
    });

    test('empty values are rejected', () {
      expect(parseEquipmentCode('   '), isNull);
    });
  });
}
