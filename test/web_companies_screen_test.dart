import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _companies = [
  Company(
    id: 1,
    name: 'Active Company',
    serviceType: CompanyServiceType.regular,
  ),
  Company(
    id: 2,
    name: 'Inactive One',
    serviceType: CompanyServiceType.regular,
    isActive: false,
  ),
  Company(
    id: 3,
    name: 'Inactive Two',
    serviceType: CompanyServiceType.regular,
    isActive: false,
  ),
];

Widget _screen() {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
      companiesProvider.overrideWith((ref) async => _companies),
    ],
    child: const MaterialApp(home: WebCompaniesScreen()),
  );
}

void main() {
  testWidgets('companies screen loads and lays out its web grid',
      (tester) async {
    tester.view.physicalSize = const Size(760, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Active Company'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inactive card shows the API count and filters the list',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    final allTile = find.byKey(const ValueKey('web-filter-All'));
    final inactiveTile = find.byKey(const ValueKey('web-filter-Inactive'));
    expect(allTile, findsOneWidget);
    expect(inactiveTile, findsOneWidget);
    expect(
      find.descendant(of: allTile, matching: find.text('3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inactiveTile, matching: find.text('2')),
      findsOneWidget,
    );

    // Only inactive companies remain after selecting the card.
    await tester.tap(inactiveTile);
    await tester.pumpAndSettle();
    expect(find.text('Active Company'), findsNothing);
    expect(find.text('Inactive One'), findsOneWidget);
    expect(find.text('Inactive Two'), findsOneWidget);

    // Back to All restores every company.
    await tester.tap(allTile);
    await tester.pumpAndSettle();
    expect(find.text('Active Company'), findsOneWidget);
    expect(find.text('Inactive One'), findsOneWidget);
    expect(find.text('Inactive Two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('six cards stay in one scrollable row on narrower screens',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    const labels = ['All', 'C-AMC', 'NC-AMC', 'Non AMC', 'Regular', 'Inactive'];
    for (final label in labels) {
      expect(find.byKey(ValueKey('web-filter-$label')), findsOneWidget);
    }

    final firstRowTop =
        tester.getTopLeft(find.byKey(const ValueKey('web-filter-All'))).dy;
    for (final label in labels) {
      expect(
        tester.getTopLeft(find.byKey(ValueKey('web-filter-$label'))).dy,
        firstRowTop,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
