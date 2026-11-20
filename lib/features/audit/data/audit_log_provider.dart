import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/models/backend_models.dart';
import '../domain/models/audit_log_entry.dart';

/// One loaded window of the server-side audit trail (`getAuditLogs`).
class AuditLogFeed {
  final List<AuditLogEntry> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;

  const AuditLogFeed({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  AuditLogFeed copyWith({
    List<AuditLogEntry>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Object? loadMoreError,
  }) {
    return AuditLogFeed(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

/// A 403 either in the response body (`{status: 403}`) or as the HTTP status
/// (mapped to "Access denied" by the error handler).
bool isAccessDenied(Failure? failure) => switch (failure) {
      ServerFailure(statusCode: 403) => true,
      AuthenticationFailure(message: 'Access denied') => true,
      _ => false,
    };

class AuditLogRepository {
  final EvergreenRepository _repo;

  AuditLogRepository(this._repo);

  static const pageSize = 30;

  /// Admins see every row; a Client Admin sees rows by their companies'
  /// users; POCs and service engineers see only their own actions. Newest
  /// first. A backend that still refuses the role (403) yields an empty page.
  Future<(List<AuditLogEntry>, int)> getPage(int page, {AuditEntity? entity}) async {
    final result = await _repo.api.post<dynamic>(
      'user/getAuditLogs',
      data: {
        'page': page,
        'limit': pageSize,
        if (entity != null) 'entity': entity.key,
      },
    );
    if (isAccessDenied(result.getLeft().toNullable())) {
      return (const <AuditLogEntry>[], 0);
    }
    final body = unwrap(result);
    // `{data: [...], total}` either at the top level or inside `data`.
    final inner = body is Map && body['data'] is Map ? body['data'] : body;
    final rows = dataList(inner).map(AuditLogEntry.fromBackend).toList();
    final rawTotal = inner is Map ? inner['total'] : null;
    final total = rawTotal is num ? rawTotal.toInt() : int.tryParse('$rawTotal');
    return (rows, total ?? rows.length);
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(evergreenRepositoryProvider));
});

/// The audit trail for one entity filter (null = all), paged from the server.
class AuditLogController
    extends AutoDisposeFamilyAsyncNotifier<AuditLogFeed, AuditEntity?> {
  @override
  Future<AuditLogFeed> build(AuditEntity? entity) async {
    final (items, total) =
        await ref.watch(auditLogRepositoryProvider).getPage(1, entity: entity);
    return AuditLogFeed(
      items: items,
      total: total,
      page: 1,
      hasMore: items.length < total && items.length >= AuditLogRepository.pageSize,
    );
  }

  Future<void> loadMore() async {
    final feed = state.valueOrNull;
    if (feed == null || !feed.hasMore || feed.loadingMore) return;
    state = AsyncData(feed.copyWith(loadingMore: true));
    try {
      final (items, total) = await ref
          .read(auditLogRepositoryProvider)
          .getPage(feed.page + 1, entity: arg);
      final seen = feed.items.map((e) => e.id).toSet();
      final merged = [...feed.items, ...items.where((e) => !seen.contains(e.id))];
      state = AsyncData(feed.copyWith(
        items: merged,
        total: total,
        page: feed.page + 1,
        hasMore: items.length >= AuditLogRepository.pageSize && merged.length < total,
        loadingMore: false,
      ),);
    } catch (e) {
      state = AsyncData(feed.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}

final auditLogProvider = AsyncNotifierProvider.autoDispose
    .family<AuditLogController, AuditLogFeed, AuditEntity?>(AuditLogController.new);
