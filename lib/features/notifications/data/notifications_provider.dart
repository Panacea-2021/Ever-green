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
    final accepted = json['accepted_by'] ??
        json['acceptedBy'] ??
        json['service_engineer'] ??
        json['engineer'] ??
        json['technician'];
    String name = '';
    if (accepted is Map) {
      name = '${accepted['name'] ?? accepted['full_name'] ?? accepted['username'] ?? ''}'
          .trim();
    } else if (accepted is String) {
      name = accepted.trim();
    } else if (accepted != null) {
      name = '$accepted'.trim();
    }
    // Also check top-level name fields.
    if (name.isEmpty) {
      final v = json['accepted_by_name'] ?? json['engineer_name'] ?? json['technician_name'];
      name = v == null ? '' : '$v'.trim();
    }
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
  /// Backend-reported total count, when available. Falls back to [items.length].
  final int? totalCount;

  const NotificationsFeed({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
    this.totalCount,
  });

  NotificationsFeed copyWith({
    List<NotificationEntry>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Object? loadMoreError,
    int? totalCount,
  }) {
    return NotificationsFeed(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class NotificationsRepository {
  final EvergreenRepository _repo;

  NotificationsRepository(this._repo);

  static const pageSize = 20;

  /// The caller's own notifications, newest first. Returns items, hasMore and
  /// an optional backend-reported total count.
  Future<(List<NotificationEntry>, bool, int?)> getPage(int page) async {
    final body = unwrap(await _repo.api.post<dynamic>(
      'user/getNotificationsPage',
      data: {'page': page, 'limit': pageSize},
    ),);
    // Accept several possible response shapes so records are not silently
    // dropped when the backend uses a different envelope key. Also unwrap a
    // nested `data` object (e.g. { data: { notifications: [...] } }).
    List<Map<String, dynamic>> rows = const [];
    dynamic container = body;
    if (container is Map) {
      for (final key in const [
        'data',
        'notifications',
        'items',
        'results',
        'rows',
        'records',
        'list',
        'notification_list',
      ]) {
        final v = container[key];
        if (v is List) {
          rows = v.whereType<Map<String, dynamic>>().toList();
          container = null;
          break;
        }
        if (v is Map) {
          // Nested envelope: keep searching inside.
          container = v;
        }
      }
    }
    if (rows.isEmpty && container is Map) {
      for (final v in container.values) {
        if (v is List) {
          rows = v.whereType<Map<String, dynamic>>().toList();
          break;
        }
      }
    }
    if (rows.isEmpty && body is List) {
      rows = body.whereType<Map<String, dynamic>>().toList();
    }
    final items = rows.map(NotificationEntry.fromJson).toList();
    // Determine hasMore from any common pagination flag, falling back to a
    // page-full heuristic.
    bool hasMore = items.length >= pageSize;
    // Check both the top-level body and the common nested `data` object.
    final nestedData = body is Map ? body['data'] : null;
    for (final src in <dynamic>[body, nestedData]) {
      if (src is! Map) continue;
      for (final key in const [
        'has_more',
        'hasMore',
        'has_next',
        'hasNext',
        'more',
      ]) {
        final v = src[key];
        if (v is bool) {
          hasMore = v;
          break;
        }
        if (v is num) {
          hasMore = v != 0;
          break;
        }
      }
      for (final key in const ['pagination', 'meta', 'page_info']) {
        final v = src[key];
        if (v is Map) {
          for (final k in const [
            'has_more',
            'hasMore',
            'has_next',
            'hasNext',
            'more',
          ]) {
            final vv = v[k];
            if (vv is bool) {
              hasMore = vv;
              break;
            }
            if (vv is num) {
              hasMore = vv != 0;
              break;
            }
          }
        }
      }
    }
    // Optional backend-reported total count.
    int? total;
    for (final src in <dynamic>[body, nestedData]) {
      if (src is! Map) continue;
      for (final key in const [
        'total',
        'total_count',
        'totalCount',
        'totalRecords',
        'total_items',
        'totalItems',
      ]) {
        final v = src[key];
        if (v is num) {
          total = v.toInt();
          break;
        }
        if (v is String) {
          final p = int.tryParse(v);
          if (p != null) {
            total = p;
            break;
          }
        }
      }
      if (total != null) break;
    }
    return (items, hasMore, total);
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
    // Be tolerant of several envelope shapes.
    dynamic count;
    if (body is num) {
      count = body;
    } else if (body is Map) {
      for (final key in const [
        'count',
        'unread_count',
        'unreadCount',
        'total',
        'value',
      ]) {
        if (body[key] != null) {
          count = body[key];
          break;
        }
      }
      if (count == null) {
        for (final nestedKey in const ['data', 'result', 'payload', 'meta']) {
          final v = body[nestedKey];
          if (v is Map) {
            for (final key in const [
              'count',
              'unread_count',
              'unreadCount',
              'total',
              'value',
            ]) {
              if (v[key] != null) {
                count = v[key];
                break;
              }
            }
            if (count != null) break;
          } else if (v is num) {
            count = v;
            break;
          }
        }
      }
    }
    if (count is num) return count.toInt();
    return int.tryParse('$count') ?? 0;
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(evergreenRepositoryProvider));
});

/// Unread badge count. Falls back to 0 if the endpoint is unavailable so the
/// badge never blocks the UI.
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  cacheFor(ref, listCacheDuration);
  try {
    return await ref.watch(notificationsRepositoryProvider).getUnreadCount();
  } catch (_) {
    return 0;
  }
});

class NotificationsController extends AsyncNotifier<NotificationsFeed> {
  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationsFeed> build() async {
    final (items, hasMore, total) =
        await ref.watch(notificationsRepositoryProvider).getPage(1);
    return NotificationsFeed(items: items, page: 1, hasMore: hasMore, totalCount: total);
  }

  Future<void> loadMore() async {
    final feed = state.valueOrNull;
    if (feed == null || !feed.hasMore || feed.loadingMore) return;
    state = AsyncData(feed.copyWith(loadingMore: true));
    try {
      final (items, hasMore, total) = await _repo.getPage(feed.page + 1);
      final seen = feed.items.map((e) => e.notification.id).toSet();
      state = AsyncData(feed.copyWith(
        items: [...feed.items, ...items.where((e) => !seen.contains(e.notification.id))],
        page: feed.page + 1,
        hasMore: hasMore,
        loadingMore: false,
        totalCount: total ?? feed.totalCount,
      ),);
    } catch (e) {
      state = AsyncData(feed.copyWith(loadingMore: false, loadMoreError: e));
    }
  }

  /// Marks [ids] (or everything when null) read on the server first, then
  /// updates local state only after confirmation. Failures propagate so the
  /// caller can show an error and the unread state is preserved.
  Future<void> markRead({List<int>? ids}) async {
    await _repo.markRead(ids: ids);
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
    ref.invalidate(unreadNotificationsCountProvider);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsFeed>(
  NotificationsController.new,
);
