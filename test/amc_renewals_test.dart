import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/amcs/domain/models/amc_contract.dart';

/// A production-shaped company row: `service_type` / `amc_type` NULL (created
/// before the field existed) but with contract dates.
Company legacyCompany({
  int id = 4,
  String? start = '2026-10-01T00:00:00.000Z',
  String? end = '2026-10-30T00:00:00.000Z',
  bool isActive = true,
}) {
  return Company.fromJson({
    'id': id,
    'name': 'sai testing',
    'branch_name': '9963477567',
    'email': 'co@x.com',
    'gst_number': '36AAAAA0000A1Z5',
    'location': 'Hyderabad',
    'logo': 'uploads/logo/a.png',
    'service_type': null,
    'amc_type': null,
    'start_date': start,
    'end_date': end,
    'is_active': isActive,
    'poc_details': null,
  });
}

void main() {
  final now = DateTime(2026, 10, 27, 9, 30);

  group('legacy AMC mapping (NULL service_type)', () {
    test('a NULL-service-type company with an end date is an AMC', () {
      final c = legacyCompany();
      expect(c.serviceType, isNull);
      expect(c.isLegacyAmc, isTrue);
      expect(c.isAmc, isTrue);

      final contract = AmcContract.fromCompany(c)!;
      expect(contract.id, '4');
      expect(contract.startDate, DateTime(2026, 10, 1));
      expect(contract.endDate, DateTime(2026, 10, 30));
      expect(contract.serviceType, 'AMC');
      expect(contract.amcCategory, '');
    });

    test('a NULL-service-type company without an end date is not', () {
      final c = legacyCompany(start: null, end: null);
      expect(c.isAmc, isFalse);
      expect(AmcContract.fromCompany(c), isNull);
    });

    test('explicit Non-AMC / Regular companies stay excluded', () {
      for (final type in ['non_amc', 'regular']) {
        final c = Company.fromJson({
          'id': 1,
          'name': 'X',
          'service_type': type,
          'end_date': '2026-10-30T00:00:00.000Z',
        });
        expect(c.isAmc, isFalse, reason: type);
        expect(AmcContract.fromCompany(c), isNull, reason: type);
      }
    });

    test('production rows: only "sai testing" is due for renewal', () {
      final contracts = amcContractsFrom([
        legacyCompany(id: 1, end: '2038-10-04T00:00:00.000Z'),
        legacyCompany(id: 2, end: '2033-10-03T00:00:00.000Z'),
        legacyCompany(id: 3, end: '2027-11-30T00:00:00.000Z'),
        legacyCompany(id: 4, end: '2026-10-30T00:00:00.000Z'),
      ]);
      expect(contracts, hasLength(4));
      final sai = contracts.singleWhere((c) => c.id == '4');
      expect(sai.daysUntilExpiry(now), 3);
      expect(sai.status(now), AmcStatus.expiringSoon);
      expect(
        contracts.where((c) => c.status(now) != AmcStatus.active).map((c) => c.id),
        ['4'],
      );
    });
  });

  group('expiry windows', () {
    AmcContract endingOn(String day) =>
        AmcContract.fromCompany(legacyCompany(end: '${day}T00:00:00.000Z'))!;

    test('ends today: expiring soon, 0 days', () {
      final c = endingOn('2026-10-27');
      expect(c.daysUntilExpiry(now), 0);
      expect(c.status(now), AmcStatus.expiringSoon);
    });

    test('30 days out is expiring soon, 31 is active', () {
      expect(endingOn('2026-11-26').status(now), AmcStatus.expiringSoon);
      expect(endingOn('2026-11-27').status(now), AmcStatus.active);
    });

    test('ended yesterday is expired', () {
      final c = endingOn('2026-10-26');
      expect(c.daysUntilExpiry(now), -1);
      expect(c.status(now), AmcStatus.expired);
    });

    test('renewalsFrom drops inactive companies and active contracts', () {
      final contracts = amcContractsFrom([
        legacyCompany(id: 1, end: '2099-01-01T00:00:00.000Z'),
        legacyCompany(id: 2, end: '2020-01-01T00:00:00.000Z'),
        legacyCompany(id: 3, end: '2020-01-01T00:00:00.000Z', isActive: false),
      ]);
      final due = renewalsFrom(contracts);
      expect(due.map((c) => c.id), ['2']);
    });
  });

  group('renewCompanyBody', () {
    test('legacy company: sends AMC service type, chosen AMC type, dates', () {
      final body = renewCompanyBody(
        legacyCompany(),
        startDate: DateTime(2026, 10, 30),
        endDate: DateTime(2027, 10, 30),
        amcType: AmcType.cAmc,
      );
      expect(body, {
        'company_name': 'sai testing',
        'branch_name': '9963477567',
        'service_type': 'amc',
        'amc_type': 'c_amc',
        'start_date': '2026-10-30',
        'end_date': '2027-10-30',
      });
    });

    test('never sends fields the backend would overwrite', () {
      final body = renewCompanyBody(
        legacyCompany(),
        startDate: DateTime(2026, 10, 30),
        endDate: DateTime(2027, 10, 30),
        amcType: AmcType.ncAmc,
      );
      for (final key in [
        'company_email',
        'company_location',
        'gst_number',
        'logo',
        'name',
        'phone',
        'email',
        'password',
      ]) {
        expect(body.containsKey(key), isFalse, reason: key);
      }
    });

    test('typed AMC company keeps its stored AMC type', () {
      final c = Company.fromJson({
        'id': 9,
        'name': 'A',
        'branch_name': 'B',
        'service_type': 'amc',
        'amc_type': 'nc_amc',
        'start_date': '2025-01-01T00:00:00.000Z',
        'end_date': '2025-12-31T00:00:00.000Z',
      });
      final body = renewCompanyBody(
        c,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      );
      expect(body['amc_type'], 'nc_amc');
      expect(body['service_type'], 'amc');
    });

    test('legacy company without a chosen AMC type is rejected', () {
      expect(
        () => renewCompanyBody(
          legacyCompany(),
          startDate: DateTime(2026, 10, 30),
          endDate: DateTime(2027, 10, 30),
        ),
        throwsArgumentError,
      );
    });

    test('end before start is rejected', () {
      expect(
        () => renewCompanyBody(
          legacyCompany(),
          startDate: DateTime(2027, 1, 1),
          endDate: DateTime(2026, 1, 1),
          amcType: AmcType.cAmc,
        ),
        throwsArgumentError,
      );
    });
  });

  group('addMonthsClamped', () {
    test('plain months', () {
      expect(addMonthsClamped(DateTime(2026, 10, 30), 12), DateTime(2027, 10, 30));
      expect(addMonthsClamped(DateTime(2026, 10, 30), 24), DateTime(2028, 10, 30));
    });

    test('clamps to the end of a shorter month', () {
      expect(addMonthsClamped(DateTime(2026, 8, 31), 6), DateTime(2027, 2, 28));
      expect(addMonthsClamped(DateTime(2027, 8, 31), 6), DateTime(2028, 2, 29));
      expect(addMonthsClamped(DateTime(2028, 2, 29), 12), DateTime(2029, 2, 28));
    });
  });
}
