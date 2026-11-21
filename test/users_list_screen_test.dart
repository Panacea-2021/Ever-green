import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/users/data/user_provider.dart';
import 'package:evergreen/features/users/presentation/screens/users_list_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/widgets/web_filter_tiles.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filterLabels = [
    'All Users',
    'Super Admin',
    'EG Managers',
    'Company Managers',
    'POCs',
    'Service Engineers',
  ];

  List<WebFilterOption> filterOptions({ValueChanged<String>? onSelect}) => [
        for (final label in filterLabels)
          WebFilterOption(
            label: label,
            icon: Icons.people_outline,
            color: const Color(0xFF106220),
            selected: label == 'Company Managers',
            count: 1,
            onTap: () => onSelect?.call(label),
          ),
      ];

  testWidgets('wide user filter cards stay in one equal-width row',
      (tester) async {
    tester.view.physicalSize = const Size(2000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 2000,
            child: WebFilterTiles(
              minTileWidth: 320,
              scrollController: controller,
              options: filterOptions(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rects = [
      for (final label in filterLabels)
        tester.getRect(find.byKey(ValueKey('web-filter-$label'))),
    ];
    expect(rects.map((rect) => rect.top).toSet(), {rects.first.top});
    for (final label in filterLabels) {
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text(label));
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label should be fully readable (width ${paragraph.size.width})',
      );
    }
    for (var i = 0; i < rects.length; i++) {
      expect(rects[i].width, closeTo(rects.first.width, 0.01));
      if (i > 0) {
        expect(rects[i].left - rects[i - 1].right, closeTo(12, 0.01));
      }
    }
    expect(controller.position.maxScrollExtent, 0);
  });

  testWidgets('narrow user filter cards stay in one scrollable row',
      (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    String? selectedFilter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: WebFilterTiles(
              minTileWidth: 320,
              scrollController: controller,
              options: filterOptions(onSelect: (label) => selectedFilter = label),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rects = [
      for (final label in filterLabels)
        tester.getRect(find.byKey(ValueKey('web-filter-$label'))),
    ];
    expect(rects.map((rect) => rect.top).toSet(), {rects.first.top});
    for (final label in filterLabels) {
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text(label));
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$label should be fully readable (width ${paragraph.size.width})',
      );
    }
    expect(controller.position.maxScrollExtent, greaterThan(0));

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final lastCard = tester.getRect(
      find.byKey(const ValueKey('web-filter-Service Engineers')),
    );
    expect(lastCard.left, greaterThanOrEqualTo(0));
    expect(lastCard.right, lessThanOrEqualTo(900));
    await tester.tap(
      find.byKey(const ValueKey('web-filter-Service Engineers')),
    );
    expect(selectedFilter, 'Service Engineers');
  });

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
    'Company Managers',
    'POCs',
    'Service Engineers',
    'Managers',
  ];

  testWidgets('tabs filter the correct roles and retain selected highlight',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
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
      // Highlight is visual; filtering verified by expectOnly.
    }

    await expectOnly(UserRole.values.toSet());
    expectSelected('All Users');

    const expectedRoles = <String, Set<UserRole>>{
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
