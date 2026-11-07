import 'package:evergreen/core/auth/permissions.dart';
import 'package:evergreen/core/config/environment_config.dart';
import 'package:evergreen/core/errors/failures.dart';
import 'package:evergreen/core/network/api_client.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/announcements/data/announcement_provider.dart';
import 'package:evergreen/features/announcements/domain/announcement.dart';
import 'package:evergreen/features/announcements/presentation/screens/mobile_announcements_screen.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  setUpAll(() => EnvironmentConfig.initialize(Environment.dev));

  const fieldEngineer = AnnouncementRecipient(
    id: '42',
    name: 'Field Engineer',
    role: UserRole.technician,
  );
  const client = AnnouncementRecipient(
    id: '84',
    name: 'Client Contact',
    role: UserRole.client,
  );
  const manager = AnnouncementRecipient(
    id: '7',
    name: 'Another Manager',
    role: UserRole.manager,
  );
  const superAdmin = AnnouncementRecipient(
    id: '1',
    name: 'Super Admin',
    role: UserRole.superAdmin,
  );

  test('only Super Admin and Manager can create announcements', () {
    expect(Permissions.canCreateAnnouncements(UserRole.superAdmin), isTrue);
    expect(Permissions.canCreateAnnouncements(UserRole.manager), isTrue);
    for (final role in [
      UserRole.seniorTechnician,
      UserRole.technician,
      UserRole.clientAdmin,
      UserRole.client,
    ]) {
      expect(
        Permissions.canCreateAnnouncements(role),
        isFalse,
        reason: '$role',
      );
    }
  });

  test('all supported roles can access the announcement inbox', () {
    for (final role in UserRole.values) {
      expect(Permissions.canAccessRoute(role, Routes.announcements), isTrue);
    }
  });

  test('manager recipient role filter excludes managers and super admins', () {
    expect(
      AnnouncementPolicy.canSelectRecipient(
        UserRole.manager,
        UserRole.technician,
      ),
      isTrue,
    );
    expect(
      AnnouncementPolicy.canSelectRecipient(UserRole.manager, UserRole.manager),
      isFalse,
    );
    expect(
      AnnouncementPolicy.canSelectRecipient(
        UserRole.manager,
        UserRole.superAdmin,
      ),
      isFalse,
    );
    expect(
      AnnouncementPolicy.canSelectRecipient(
        UserRole.client,
        UserRole.technician,
      ),
      isFalse,
    );
  });

  test('Super Admin is not offered as a recipient group', () {
    final visibleGroups = AnnouncementRecipientFilter.forUsers([
      const User(
        id: '1',
        email: 'admin@example.com',
        name: 'Super Admin',
        role: UserRole.superAdmin,
      ),
      const User(
        id: '7',
        email: 'manager@example.com',
        name: 'Manager',
        role: UserRole.manager,
      ),
      const User(
        id: '42',
        email: 'engineer@example.com',
        name: 'Cold Room Engineer',
        role: UserRole.technician,
        designation: 'Cold Room Service Engineer',
      ),
    ]);

    expect(
      visibleGroups.map((filter) => filter.label),
      contains('Cold Room Service Engineer'),
    );
    expect(
      visibleGroups.map((filter) => filter.label),
      isNot(contains('Super Admin')),
    );
    expect(
      visibleGroups
          .firstWhere(
            (filter) =>
                filter.key == AnnouncementRecipientFilter.coldRoomFilterKey,
          )
          .matches(
            const User(
              id: '42',
              email: 'engineer@example.com',
              name: 'Cold Room Engineer',
              role: UserRole.technician,
              designation: 'Cold Room Service Engineer',
            ),
          ),
      isTrue,
    );
    expect(
      visibleGroups
          .firstWhere(
            (filter) =>
                filter.key == AnnouncementRecipientFilter.coldRoomFilterKey,
          )
          .matches(
            const User(
              id: '43',
              email: 'engineer@example.com',
              name: 'Other Engineer',
              role: UserRole.technician,
            ),
          ),
      isFalse,
    );
  });

  test('selecting a role or cold room filter matches recipients automatically',
      () {
    const coldRoomEngineer = User(
      id: '42',
      email: 'engineer@example.com',
      name: 'Cold Room Engineer',
      role: UserRole.technician,
      designation: 'Cold Room Service Engineer',
    );
    const otherEngineer = User(
      id: '43',
      email: 'other@example.com',
      name: 'Other Engineer',
      role: UserRole.technician,
    );
    final filters = AnnouncementRecipientFilter.forUsers(
      [coldRoomEngineer, otherEngineer],
    );
    final roleFilter = filters.firstWhere(
      (filter) => filter.key == UserRole.technician.name,
    );
    final coldRoomFilter = filters.firstWhere(
      (filter) => filter.key == AnnouncementRecipientFilter.coldRoomFilterKey,
    );

    expect(
      AnnouncementRecipientFilter.matchesAny([roleFilter], otherEngineer),
      isTrue,
    );
    expect(
      AnnouncementRecipientFilter.matchesAny(
        [coldRoomFilter],
        coldRoomEngineer,
      ),
      isTrue,
    );
    expect(
      AnnouncementRecipientFilter.matchesAny([coldRoomFilter], otherEngineer),
      isFalse,
    );
  });

  test('announcement creates one notification per distinct selected recipient',
      () {
    final state = const AnnouncementState().addAnnouncement(
      id: 'announcement-1',
      title: 'Service update',
      message: 'A scheduled update.',
      senderId: '5',
      senderName: 'Sender',
      createdAt: DateTime.utc(2026, 1, 2),
      recipients: [fieldEngineer, fieldEngineer, client],
    );

    expect(state.announcements.single.recipients, hasLength(2));
    expect(
      state.notifications.map((notification) => notification.recipientId),
      containsAll(['42', '84']),
    );
    expect(state.notifications, hasLength(2));
    expect(state.inboxFor('7'), isEmpty);
    expect(state.inboxFor('42'), hasLength(1));
  });

  test('read status and unread count are scoped to the recipient', () {
    final sent = const AnnouncementState().addAnnouncement(
      id: 'announcement-1',
      title: 'Service update',
      message: 'A scheduled update.',
      senderId: '5',
      senderName: 'Sender',
      createdAt: DateTime.utc(2026, 1, 2),
      recipients: [fieldEngineer, client],
    );
    final read = sent.markRead('announcement-1:42', '42');

    expect(read.unreadCountFor('42'), 0);
    expect(read.unreadCountFor('84'), 1);
    expect(
      read.notifications
          .singleWhere((notification) => notification.recipientId == '42')
          .isRead,
      isTrue,
    );
  });

  test('duplicate announcement identifiers are rejected', () {
    final sent = const AnnouncementState().addAnnouncement(
      id: 'announcement-1',
      title: 'Service update',
      message: 'A scheduled update.',
      senderId: '5',
      senderName: 'Sender',
      createdAt: DateTime.utc(2026, 1, 2),
      recipients: [fieldEngineer],
    );

    expect(
      () => sent.addAnnouncement(
        id: 'announcement-1',
        title: 'Duplicate',
        message: 'Must not be added.',
        senderId: '5',
        senderName: 'Sender',
        createdAt: DateTime.utc(2026, 1, 3),
        recipients: [client],
      ),
      throwsStateError,
    );
  });

  test('a user cannot mark another recipient notification as read', () {
    final sent = const AnnouncementState().addAnnouncement(
      id: 'announcement-1',
      title: 'Service update',
      message: 'A scheduled update.',
      senderId: '5',
      senderName: 'Sender',
      createdAt: DateTime.utc(2026, 1, 2),
      recipients: [fieldEngineer],
    );

    expect(
      () => sent.markRead('announcement-1:42', '84'),
      throwsStateError,
    );
  });

  test('announcement state survives JSON serialization', () {
    final sent = const AnnouncementState().addAnnouncement(
      id: 'announcement-1',
      title: 'Service update',
      message: 'A scheduled update.',
      senderId: '5',
      senderName: 'Sender',
      createdAt: DateTime.utc(2026, 1, 2),
      recipients: [manager, superAdmin],
    );

    final restored = AnnouncementState.fromJson(sent.toJson());
    expect(restored.announcements.single.title, 'Service update');
    expect(restored.notifications, hasLength(2));
    expect(restored.inboxFor('1').single.announcement.senderName, 'Sender');
  });

  test('manager controller records notifications only for selected users',
      () async {
    late _FakeApiClient api;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          const User(
            id: 'manager-1',
            email: 'manager@example.com',
            name: 'Manager',
            role: UserRole.manager,
          ),
        ),
        apiClientProvider.overrideWith((ref) {
          api = _FakeApiClient(ref);
          return api;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(announcementControllerProvider.future);

    await container.read(announcementControllerProvider.notifier).send(
      title: 'Maintenance notice',
      message: 'A scheduled service window.',
      recipients: [fieldEngineer, fieldEngineer],
    );

    final result = container.read(announcementControllerProvider).requireValue;
    expect(result.announcements.single.recipients, hasLength(1));
    expect(api.posts.single.path, 'announcements');
    expect(api.posts.single.body['recipient_ids'], [42]);
    expect(result.notifications, isEmpty);
  });

  test(
    'manager inbox remains available when announcement management is denied',
    () async {
      late _FakeApiClient api;
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(
            const User(
              id: 'manager-1',
              email: 'manager@example.com',
              name: 'Manager',
              role: UserRole.manager,
            ),
          ),
          apiClientProvider.overrideWith((ref) {
            api = _FakeApiClient(
              ref,
              inbox: [
                {
                  'notification': {
                    'id': '99:manager-1',
                    'announcement_id': '99',
                    'recipient_id': 'manager-1',
                    'is_read': false,
                  },
                  'announcement': {
                    'id': '99',
                    'title': 'Service update',
                    'message': 'Please review the new schedule.',
                    'sender_id': '1',
                    'sender_name': 'Super Admin',
                    'created_at': '2026-01-03T00:00:00.000Z',
                    'recipients': [],
                  },
                },
              ],
              managementFailure: const AuthenticationFailure(
                message: 'Access denied',
              ),
            );
            return api;
          }),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(announcementControllerProvider.future);

      expect(result.managementError, 'Access denied');
      expect(result.recipientDirectory, isEmpty);
      expect(result.inboxFor('manager-1'), hasLength(1));
      expect(
        result.inboxFor('manager-1').single.announcement.title,
        'Service update',
      );
    },
    skip: !kIsWeb,
  );

  test('refreshInbox picks up announcements received after the initial load',
      () async {
    late _FakeApiClient api;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          const User(
            id: '42',
            email: 'manager@example.com',
            name: 'Manager',
            role: UserRole.manager,
          ),
        ),
        apiClientProvider.overrideWith((ref) {
          api = _FakeApiClient(ref);
          return api;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(announcementControllerProvider.future);

    api.addInboxRow({
      'notification': {
        'id': '99:42',
        'announcement_id': '99',
        'recipient_id': '42',
        'is_read': false,
      },
      'announcement': {
        'id': '99',
        'title': 'Urgent service update',
        'message': 'Please review the new schedule.',
        'sender_id': '1',
        'sender_name': 'Super Admin',
        'created_at': '2026-01-03T00:00:00.000Z',
        'recipients': [],
      },
    });

    await container
        .read(announcementControllerProvider.notifier)
        .refreshInbox();

    final result = container.read(announcementControllerProvider).requireValue;
    expect(result.unreadCountFor('42'), 1);
    expect(
      result.inboxFor('42').single.announcement.title,
      'Urgent service update',
    );
  });

  test('mark-read calls the backend with the announcement ID', () async {
    late _FakeApiClient api;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          const User(
            id: '42',
            email: 'engineer@example.com',
            name: 'Field Engineer',
            role: UserRole.technician,
          ),
        ),
        apiClientProvider.overrideWith((ref) {
          api = _FakeApiClient(
            ref,
            inbox: [
              {
                'notification': {
                  'id': '99:42',
                  'announcement_id': '99',
                  'recipient_id': '42',
                  'is_read': false,
                },
                'announcement': {
                  'id': '99',
                  'title': 'Service update',
                  'message': 'A scheduled update.',
                  'sender_id': '7',
                  'sender_name': 'Manager',
                  'created_at': '2026-01-02T00:00:00.000Z',
                  'recipients': [],
                },
              },
            ],
          );
          return api;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(announcementControllerProvider.future);

    await container
        .read(announcementControllerProvider.notifier)
        .markRead('99');

    final result = container.read(announcementControllerProvider).requireValue;
    expect(api.posts.single.path, 'announcements/99/read');
    expect(result.inboxFor('42').single.notification.isRead, isTrue);
  });

  testWidgets('mobile inbox marks the current user notification as read',
      (tester) async {
    late _FakeApiClient api;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const User(
              id: '42',
              email: 'engineer@example.com',
              name: 'Field Engineer',
              role: UserRole.technician,
            ),
          ),
          apiClientProvider.overrideWith((ref) {
            api = _FakeApiClient(
              ref,
              inbox: [
                {
                  'notification': {
                    'id': '99:42',
                    'announcement_id': '99',
                    'recipient_id': '42',
                    'is_read': false,
                  },
                  'announcement': {
                    'id': '99',
                    'title': 'Service update',
                    'message': 'A scheduled update.',
                    'sender_id': '7',
                    'sender_name': 'Manager',
                    'created_at': '2026-01-02T00:00:00.000Z',
                    'recipients': [],
                  },
                },
              ],
            );
            return api;
          }),
        ],
        child: const MaterialApp(home: MobileAnnouncementsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 unread'), findsOneWidget);
    await tester.tap(find.text('Service update'));
    await tester.pumpAndSettle();

    expect(api.posts.single.path, 'announcements/99/read');
    expect(find.text('A scheduled update.'), findsOneWidget);
  });

  testWidgets('mobile manager can select recipients and send an announcement',
      (tester) async {
    late _FakeApiClient api;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const User(
              id: '7',
              email: 'manager@example.com',
              name: 'Manager',
              role: UserRole.manager,
            ),
          ),
          apiClientProvider.overrideWith((ref) {
            api = _FakeApiClient(ref);
            return api;
          }),
        ],
        child: const MaterialApp(home: MobileAnnouncementsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create announcement'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Maintenance notice',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'A scheduled service window.',
    );
    await tester.ensureVisible(find.text('Recipients'));
    await tester.tap(find.text('Recipients'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Field Engineer'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send announcement'));
    await tester.tap(find.text('Send announcement'));
    await tester.pumpAndSettle();

    expect(api.posts.single.path, 'announcements');
    expect(api.posts.single.body['recipient_ids'], [42]);
    expect(find.text('Announcement sent successfully.'), findsOneWidget);
  });

  testWidgets('mobile inbox gives useful HTTP error messages', (tester) async {
    final cases = [
      (
        Failure.authentication(message: 'Unauthorized'),
        'Your session is no longer valid. Please sign in again.',
      ),
      (
        Failure.authentication(message: 'Access denied'),
        'You do not have permission to access this announcement.',
      ),
      (
        Failure.server(message: 'Missing', statusCode: 404),
        'The announcement service could not find this resource.',
      ),
      (
        Failure.server(message: 'Server error', statusCode: 500),
        'The announcement service is temporarily unavailable. Try again.',
      ),
    ];

    for (final (failure, message) in cases) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const User(
                id: '42',
                email: 'engineer@example.com',
                name: 'Field Engineer',
                role: UserRole.technician,
              ),
            ),
            apiClientProvider.overrideWith(
              (ref) => _FakeApiClient(ref, getFailure: failure),
            ),
          ],
          child: const MaterialApp(home: MobileAnnouncementsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  test('unauthorized roles cannot send through the controller', () async {
    for (final role in [
      UserRole.seniorTechnician,
      UserRole.technician,
      UserRole.clientAdmin,
      UserRole.client,
    ]) {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(
            User(
              id: 'user-${role.name}',
              email: 'user@example.com',
              name: 'User',
              role: role,
            ),
          ),
          apiClientProvider.overrideWith((ref) => _FakeApiClient(ref)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(announcementControllerProvider.future);

      await expectLater(
        container.read(announcementControllerProvider.notifier).send(
          title: 'Unauthorized',
          message: 'This must not be stored.',
          recipients: [fieldEngineer],
        ),
        throwsStateError,
        reason: '$role',
      );
      expect(
        container
            .read(announcementControllerProvider)
            .requireValue
            .announcements,
        isEmpty,
      );
    }
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(
    super.ref, {
    List<Map<String, dynamic>> inbox = const [],
    Failure? getFailure,
    Failure? managementFailure,
  })  : _inbox = List.of(inbox),
        _getFailure = getFailure,
        _managementFailure = managementFailure;

  final List<Map<String, dynamic>> _inbox;
  final Failure? _getFailure;
  final Failure? _managementFailure;
  final List<({String path, Map<String, dynamic> body})> posts = [];
  final List<Map<String, dynamic>> _history = [];

  void addInboxRow(Map<String, dynamic> row) => _inbox.insert(0, row);

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    final failure = path == 'announcements/inbox'
        ? _getFailure
        : _managementFailure ?? _getFailure;
    if (failure != null) return Left(failure);
    final body = switch (path) {
      'announcements/recipients' => {
          'status': 200,
          'data': [
            {'id': '42', 'name': 'Field Engineer', 'role': 'technician'},
            {'id': '84', 'name': 'Client Contact', 'role': 'client'},
          ],
        },
      'announcements/history' => {'status': 200, 'data': _history},
      'announcements/inbox' => {'status': 200, 'data': _inbox},
      _ => throw StateError('Unexpected GET $path'),
    };
    return Right(body as T);
  }

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    final body = Map<String, dynamic>.from(data as Map? ?? const {});
    posts.add((path: path, body: body));
    if (path == 'announcements') {
      final recipientIds = (body['recipient_ids'] as List).cast<int>();
      _history.insert(0, {
        'id': '99',
        'title': body['title'],
        'message': body['message'],
        'sender_id': '7',
        'sender_name': 'Manager',
        'created_at': '2026-01-02T00:00:00.000Z',
        'recipients': [
          for (final id in recipientIds)
            {
              'id': '$id',
              'name': id == 42 ? 'Field Engineer' : 'Recipient',
              'role': id == 42 ? 'technician' : 'client',
            },
        ],
      });
    } else if (path.endsWith('/read')) {
      for (final row in _inbox) {
        final notification = row['notification'] as Map<String, dynamic>;
        if (notification['announcement_id'] == path.split('/')[1]) {
          notification['is_read'] = true;
        }
      }
    } else {
      throw StateError('Unexpected POST $path');
    }
    final response = path == 'announcements'
        ? {'status': 201, 'data': _history.first}
        : {
            'status': 200,
            'data': {'updated': 1},
          };
    return Right(response as T);
  }
}
