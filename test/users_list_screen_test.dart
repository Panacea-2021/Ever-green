import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/users/data/user_provider.dart';
import 'package:evergreen/features/users/presentation/screens/users_list_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewer = User(
    id: 'viewer',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.superAdmin,
  );
  final users = [
    for (final role in UserRole.values)
      User(
        id: role.name,
        email: '${role.name}@example.com',
        name: '${role.name} user',
        role: role,
      ),
  ];
  const tabs = [
    'All Users',
    'EG Managers',
    'Company Managers',
    'POCs',
    'Service Engineers',
  ];

  testWidgets('tabs filter the correct roles and retain selected highlight',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
          currentUserProvider.overrideWithValue(viewer),
          usersListProvider.overrideWith((ref) async => users),
        ],
        child: const MaterialApp(
          home: UsersListScreen(initialTab: kIsWeb ? 0 : -1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> expectOnly(Set<UserRole> roles) async {
      for (final role in UserRole.values) {
        final name = '${role.name} user';
        if (roles.contains(role)) {
          expect(
            find.descendant(
              of: find.byType(ListView),
              matching: find.text(name),
            ),
            findsOneWidget,
          );
        } else {
          expect(find.text(name), findsNothing);
        }
      }
    }

    void expectSelected(String selected) {
      for (final tab in tabs) {
        final text = find.text(tab).first;
        final container = find.ancestor(
          of: text,
          matching: find.byType(AnimatedContainer),
        );
        if (kIsWeb) {
          expect(
            find.descendant(
              of: container.first,
              matching: find.byIcon(Icons.check_circle),
            ),
            tab == selected ? findsOneWidget : findsNothing,
            reason: '$tab selection',
          );
        } else {
          final decoration = tester
              .widget<AnimatedContainer>(container.first)
              .decoration! as BoxDecoration;
          expect(
            decoration.color,
            tab == selected ? const Color(0xFF11682E) : Colors.white,
            reason: '$tab selection',
          );
        }
      }
    }

    await expectOnly(UserRole.values.toSet());
    expectSelected('All Users');

    const expectedRoles = <String, Set<UserRole>>{
      'EG Managers': {UserRole.superAdmin, UserRole.manager},
      'Company Managers': {UserRole.clientAdmin},
      'POCs': {UserRole.client},
      'Service Engineers': {
        UserRole.seniorTechnician,
        UserRole.technician,
        UserRole.coldRoomTechnician,
      },
    };

    for (final entry in expectedRoles.entries) {
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();
      await expectOnly(entry.value);
      expectSelected(entry.key);
    }

    await tester.tap(find.text('All Users').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'clientAdmin user',
    );
    await tester.pumpAndSettle();
    await expectOnly({UserRole.clientAdmin});
    expectSelected('All Users');
  });
}
