import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/data/evergreen_repository.dart' show unwrap;
import '../../../core/models/backend_models.dart' show dataList;
import '../../../core/network/api_client.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../auth/domain/models/user_model.dart';
import '../domain/announcement.dart';

final announcementControllerProvider =
    AsyncNotifierProvider<AnnouncementController, AnnouncementState>(
  AnnouncementController.new,
);

class AnnouncementController extends AsyncNotifier<AnnouncementState> {
  bool _writing = false;

  @override
  Future<AnnouncementState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const AnnouncementState();
    return _load(user);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return const AnnouncementState();
      return _load(user);
    });
  }

  Future<AnnouncementState> _load(User user) async {
    final api = ref.read(apiClientProvider);
    final inboxBody = unwrap(await api.get<dynamic>('announcements/inbox'));
    final inboxRows = dataList(inboxBody);
    final announcementsById = <String, Announcement>{};
    final notifications = <AnnouncementNotification>[];

    for (final row in inboxRows) {
      final notification =
          Map<String, dynamic>.from(row['notification'] as Map);
      final announcement =
          Map<String, dynamic>.from(row['announcement'] as Map);
      final parsedAnnouncement = Announcement.fromBackend(announcement);
      announcementsById.putIfAbsent(
        parsedAnnouncement.id,
        () => parsedAnnouncement,
      );
      notifications.add(AnnouncementNotification.fromBackend(notification));
    }

    final recipients = <AnnouncementRecipient>[];
    if (Permissions.canCreateAnnouncements(user.role)) {
      final results = await Future.wait([
        api.get<dynamic>('announcements/recipients'),
        api.get<dynamic>('announcements/history'),
      ]);
      final recipientRows = dataList(unwrap(results[0]));
      recipients.addAll(recipientRows.map(AnnouncementRecipient.fromBackend));

      for (final row in dataList(unwrap(results[1]))) {
        final announcement = Announcement.fromBackend(row);
        announcementsById.putIfAbsent(announcement.id, () => announcement);
      }
    }

    return AnnouncementState(
      announcements: announcementsById.values.toList(),
      notifications: notifications,
      recipientDirectory: recipients,
    );
  }

  Future<void> send({
    required String title,
    required String message,
    required List<AnnouncementRecipient> recipients,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !Permissions.canCreateAnnouncements(user.role)) {
      throw StateError('Your role cannot create announcements.');
    }
    final uniqueRecipients = {
      for (final recipient in recipients) recipient.id: recipient,
    }.values.toList();
    if (uniqueRecipients.isEmpty) {
      throw StateError('Select at least one recipient.');
    }
    if (uniqueRecipients.any(
      (recipient) =>
          !AnnouncementPolicy.canSelectRecipient(user.role, recipient.role),
    )) {
      throw StateError('A selected role is not permitted for this sender.');
    }
    final recipientIds = uniqueRecipients.map((recipient) {
      final id = int.tryParse(recipient.id);
      if (id == null || id <= 0) {
        throw StateError('A selected recipient has an invalid ID.');
      }
      return id;
    }).toList();

    await _runMutation(() async {
      final response = unwrap(
        await ref.read(apiClientProvider).post<dynamic>(
          'announcements',
          data: {
            'title': title.trim(),
            'message': message.trim(),
            'recipient_ids': recipientIds,
          },
        ),
      );
      final rawAnnouncement = response is Map ? response['data'] : null;
      if (rawAnnouncement is! Map) {
        throw const FormatException(
          'The server returned an invalid announcement response.',
        );
      }
      final created = Announcement.fromBackend(
        Map<String, dynamic>.from(rawAnnouncement),
      );
      final current = state.valueOrNull;
      if (current == null) {
        throw StateError('Announcements are not ready.');
      }
      state = AsyncData(
        AnnouncementState(
          announcements: [
            created,
            ...current.announcements
                .where((announcement) => announcement.id != created.id),
          ],
          notifications: current.notifications,
          recipientDirectory: current.recipientDirectory,
        ),
      );
    });
  }

  Future<void> markRead(String announcementId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Sign in to read notifications.');

    await _runMutation(() async {
      unwrap(
        await ref.read(apiClientProvider).post<dynamic>(
              'announcements/$announcementId/read',
            ),
      );
      final current = state.valueOrNull;
      if (current == null) {
        throw StateError('Announcements are not ready.');
      }
      final notification = current.notifications.firstWhere(
        (item) =>
            item.announcementId == announcementId &&
            item.recipientId == user.id,
      );
      state = AsyncData(current.markRead(notification.id, user.id));
    });
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    if (_writing) {
      throw StateError('Another announcement update is in progress.');
    }
    _writing = true;
    try {
      await mutation();
    } finally {
      _writing = false;
    }
  }
}
