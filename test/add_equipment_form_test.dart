import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/amcs/presentation/screens/add_equipment_screen.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAdd(
  WidgetTester tester, {
  String companyId = '3',
  List<Company> companies = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.manager),
        serviceTypesProvider.overrideWith((ref) async => const []),
        companiesProvider.overrideWith((ref) async => companies),
      ],
      child: MaterialApp(home: AddEquipmentScreen(companyId: companyId)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openYearPicker(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Manufacturer Year'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Manufacturer Year'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('placeholders say Equipment Name and Location', (tester) async {
    await _pumpAdd(tester);
    expect(find.text('Equipment Name'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Fridge'), findsNothing);
    expect(find.text('Hyderabad'), findsNothing);
  });

  testWidgets('company picker displays available companies', (tester) async {
    await _pumpAdd(
      tester,
      companyId: 'new',
      companies: const [Company(id: 1, name: 'Evergreen Foods')],
    );
    await tester.ensureVisible(find.text('Company'));
    await tester.tap(find.text('Company').first);
    await tester.pumpAndSettle();

    expect(find.text('Select Company'), findsOneWidget);
    expect(find.text('Evergreen Foods'), findsOneWidget);
  });

  testWidgets('manufacturer year picker scrolls back to older years',
      (tester) async {
    await _pumpAdd(tester);
    await _openYearPicker(tester);
    expect(find.byType(YearPicker), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('1995'),
      -300,
      scrollable: find.descendant(
        of: find.byType(YearPicker),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('1995'));
    await tester.pumpAndSettle();
    expect(find.byType(YearPicker), findsNothing);
    expect(find.text('1995'), findsOneWidget);
  });

  testWidgets('saving without an image asks for one', (tester) async {
    await _pumpAdd(tester);
    await tester.enterText(find.byType(TextField).first, 'Chiller');
    await _openYearPicker(tester);
    await tester.tap(find.text('${DateTime.now().year}'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Please upload an equipment image'), findsOneWidget);
    expect(find.text('Choose One'), findsOneWidget);
  });
}
