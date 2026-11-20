import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('companies screen loads and lays out its web grid',
      (tester) async {
    tester.view.physicalSize = const Size(760, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
          companiesProvider.overrideWith(
            (ref) async => const [
              Company(
                id: 1,
                name: 'Example Company',
                serviceType: CompanyServiceType.regular,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: WebCompaniesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Example Company'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
