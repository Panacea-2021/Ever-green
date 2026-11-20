import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _amcCompanies = [
  Company(
    id: 1,
    name: 'NC AMC Co',
    serviceType: CompanyServiceType.amc,
    amcType: AmcType.ncAmc,
  ),
  Company(
    id: 2,
    name: 'C AMC Co',
    serviceType: CompanyServiceType.amc,
    amcType: AmcType.cAmc,
  ),
  Company(
    id: 3,
    name: 'Regular Co',
    serviceType: CompanyServiceType.regular,
  ),
  Company(
    id: 4,
    name: 'Non AMC Co',
    serviceType: CompanyServiceType.nonAmc,
  ),
  Company(
    id: 5,
    name: 'Plain AMC Co',
    serviceType: CompanyServiceType.amc,
  ),
];

Widget _screen() {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
      companiesProvider.overrideWith((ref) async => _amcCompanies),
    ],
    child: const MaterialApp(home: WebCompaniesScreen()),
  );
}

void main() {
  testWidgets('service badges drop the plain AMC marker', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('NC AMC'), findsOneWidget);
    expect(find.text('C AMC'), findsOneWidget);
    // "Regular" also appears as a filter-tile label, so allow multiple.
    expect(find.text('Regular'), findsWidgets);
    expect(find.text('Non-AMC'), findsOneWidget);
    // The plain "AMC" badge must not appear anywhere on the list page.
    expect(find.text('AMC'), findsNothing);
    // A company whose only service marker was the plain AMC shows the dash.
    expect(find.text('—'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
