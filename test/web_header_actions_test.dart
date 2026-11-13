import 'package:evergreen/core/errors/failures.dart';
import 'package:evergreen/core/config/environment_config.dart';
import 'package:evergreen/core/network/api_client.dart';
import 'package:evergreen/core/push/push_service.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/core/storage/token_storage.dart';
import 'package:evergreen/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/auth/domain/repositories/auth_repository.dart';
import 'package:evergreen/features/auth/presentation/providers/auth_provider.dart';
import 'package:evergreen/features/notifications/data/notifications_provider.dart';
import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/shared/widgets/app_drawer.dart'
    show drawerCompaniesCountProvider, drawerUsersCountProvider;
import 'package:evergreen/web/widgets/web_module_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

class _MemoryNotificationsRepository implements NotificationsRepository {
  _MemoryNotificationsRepository(this.items);

  final List<NotificationEntry> items;

  @override
  Future<(List<NotificationEntry>, bool)> getPage(int page) async =>
      (List.of(items), false);

  @override
  Future<void> markRead({List<int>? ids}) async {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (ids == null || ids.contains(item.notification.id)) {
        items[index] = item.markedRead();
      }
    }
  }

  @override
  Future<int> getUnreadCount() async =>
      items.where((item) => !item.notification.isRead).length;
}

class _AuthenticatedRepository implements AuthRepository {
  _AuthenticatedRepository(this.user);

  final User user;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Either<Failure, User>> getCurrentUser() async => Right(user);

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingAuthController extends AuthController {
  _RecordingAuthController(super.ref, this.onLogout);

  final VoidCallback onLogout;

  @override
  Future<void> logout() async => onLogout();
}

class _NoopPushService extends PushService {
  _NoopPushService(super.apiClient, super.tokenStorage);

  @override
  Future<void> registerForUser() async {}
}

void main() {
  const user = User(
    id: 'user-42',
    name: 'Jordan Green',
    email: 'jordan@example.com',
    phone: '+1 555 0100',
    role: UserRole.manager,
  );

  testWidgets('notification panel shows real feed data and marks it read',
      (tester) async {
    final repository = _MemoryNotificationsRepository([
      NotificationEntry(
        AppNotification(
          id: 7,
          title: 'Repair update',
          description: 'A repair booking needs attention.',
          isRead: false,
          createdAt: DateTime(2026, 5, 10, 9, 30),
        ),
      ),
    ]);

    await _mountDashboard(tester, user, repository);

    await tester.tap(find.byKey(const ValueKey('web-notification-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('web-notifications-panel')),
      findsOneWidget,
    );
    expect(find.text('Repair update'), findsOneWidget);
    expect(find.text('A repair booking needs attention.'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('notification-mark-read-7')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Unread'), findsNothing);
  });

  testWidgets('notification panel has an empty state and closes outside',
      (tester) async {
    await _mountDashboard(
      tester,
      user,
      _MemoryNotificationsRepository([]),
    );

    await tester.tap(find.byKey(const ValueKey('web-notification-button')));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);

    await tester.tap(find.text('Dashboard content'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('web-notifications-panel')), findsNothing);
  });

  testWidgets('notification panel stays inside a narrow viewport',
      (tester) async {
    await _mountDashboard(
      tester,
      user,
      _MemoryNotificationsRepository([
        const NotificationEntry(
          AppNotification(
            id: 8,
            title: 'Unread item',
            description: '',
          ),
        ),
      ]),
      width: 320,
    );

    await tester.tap(find.byKey(const ValueKey('web-notification-button')));
    await tester.pumpAndSettle();

    final panelRect =
        tester.getRect(find.byKey(const ValueKey('web-notifications-panel')));
    expect(panelRect.left, greaterThanOrEqualTo(0));
    expect(panelRect.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-profile-button')));
    await tester.pumpAndSettle();

    final profileRect =
        tester.getRect(find.byKey(const ValueKey('web-profile-panel')));
    expect(profileRect.left, greaterThanOrEqualTo(0));
    expect(profileRect.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile panel shows account details and navigates to profile',
      (tester) async {
    await _mountDashboard(
      tester,
      user,
      _MemoryNotificationsRepository([]),
    );

    await tester.tap(find.byKey(const ValueKey('web-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Jordan Green'), findsOneWidget);
    expect(find.text('jordan@example.com'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-profile-view')));
    await tester.pumpAndSettle();

    expect(find.text('Profile destination'), findsOneWidget);
  });

  testWidgets('profile logout invokes the existing logout action',
      (tester) async {
    var logoutCalled = false;
    await _mountDashboard(
      tester,
      user,
      _MemoryNotificationsRepository([]),
      onLogout: () => logoutCalled = true,
    );

    await tester.tap(find.byKey(const ValueKey('web-profile-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-profile-logout')));
    await tester.pumpAndSettle();

    expect(logoutCalled, isTrue);
    expect(find.text('Home destination'), findsOneWidget);
  });
}

Future<void> _mountDashboard(
  WidgetTester tester,
  User user,
  NotificationsRepository notifications, {
  VoidCallback? onLogout,
  double width = 1280,
}) async {
  EnvironmentConfig.initialize(Environment.dev);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: Routes.webDashboard,
    routes: [
      GoRoute(
        path: Routes.webDashboard,
        builder: (_, __) => const Center(child: Text('Dashboard content')),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const Center(child: Text('Profile destination')),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) =>
            const Center(child: Text('Notifications destination')),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const Center(child: Text('Home destination')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final tokenStorage = TokenStorage();
  addTearDown(tokenStorage.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider
            .overrideWithValue(_AuthenticatedRepository(user)),
        pushServiceProvider.overrideWith(
          (ref) => _NoopPushService(
            ref.read(apiClientProvider),
            tokenStorage,
          ),
        ),
        notificationsRepositoryProvider.overrideWithValue(notifications),
        drawerCompaniesCountProvider.overrideWith((ref) => 0),
        drawerUsersCountProvider.overrideWith((ref) async => 0),
        if (onLogout != null)
          authControllerProvider.overrideWith(
            (ref) => _RecordingAuthController(ref, onLogout),
          ),
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
}
