import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/search/domain/global_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final company = Company.fromJson({
    'id': 1,
    'name': 'Apollo Hospitals',
    'branch_name': 'Jubilee Hills',
    'location': 'Hyderabad',
    'gst_number': '36AABCA1234F1Z5',
    'service_type': 'amc',
    'poc_details': {
      'user': {'id': 9, 'name': 'Ravi Kumar', 'phone': '9876543210'},
    },
  });

  final equipment = Equipment.fromJson({
    'id': 5,
    'name': 'MRI Scanner',
    'make': 'Siemens',
    'model': 'Magnetom',
    'serial_number': 'SN-777',
    'eg_serial_number': 'EG-0042',
    'location': 'Radiology',
    'company': {'id': 1, 'name': 'Apollo Hospitals', 'branch_name': ''},
  });

  final companyTask = ServiceTask.fromJson({
    'id': 30,
    'status': 'in_progress',
    'technician': {'id': 4, 'name': 'Suresh Reddy', 'phone': '9000000001'},
    'task': {
      'id': 11,
      'ticket_no': 'TKT-1001',
      'name': 'Coil failure',
      'description': 'Head coil not detected',
      'equipment': {
        'id': 5,
        'name': 'MRI Scanner',
        'eg_serial_number': 'EG-0042',
        'company': {'id': 1, 'name': 'Apollo Hospitals'},
      },
    },
  });

  final individualTask = ServiceTask.fromJson({
    'id': 31,
    'status': 'open',
    'task': {
      'id': 12,
      'ticket_no': 'TKT-1002',
      'name': 'Home ventilator check',
      'description': '',
      'contact_name': 'Lakshmi Devi',
      'contact_phone': '9123456789',
      'address': 'Banjara Hills, Road 12',
    },
  });

  const engineer = User(
    id: '4',
    email: 'suresh@evergreen.in',
    name: 'Suresh Reddy',
    phone: '9000000001',
    role: UserRole.technician,
    designation: 'Junior Technician',
  );

  group('matchesQuery', () {
    test('blank query matches everything', () {
      expect(matchesQuery('', const ['x']), isTrue);
      expect(matchesQuery('   ', const [null]), isTrue);
    });

    test('is case-insensitive', () {
      expect(matchesQuery('APOLLO', const ['Apollo Hospitals']), isTrue);
      expect(matchesQuery('apollo', const ['APOLLO']), isTrue);
    });

    test('every word must appear, in any field', () {
      expect(
        matchesQuery('apollo hyderabad', const ['Apollo', 'Hyderabad']),
        isTrue,
      );
      expect(
        matchesQuery('apollo chennai', const ['Apollo', 'Hyderabad']),
        isFalse,
      );
    });

    test('ignores null and empty fields', () {
      expect(matchesQuery('a', const [null, '']), isFalse);
    });

    test('a word does not match across two fields', () {
      expect(matchesQuery('ab', const ['a', 'b']), isFalse);
    });
  });

  group('company fields', () {
    for (final q in [
      'apollo',
      'jubilee',
      'hyderabad',
      '36aabca',
      'amc',
      'ravi',
      '98765',
    ]) {
      test('match "$q"', () {
        expect(matchesQuery(q, companySearchFields(company)), isTrue);
      });
    }
  });

  group('equipment fields', () {
    for (final q in [
      'mri',
      'siemens',
      'magnetom',
      'sn-777',
      'eg-0042',
      'radiology',
      'apollo',
    ]) {
      test('match "$q"', () {
        expect(matchesQuery(q, equipmentSearchFields(equipment)), isTrue);
      });
    }

    test('falls back to the looked-up company name', () {
      final bare = Equipment.fromJson(
        {'id': 6, 'name': 'X-Ray', 'eg_serial_number': 'EG-1'},
      );
      expect(matchesQuery('fortis', equipmentSearchFields(bare)), isFalse);
      expect(
        matchesQuery(
          'fortis',
          equipmentSearchFields(bare, companyName: 'Fortis'),
        ),
        isTrue,
      );
    });
  });

  group('task fields', () {
    for (final q in [
      'tkt-1001',
      'coil failure',
      'head coil',
      'apollo',
      'mri',
      'in progress',
      'suresh',
    ]) {
      test('company task matches "$q"', () {
        expect(matchesQuery(q, taskSearchFields(companyTask)), isTrue);
      });
    }

    for (final q in ['lakshmi', '91234', 'banjara', 'tkt-1002']) {
      test('individual task matches contact "$q"', () {
        expect(matchesQuery(q, taskSearchFields(individualTask)), isTrue);
      });
    }

    test('reads contact details from the nested task row', () {
      final c = taskContact(individualTask);
      expect(c.name, 'Lakshmi Devi');
      expect(c.phone, '9123456789');
      expect(c.address, 'Banjara Hills, Road 12');
      expect(taskContact(companyTask).name, isNull);
    });
  });

  group('service engineer fields', () {
    for (final q in ['suresh', '90000', 'suresh@evergreen', 'junior service']) {
      test('match "$q"', () {
        expect(matchesQuery(q, engineerSearchFields(engineer)), isTrue);
      });
    }

    test('never exposes the legacy "Technician" designation', () {
      expect(engineerDesignation(engineer), 'Junior Service Engineer');
      expect(
        matchesQuery('technician', engineerSearchFields(engineer)),
        isFalse,
      );
    });
  });

  test('filterByQuery keeps order and returns all items for a blank query', () {
    final items = ['Beta', 'alpha', 'Alphabet'];
    String? self(String s) => s;
    expect(filterByQuery(items, '', (s) => [self(s)]), items);
    expect(
      filterByQuery(items, 'ALPHA', (s) => [self(s)]),
      ['alpha', 'Alphabet'],
    );
  });

  group('searchTabsFor', () {
    const all = [
      SearchTab.companies,
      SearchTab.equipments,
      SearchTab.tasks,
      SearchTab.serviceEngineers,
    ];

    test('admins and managers see every tab', () {
      expect(searchTabsFor(UserRole.superAdmin), all);
      expect(searchTabsFor(UserRole.manager), all);
    });

    test('senior service engineers have no companies tab', () {
      expect(searchTabsFor(UserRole.seniorTechnician), [
        SearchTab.equipments,
        SearchTab.tasks,
        SearchTab.serviceEngineers,
      ]);
    });

    test('junior service engineers see equipment and tasks only', () {
      expect(
        searchTabsFor(UserRole.technician),
        [SearchTab.equipments, SearchTab.tasks],
      );
    });

    test('clients have no service engineers tab', () {
      for (final role in [UserRole.client, UserRole.clientAdmin]) {
        expect(searchTabsFor(role), [
          SearchTab.companies,
          SearchTab.equipments,
          SearchTab.tasks,
        ]);
      }
    });

    test('no tab label says "Technician"', () {
      for (final t in SearchTab.values) {
        expect(t.label.toLowerCase(), isNot(contains('technician')));
      }
    });
  });
}
