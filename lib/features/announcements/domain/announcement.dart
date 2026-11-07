import '../../auth/domain/models/user_model.dart';

class AnnouncementRecipient {
  const AnnouncementRecipient({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final UserRole role;

  factory AnnouncementRecipient.fromJson(Map<String, dynamic> json) =>
      AnnouncementRecipient(
        id: json['id'] as String,
        name: json['name'] as String,
        role: UserRoleX.fromKey(json['role'] as String?),
      );

  factory AnnouncementRecipient.fromBackend(Map<String, dynamic> json) =>
      AnnouncementRecipient(
        id: '${json['id']}',
        name: json['name']?.toString() ?? '',
        role: UserRoleX.fromKey(json['role']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.key,
      };
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.recipients,
  });

  final String id;
  final String title;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final List<AnnouncementRecipient> recipients;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        recipients: (json['recipients'] as List)
            .map(
              (item) => AnnouncementRecipient.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

  factory Announcement.fromBackend(Map<String, dynamic> json) {
    final rawRecipients = json['recipients'];
    return Announcement(
      id: '${json['id']}',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      senderId: '${json['sender_id']}',
      senderName: json['sender_name']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      recipients: rawRecipients is List
          ? rawRecipients
              .whereType<Map>()
              .map(
                (recipient) => AnnouncementRecipient.fromBackend(
                  Map<String, dynamic>.from(recipient),
                ),
              )
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'sender_id': senderId,
        'sender_name': senderName,
        'created_at': createdAt.toUtc().toIso8601String(),
        'recipients':
            recipients.map((recipient) => recipient.toJson()).toList(),
      };
}

class AnnouncementNotification {
  const AnnouncementNotification({
    required this.id,
    required this.announcementId,
    required this.recipientId,
    this.isRead = false,
  });

  final String id;
  final String announcementId;
  final String recipientId;
  final bool isRead;

  AnnouncementNotification markRead() => AnnouncementNotification(
        id: id,
        announcementId: announcementId,
        recipientId: recipientId,
        isRead: true,
      );

  factory AnnouncementNotification.fromJson(Map<String, dynamic> json) =>
      AnnouncementNotification(
        id: json['id'] as String,
        announcementId: json['announcement_id'] as String,
        recipientId: json['recipient_id'] as String,
        isRead: json['is_read'] as bool,
      );

  factory AnnouncementNotification.fromBackend(Map<String, dynamic> json) =>
      AnnouncementNotification(
        id: json['id']?.toString() ?? '',
        announcementId: '${json['announcement_id']}',
        recipientId: '${json['recipient_id']}',
        isRead: json['is_read'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'announcement_id': announcementId,
        'recipient_id': recipientId,
        'is_read': isRead,
      };
}

class AnnouncementState {
  const AnnouncementState({
    this.announcements = const [],
    this.notifications = const [],
    this.recipientDirectory = const [],
    this.managementError,
  });

  final List<Announcement> announcements;
  final List<AnnouncementNotification> notifications;
  final List<AnnouncementRecipient> recipientDirectory;
  final String? managementError;

  factory AnnouncementState.fromJson(Map<String, dynamic> json) =>
      AnnouncementState(
        announcements: (json['announcements'] as List)
            .map(
              (item) => Announcement.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        notifications: (json['notifications'] as List)
            .map(
              (item) => AnnouncementNotification.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        recipientDirectory: (json['recipientDirectory'] as List? ?? const [])
            .map(
              (item) => AnnouncementRecipient.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'announcements':
            announcements.map((announcement) => announcement.toJson()).toList(),
        'notifications':
            notifications.map((notification) => notification.toJson()).toList(),
        'recipientDirectory':
            recipientDirectory.map((recipient) => recipient.toJson()).toList(),
      };

  AnnouncementState addAnnouncement({
    required String id,
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required DateTime createdAt,
    required List<AnnouncementRecipient> recipients,
  }) {
    if (announcements.any((announcement) => announcement.id == id)) {
      throw StateError('This announcement already exists.');
    }

    final uniqueRecipients = <String, AnnouncementRecipient>{};
    for (final recipient in recipients) {
      uniqueRecipients.putIfAbsent(recipient.id, () => recipient);
    }
    if (uniqueRecipients.isEmpty) {
      throw StateError('Select at least one recipient.');
    }

    final announcement = Announcement(
      id: id,
      title: title,
      message: message,
      senderId: senderId,
      senderName: senderName,
      createdAt: createdAt,
      recipients: uniqueRecipients.values.toList(),
    );
    final notificationIds =
        notifications.map((notification) => notification.id).toSet();
    final newNotifications = [
      for (final recipient in announcement.recipients)
        if (!notificationIds.contains('$id:${recipient.id}'))
          AnnouncementNotification(
            id: '$id:${recipient.id}',
            announcementId: id,
            recipientId: recipient.id,
          ),
    ];

    return AnnouncementState(
      announcements: [announcement, ...announcements],
      notifications: [...newNotifications, ...notifications],
      recipientDirectory: recipientDirectory,
      managementError: managementError,
    );
  }

  AnnouncementState markRead(String notificationId, String recipientId) {
    var found = false;
    final updated = notifications.map((notification) {
      if (notification.id != notificationId ||
          notification.recipientId != recipientId) {
        return notification;
      }
      found = true;
      return notification.markRead();
    }).toList();
    if (!found) throw StateError('Notification not found for this user.');
    return AnnouncementState(
      announcements: announcements,
      notifications: updated,
      recipientDirectory: recipientDirectory,
      managementError: managementError,
    );
  }

  int unreadCountFor(String recipientId) => notifications
      .where(
        (notification) =>
            notification.recipientId == recipientId && !notification.isRead,
      )
      .length;

  List<({AnnouncementNotification notification, Announcement announcement})>
      inboxFor(String recipientId) {
    final byId = {
      for (final announcement in announcements) announcement.id: announcement,
    };
    return [
      for (final notification in notifications)
        if (notification.recipientId == recipientId &&
            byId.containsKey(notification.announcementId))
          (
            notification: notification,
            announcement: byId[notification.announcementId]!,
          ),
    ];
  }
}

class AnnouncementPolicy {
  const AnnouncementPolicy._();

  static List<UserRole> visibleRecipientGroups(Iterable<UserRole> roles) =>
      roles.toSet().where((role) => role != UserRole.superAdmin).toList();

  /// Role exclusions are illustrative only; manager hierarchy membership
  /// cannot be determined from the client-side user model.
  static bool canSelectRecipient(UserRole sender, UserRole recipient) {
    if (sender == UserRole.superAdmin) return true;
    if (sender != UserRole.manager) return false;
    return recipient != UserRole.superAdmin && recipient != UserRole.manager;
  }
}

class AnnouncementRecipientFilter {
  const AnnouncementRecipientFilter._({
    required this.key,
    required this.label,
    required this.matchesRole,
    this.coldRoomServiceEngineer = false,
  });

  static const coldRoomFilterKey = 'cold_room_service_engineer';

  final String key;
  final String label;
  final UserRole? matchesRole;
  final bool coldRoomServiceEngineer;

  bool matches(User user) {
    if (coldRoomServiceEngineer) {
      return user.designation?.toLowerCase().contains('cold room') ?? false;
    }
    return matchesRole == user.role;
  }

  static bool matchesAny(
    Iterable<AnnouncementRecipientFilter> filters,
    User user,
  ) =>
      filters.any((filter) => filter.matches(user));

  static List<AnnouncementRecipientFilter> forUsers(Iterable<User> users) {
    final userList = users.toList();
    return [
      const AnnouncementRecipientFilter._(
        key: coldRoomFilterKey,
        label: 'Cold Room Service Engineer',
        matchesRole: null,
        coldRoomServiceEngineer: true,
      ),
      for (final role in AnnouncementPolicy.visibleRecipientGroups(
        userList.map((user) => user.role),
      ))
        AnnouncementRecipientFilter._(
          key: role.name,
          label: role.label,
          matchesRole: role,
        ),
    ];
  }
}
