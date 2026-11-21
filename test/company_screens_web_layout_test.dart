import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/amcs/presentation/screens/company_equipments_screen.dart';
import 'package:evergreen/features/amcs/presentation/screens/company_tasks_screen.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _company = Company(id: 1, name: 'Example Company');
const _equipment = Equipment(
  id: 10,
  name: 'Leaky Tap',
  egSerialNumber: 'EG-10',
  companyId: 1,
  company: _company,
  make: 'Acme',
  model: 'X1',
  location: 'Kitchen',
);
const _tasks = [
  ServiceTask(
    id: 100,
    ticketNo: 'TCK-100',
    name: 'Leaky tap repair',
    status: TaskStatus.open,
    equipment: _equipment,
  ),
  ServiceTask(
    id: 101,
    ticketNo: 'TCK-101',
    name: 'Filter replacement',
    status: TaskStatus.closed,
    equipment: _equipment,
  ),
];

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
      ...overrides,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('company tasks hides the in-card header on web', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const CompanyTasksScreen(
          companyId: '1',
          companyName: 'Example Company',
        ),
        [tasksProvider.overrideWith((ref) async => _tasks)],
      ),
    );
    await tester.pumpAndSettle();

    // Only the frame's top bar should carry the page heading on web; the
    // mobile layout keeps its own header.
    expect(
      find.text('Company Tasks'),
      kIsWeb ? findsNothing : findsOneWidget,
    );
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Leaky tap repair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company tasks shows a compact empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const CompanyTasksScreen(companyId: '1'),
        [tasksProvider.overrideWith((ref) async => const <ServiceTask>[])],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tasks'), findsOneWidget);
    expect(
      find.text('Company Tasks'),
      kIsWeb ? findsNothing : findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('company equipment hides the in-card header on web',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const CompanyEquipmentsScreen(
          companyId: '1',
          companyName: 'Example Company',
        ),
        [equipmentsProvider(1).overrideWith((ref) async => const [_equipment])],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Equipments'),
      kIsWeb ? findsNothing : findsOneWidget,
    );
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Leaky Tap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
