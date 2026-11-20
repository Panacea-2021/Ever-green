import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/amcs/domain/models/amc_contract.dart';

String _day(DateTime d) => apiDate(d);

Company company({
  required int id,
  String serviceType = 'amc',
  String? amcType = 'c_amc',
  int? endInDays,
  bool isActive = true,
}) {
  final today = DateTime.now();
  final end = endInDays == null
      ? null
      : DateTime(today.year, today.month, today.day + endInDays);
  return Company.fromJson({
    'id': id,
    'name': 'Co $id',
    'branch_name': 'HQ',
    'service_type': serviceType,
    'amc_type': amcType,
    'start_date': end == null
        ? null
        : '${_day(end.subtract(const Duration(days: 365)))}T00:00:00.000Z',
    'end_date': end == null ? null : '${_day(end)}T00:00:00.000Z',
    'is_active': isActive,
    'poc_details': {
      'user': {'name': 'POC', 'phone': '9999999999', 'email': 'p@x.com'},
    },
  });
}

void main() {
  group('AmcContract.fromCompany', () {
    test('maps an AMC company with dates', () {
      final c = AmcContract.fromCompany(company(id: 7, endInDays: 10))!;
      expect(c.id, '7');
      expect(c.companyId, 7);
      expect(c.amcCategory, 'C AMC');
      expect(c.pocName, 'POC');
      expect(c.daysUntilExpiry(), 10);
      expect(c.status(), AmcStatus.expiringSoon);
    });

    test('reads the calendar day from the raw UTC date', () {
      final c = AmcContract.fromCompany(company(id: 1, endInDays: 0))!;
      expect(c.daysUntilExpiry(), 0);
    });

    test('skips Non-AMC, Regular and undated companies', () {
      expect(
        AmcContract.fromCompany(
          company(id: 1, serviceType: 'non_amc', amcType: null),
        ),
        isNull,
      );
      expect(
        AmcContract.fromCompany(
          company(id: 2, serviceType: 'regular', amcType: null),
        ),
        isNull,
      );
      expect(AmcContract.fromCompany(company(id: 3)), isNull);
    });
  });

  group('renewals', () {
    test('keeps active companies expiring or expired, soonest first', () {
      final contracts = amcContractsFrom([
        company(id: 1, endInDays: 200),
        company(id: 2, endInDays: 5),
        company(id: 3, endInDays: -3),
        company(id: 4, endInDays: -1, isActive: false),
      ]);
      final due = renewalsFrom(contracts);
      expect(due.map((c) => c.id), ['3', '2']);
    });
  });

  group('CompanyInput', () {
    test('AMC body carries type and dates', () {
      final body = CompanyInput(
        name: 'A',
        branchName: 'B',
        serviceType: CompanyServiceType.amc,
        amcType: AmcType.ncAmc,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ).toBody();
      expect(body['service_type'], 'amc');
      expect(body['amc_type'], 'nc_amc');
      expect(body['start_date'], '2026-01-01');
      expect(body['end_date'], '2026-12-31');
    });

    test('Non-AMC body never carries type or dates', () {
      final body = CompanyInput(
        name: 'A',
        branchName: 'B',
        serviceType: CompanyServiceType.regular,
        amcType: AmcType.cAmc,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ).toBody();
      expect(body['service_type'], 'regular');
      expect(body.containsKey('amc_type'), isFalse);
      expect(body.containsKey('start_date'), isFalse);
      expect(body.containsKey('end_date'), isFalse);
    });
  });
}
