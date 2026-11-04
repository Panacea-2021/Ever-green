import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/permissions.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../domain/announcement.dart';

const _storageKey = 'evergreen_announcement_preview_v1';

final announcementControllerProvider =
    AsyncNotifierProvider<AnnouncementController, AnnouncementState>(
  AnnouncementController.new,
);

class AnnouncementController extends AsyncNotifier<AnnouncementState> {
  bool _writing = false;

  @override
  Future<AnnouncementState> build() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return const AnnouncementState();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Stored announcement preview is invalid.');
    }
    return AnnouncementState.fromJson(Map<String, dynamic>.from(decoded));
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
    if (uniqueRecipients.any(
      (recipient) =>
          !AnnouncementPolicy.canSelectRecipient(user.role, recipient.role),
    )) {
      throw StateError('A selected role is not permitted for this sender.');
    }

    await _update(
      (current) => current.addAnnouncement(
        id: 'preview-${DateTime.now().microsecondsSinceEpoch}-${user.id}',
        title: title.trim(),
        message: message.trim(),
        senderId: user.id,
        senderName: user.name,
        createdAt: DateTime.now(),
        recipients: uniqueRecipients,
      ),
    );
  }

  Future<void> markRead(String notificationId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Sign in to read notifications.');
    await _update((current) => current.markRead(notificationId, user.id));
  }

  Future<void> _update(
    AnnouncementState Function(AnnouncementState current) transform,
  ) async {
    if (_writing) {
      throw StateError('Another announcement update is in progress.');
    }
    final current = state.valueOrNull;
    if (current == null) throw StateError('Announcement preview is not ready.');

    _writing = true;
    try {
      final next = transform(current);
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode(next.toJson()),
      );
      if (!saved) {
        throw StateError('Could not save the local announcement preview.');
      }
      state = AsyncData(next);
    } finally {
      _writing = false;
    }
  }
}
