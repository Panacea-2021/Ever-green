import 'dart:async';

import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:evergreen/features/auth/domain/repositories/auth_repository.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/notifications/data/notifications_provider.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/widgets/web_module_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _PendingAuthRepository implements AuthRepository {
  @override
  Future<bool> isAuthenticated() => Completer<bool>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthenticatedStateNotifier extends AuthStateNotifier {
  _AuthenticatedStateNotifier(super.ref) {
    state = const AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: '1',
        email: 'admin@example.com',
        name: 'Admin User',
        role: UserRole.superAdmin,
      ),
    );
  }
}

void main() {
  testWidgets('dashboard notification and profile buttons open their pages',
      (tester) async {
    final router = GoRouter(
      initialLocation: Routes.webDashboard,
      routes: [
        GoRoute(
          path: Routes.webDashboard,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (context, state) =>
              const Scaffold(body: Text('Notification page')),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) =>
              const Scaffold(body: Text('Profile page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_PendingAuthRepository()),
          authStateProvider.overrideWith(
            (ref) => _AuthenticatedStateNotifier(ref),
          ),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => WebModuleFrame(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('web-notifications-button')));
    await tester.pumpAndSettle();
    expect(find.text('Notification page'), findsOneWidget);

    router.go(Routes.webDashboard);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
  });
}
