import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart' hide TaskStatus;
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/issue_types/presentation/screens/issue_types_screen.dart';
import 'package:evergreen/features/pickers/presentation/screens/location_picker_screen.dart';
import 'package:evergreen/features/pickers/presentation/widgets/picker_scaffold.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/screens/task_board_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Company _company(int id, {String? location}) => Company.fromJson({
      'id': id,
      'name': 'Acme',
      'branch_name': 'HQ',
      'email': 'a@x.com',
      'location': location,
    });

Equipment _equipment(int id, String name, String? location) =>
    Equipment(id: id, name: name, egSerialNumber: 'EG-$id', location: location);

ServiceTask _task(int id, int companyId, String? location) =>
    ServiceTask.fromJson({
      'id': id,
      'ticket_no': '$id',
      'name': 'T',
      'description': '',
      'status': 'open',
      'location': location,
      'equipment': {
        'id': 100 + id,
        'name': 'E',
        'eg_serial_number': 'EG',
        'company_link': companyId,
      },
    });

void main() {
  group('ServiceType', () {
    test('equipment reads its service type', () {
      final e = Equipment.fromJson({
        'id': 1,
        'name': 'Chiller',
        'eg_serial_number': 'EG-1',
        'service_type': {'id': 3, 'name': 'Chiller AMC'},
      });
      expect(e.serviceType?.id, 3);
      expect(e.serviceType?.name, 'Chiller AMC');
      expect(
        Equipment.fromJson({'id': 2, 'name': 'X', 'eg_serial_number': 'E'})
            .serviceType,
        isNull,
      );
    });

    test('fromJson reads the active flag', () {
      final t =
          ServiceType.fromJson({'id': 1, 'name': 'A', 'is_active': false});
      expect(t.isActive, isFalse);
    });
  });

  group('companyLocations', () {
    test('merges branch, equipment and ticket locations without duplicates',
        () {
      final options = companyLocations(
        company: _company(1, location: 'Hyderabad'),
        equipment: [
          _equipment(1, 'Split AC', 'Block B'),
          _equipment(2, 'Fridge', ' block  b '),
          _equipment(3, 'Lift', null),
        ],
        tasks: [
          _task(1, 1, 'Server Room'),
          _task(2, 1, 'server room'),
          _task(3, 1, 'Block B'),
          _task(4, 2, 'Other company'),
        ],
      );
      expect(
        options.map((o) => o.location),
        ['Hyderabad', 'Block B', 'Server Room'],
      );
      expect(options[0].usedBy, ['Branch address']);
      expect(
        options[1].usedBy,
        ['Equipment: Split AC', 'Equipment: Fridge', '1 ticket'],
      );
      expect(options[2].usedBy, ['2 tickets']);
    });
  });

  group('PickerScaffold query row', () {
    Widget scaffold(List<String> items) => MaterialApp(
          home: PickerScaffold<String>(
            title: 'Pick',
            searchHint: 'Search',
            items: AsyncValue.data(items),
            matches: (i, q) => i.toLowerCase().contains(q),
            itemBuilder: (_, i) => Text('item $i'),
            onRetry: () {},
            emptyText: 'Nothing',
            queryItemBuilder: (_, q) => Text('use $q'),
          ),
        );

    testWidgets('offers the typed text even with no matches', (tester) async {
      await tester.pumpWidget(scaffold(['Block B']));
      expect(find.text('use Block C'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Block C');
      await tester.pump();
      expect(find.text('use Block C'), findsOneWidget);
      expect(find.text('No matches'), findsNothing);
      await tester.enterText(find.byType(TextField), 'block');
      await tester.pump();
      expect(find.text('use block'), findsOneWidget);
      expect(find.text('item Block B'), findsOneWidget);
    });

    testWidgets('empty list still allows typing a new one', (tester) async {
      await tester.pumpWidget(scaffold([]));
      expect(find.text('Nothing'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Roof');
      await tester.pump();
      expect(find.text('use Roof'), findsOneWidget);
    });
  });

  testWidgets('task board chips show counts per status', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    TaskItem item(String id, TaskStatus status) => TaskItem(
          id: id,
          title: 'Task $id',
          equipment: 'E',
          companyName: 'C',
          ticketNo: id,
          status: status,
          priority: TaskPriority.low,
          createdAt: DateTime.now(),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.manager),
          currentUserProvider.overrideWithValue(
            const User(id: '1', email: 'e', name: 'M', role: UserRole.manager),
          ),
          taskItemsProvider.overrideWithValue(
            AsyncValue.data([
              item('1', TaskStatus.open),
              item('2', TaskStatus.open),
              item('3', TaskStatus.hold),
            ]),
          ),
          deletedTasksProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: TaskBoardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    String count(String label) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(Key('taskStatusCount-$label')),
            matching: find.byType(Text),
          ),
        )
        .data!;
    expect(count('All'), '3');
    expect(count('Open'), '2');
    expect(count('Hold'), '1');
    expect(count('Closed'), '0');
    expect(count('Deleted'), '0');
    expect(
      find.descendant(
        of: find.byKey(const Key('taskCountHeader')),
        matching: find.text('All Tasks'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Service Types screen lists types', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allServiceTypesProvider.overrideWith(
            (ref) async => const [
              ServiceType(id: 1, name: 'Chiller AMC'),
              ServiceType(id: 2, name: 'Lift AMC', isActive: false),
            ],
          ),
        ],
        child: const MaterialApp(home: ServiceTypesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Service Types'), findsOneWidget);
    expect(find.text('New Service Type'), findsOneWidget);
    expect(find.byKey(const Key('serviceType-1')), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addServiceType')));
    await tester.pumpAndSettle();
    expect(find.text('New service type'), findsOneWidget);
    expect(find.byKey(const Key('serviceTypeNameField')), findsOneWidget);
  });
}
