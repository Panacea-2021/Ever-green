import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';

/// A notification row plus the technician who accepted its task, which the
/// backend attaches as `accepted_by`.
class NotificationEntry {
  final AppNotification notification;
  final String? acceptedBy;

  const NotificationEntry(this.notification, {this.acceptedBy});

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    final accepted = json['accepted_by'];
    final name = accepted is Map ? '${accepted['name'] ?? ''}'.trim() : '';
    return NotificationEntry(
      AppNotification.fromJson(json),
      acceptedBy: name.isEmpty ? null : name,
    );
  }

  NotificationEntry markedRead() {
    final n = notification;
    return NotificationEntry(
      AppNotification(
        id: n.id,
        title: n.title,
        description: n.description,
        imageUrl: n.imageUrl,
        taskId: n.taskId,
        isRead: true,
        createdAt: n.createdAt,
      ),
      acceptedBy: acceptedBy,
    );
  }
}

class NotificationsFeed {
  final List<NotificationEntry> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;

  const NotificationsFeed({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  NotificationsFeed copyWith({
    List<NotificationEntry>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Object? loadMoreError,
  }) {
    return NotificationsFeed(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

class NotificationsRepository {
  final EvergreenRepository _repo;

  NotificationsRepository(this._repo);

  static const pageSize = 20;

  /// The caller's own notifications, newest first.
  Future<(List<NotificationEntry>, bool)> getPage(int page) async {
    final body = unwrap(await _repo.api.post<dynamic>(
      'user/getNotificationsPage',
      data: {'page': page, 'limit': pageSize},
    ),);
    final items = dataList(body).map(NotificationEntry.fromJson).toList();
    final hasMore = body is Map && body['has_more'] is bool
        ? body['has_more'] as bool
        : items.length >= pageSize;
    return (items, hasMore);
  }

  Future<void> markRead({List<int>? ids}) async {
    unwrap(await _repo.api.post<dynamic>(
      'user/markNotificationsRead',
      data: ids == null ? {'all': true} : {'notification_ids': ids},
    ),);
  }

  Future<int> getUnreadCount() async {
    final body = unwrap(await _repo.api.post<dynamic>(
      'user/getUnreadNotificationsCount',
      data: {},
    ),);
    final data = body is Map ? body['data'] : null;
    final count = data is Map ? data['count'] : null;
    return count is num ? count.toInt() : int.tryParse('$count') ?? 0;
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(evergreenRepositoryProvider));
});

/// Unread badge count. Falls back to 0 if the endpoint is unavailable so the
/// badge never blocks the UI.
final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(notificationsRepositoryProvider).getUnreadCount();
  } catch (_) {
    return 0;
  }
});

class NotificationsController extends AutoDisposeAsyncNotifier<NotificationsFeed> {
  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationsFeed> build() async {
    final (items, hasMore) = await ref.watch(notificationsRepositoryProvider).getPage(1);
    return NotificationsFeed(items: items, page: 1, hasMore: hasMore);
  }

  Future<void> loadMore() async {
    final feed = state.valueOrNull;
    if (feed == null || !feed.hasMore || feed.loadingMore) return;
    state = AsyncData(feed.copyWith(loadingMore: true));
    try {
      final (items, hasMore) = await _repo.getPage(feed.page + 1);
      final seen = feed.items.map((e) => e.notification.id).toSet();
      state = AsyncData(feed.copyWith(
        items: [...feed.items, ...items.where((e) => !seen.contains(e.notification.id))],
        page: feed.page + 1,
        hasMore: hasMore,
        loadingMore: false,
      ),);
    } catch (e) {
      state = AsyncData(feed.copyWith(loadingMore: false, loadMoreError: e));
    }
  }

  /// Marks [ids] (or everything when null) read locally, then on the server.
  /// Server failures are ignored: the next refresh shows the true state.
  Future<void> markRead({List<int>? ids}) async {
    final feed = state.valueOrNull;
    if (feed != null) {
      state = AsyncData(feed.copyWith(
        items: [
          for (final e in feed.items)
            if (!e.notification.isRead && (ids == null || ids.contains(e.notification.id)))
              e.markedRead()
            else
              e,
        ],
      ),);
    }
    try {
      await _repo.markRead(ids: ids);
    } catch (_) {
      // Endpoint missing or failed; keep the optimistic state.
    }
    ref.invalidate(unreadNotificationsCountProvider);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider.autoDispose<NotificationsController, NotificationsFeed>(
  NotificationsController.new,
);
