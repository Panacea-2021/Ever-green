import 'package:evergreen/core/auth/permissions.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/announcements/data/announcement_provider.dart';
import 'package:evergreen/features/announcements/domain/announcement.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  test('announcement route is unavailable outside the web app', () {
    for (final role in UserRole.values) {
      expect(Permissions.canAccessRoute(role, Routes.announcements), isFalse);
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
    SharedPreferences.setMockInitialValues({});
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
    expect(result.notifications, hasLength(1));
    expect(result.inboxFor('42'), hasLength(1));
    expect(result.inboxFor('84'), isEmpty);
  });

  test('Super Admin controller can target multiple permitted groups', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          const User(
            id: 'admin-1',
            email: 'admin@example.com',
            name: 'Super Admin',
            role: UserRole.superAdmin,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(announcementControllerProvider.future);

    await container.read(announcementControllerProvider.notifier).send(
      title: 'Workspace update',
      message: 'Please review this update.',
      recipients: [manager, fieldEngineer],
    );

    final result = container.read(announcementControllerProvider).requireValue;
    expect(result.announcements.single.recipients, hasLength(2));
    expect(result.notifications, hasLength(2));
    expect(result.inboxFor('7'), hasLength(1));
    expect(result.inboxFor('42'), hasLength(1));
  });

  test('unauthorized roles cannot send through the controller', () async {
    for (final role in [
      UserRole.seniorTechnician,
      UserRole.technician,
      UserRole.clientAdmin,
      UserRole.client,
    ]) {
      SharedPreferences.setMockInitialValues({});
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
