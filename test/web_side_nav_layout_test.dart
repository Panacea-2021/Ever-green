import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/shared/widgets/app_drawer.dart'
    show drawerCompaniesCountProvider, drawerUsersCountProvider;
import 'package:evergreen/web/widgets/web_side_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web side navigation scrolls within short and narrow viewports',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in [
      const Size(1280, 800),
      const Size(320, 480),
      const Size(900, 480),
      const Size(900, 1),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
            drawerCompaniesCountProvider.overrideWithValue(0),
            drawerUsersCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: Row(
              children: [
                WebSideNav(
                  activeRoute: '/dashboard',
                  onNavigate: (_) {},
                  onSignOut: () async {},
                ),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final navScroll = find.descendant(
        of: find.byType(WebSideNav),
        matching: find.byType(Scrollable),
      );
      expect(navScroll, findsOneWidget);
      expect(
        tester.state<ScrollableState>(navScroll).position.maxScrollExtent,
        greaterThan(0),
      );
    }
  });
}
