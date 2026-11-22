import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../data/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _webBackground = Color(0xFFF6F9F6);

  String _webFilter = 'all';
  String _webSearch = '';
  bool _loadingAllPages = false;
  bool _markingAllRead = false;

  @override
  void initState() {
    super.initState();
  }

  void _onNotificationTap(NotificationEntry entry) {
    final n = entry.notification;
    if (kIsWeb) {
      unawaited(_openWebNotification(entry));
      return;
    }
    if (!n.isRead) {
      ref.read(notificationsControllerProvider.notifier).markRead(ids: [n.id]);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _loadAllNotifications() async {
    if (!mounted || _loadingAllPages) return;
    var feed = ref.read(notificationsControllerProvider).valueOrNull;
    if (feed == null ||
        !feed.hasMore ||
        feed.loadingMore ||
        feed.loadMoreError != null) {
      return;
    }

    _loadingAllPages = true;
    var pages = 0;
    try {
      while (mounted && pages < 100) {
        feed = ref.read(notificationsControllerProvider).valueOrNull;
        if (feed == null ||
            !feed.hasMore ||
            feed.loadingMore ||
            feed.loadMoreError != null) {
          break;
        }
        await ref.read(notificationsControllerProvider.notifier).loadMore();
        pages++;
      }
    } finally {
      if (mounted) _loadingAllPages = false;
    }
  }

  Future<void> _openWebNotification(NotificationEntry entry) async {
    final notification = entry.notification;
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationsControllerProvider.notifier)
            .markRead(ids: [notification.id]);
      } catch (error) {
        _showWebError("Couldn't mark this notification as read: $error");
      }
    }

    if (!mounted) return;
    if (notification.taskId != null) {
      context.push('${Routes.taskDetails}/${notification.taskId}');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailScreen(entry: entry),
        ),
      );
    }
  }

  Future<void> _markAllWebNotificationsRead() async {
    if (_markingAllRead) return;
    setState(() => _markingAllRead = true);
    try {
      await ref.read(notificationsControllerProvider.notifier).markRead();
      if (!mounted) return;
    } catch (error) {
      _showWebError("Couldn't mark all notifications as read: $error");
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  void _showWebError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(notificationsControllerProvider);
    try {
      await ref.read(notificationsControllerProvider.future);
    } catch (_) {
      // The error state is rendered by the list.
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(notificationsControllerProvider);
    if (kIsWeb) return _buildWebNotifications(feed);

    final hasUnread =
        feed.valueOrNull?.items.any((e) => !e.notification.isRead) ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with 30% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.white);
                },
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, hasUnread),
                // Notifications List
                Expanded(
                  child: RefreshIndicator(
                    color: _green,
                    onRefresh: _refresh,
                    child: feed.when(
                      loading: () {
                        final cached = feed.valueOrNull;
                        if (cached != null) {
                          return cached.items.isEmpty
                              ? _message(
                                  icon: Icons.notifications_none,
                                  title: 'No notifications yet',
                                  subtitle: 'Task updates will show up here.',
                                )
                              : _buildNotificationsList(cached);
                        }
                        return const Center(
                          child: CircularProgressIndicator(color: _green),
                        );
                      },
                      error: (e, _) {
                        final cached = feed.valueOrNull;
                        if (cached != null) {
                          return cached.items.isEmpty
                              ? _message(
                                  icon: Icons.notifications_none,
                                  title: 'No notifications yet',
                                  subtitle: 'Task updates will show up here.',
                                )
                              : _buildNotificationsList(cached);
                        }
                        return _message(
                          icon: Icons.cloud_off_outlined,
                          title: "Couldn't load notifications",
                          subtitle: '$e',
                          onRetry: _refresh,
                        );
                      },
                      data: (data) => data.items.isEmpty
                          ? _message(
                              icon: Icons.notifications_none,
                              title: 'No notifications yet',
                              subtitle: 'Task updates will show up here.',
                            )
                          : _buildNotificationsList(data),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNotifications(AsyncValue<NotificationsFeed> state) {
    final feed = state.valueOrNull;
    final items = feed?.items ?? const <NotificationEntry>[];
    final loadedUnread =
        items.where((entry) => !entry.notification.isRead).length;
    final apiUnread = ref.watch(unreadNotificationsCountProvider).valueOrNull;
    final unreadCount = apiUnread ?? loadedUnread;
    final total = feed?.totalCount ?? items.length;
    final totalLabel = '$total';
    final unreadLabel = '$unreadCount';
    final readLabel = '${(total - unreadCount).clamp(0, total)}';
    final query = _webSearch.trim().toLowerCase();
    final filteredItems = items.where((entry) {
      final notification = entry.notification;
      final matchesFilter = switch (_webFilter) {
        'unread' => !notification.isRead,
        'read' => notification.isRead,
        _ => true,
      };
      final matchesSearch = query.isEmpty ||
          notification.title.toLowerCase().contains(query) ||
          notification.description.toLowerCase().contains(query) ||
          (notification.taskId?.toString().contains(query) ?? false) ||
          (notification.taskId != null &&
              '#${notification.taskId}'.contains(query));
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: _webBackground,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _green,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildWebSummary(
                  totalLabel: totalLabel,
                  unreadLabel: unreadLabel,
                  readLabel: readLabel,
                  unreadCount: unreadCount,
                  loadingAll: false,
                ),
              ),
              if (feed != null)
                SliverToBoxAdapter(
                  child: _buildWebFilters(
                    totalLabel: totalLabel,
                    unreadLabel: unreadLabel,
                    readLabel: readLabel,
                    enabled: true,
                  ),
                ),
              if (feed?.loadMoreError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Some notifications could not be loaded. Counts and results may be incomplete.',
                            style: TextStyle(color: Color(0xFF8A5A00)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => unawaited(
                            ref
                                .read(notificationsControllerProvider.notifier)
                                .loadMore(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (feed == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: state.hasError
                      ? _message(
                          icon: Icons.cloud_off_outlined,
                          title: "Couldn't load notifications",
                          subtitle: '${state.error}',
                          onRetry: _refresh,
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: _green),
                        ),
                )
              else if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _message(
                    icon: Icons.notifications_none,
                    title: query.isNotEmpty
                        ? 'No matching notifications'
                        : _webFilter == 'all'
                            ? 'No notifications yet'
                            : 'No $_webFilter notifications',
                    subtitle: query.isNotEmpty
                        ? 'Try another search.'
                        : 'Task updates will show up here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildWebNotificationCard(
                        filteredItems[index],
                      ),
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
              if (feed != null &&
                  feed.hasMore &&
                  feed.loadMoreError == null &&
                  !_loadingAllPages)
                SliverToBoxAdapter(
                  child: _buildFooter(feed),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSummary({
    required String totalLabel,
    required String unreadLabel,
    required String readLabel,
    required int unreadCount,
    required bool loadingAll,
  }) {
    final titleBlock = Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F2E7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.notifications,
            color: _green,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17201A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Stay updated with your tasks and activities',
                style: TextStyle(fontSize: 14, color: Color(0xFF68716B)),
              ),
            ],
          ),
        ),
      ],
    );

    final markAllButton = SizedBox(
      height: 46,
      child: FilledButton.icon(
        key: const ValueKey('notifications-mark-all-read'),
        onPressed: loadingAll || unreadCount == 0 || _markingAllRead
            ? null
            : _markAllWebNotificationsRead,
        icon: _markingAllRead
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, size: 20),
        label: const Text('Mark All as Read'),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFA8B9AA),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1000;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EEE9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120E3E1B),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: horizontal
                ? Row(
                    children: [
                      Expanded(flex: 3, child: titleBlock),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: _webMetricCard(
                                icon: Icons.layers_rounded,
                                value: totalLabel,
                                label: 'Total',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _webMetricCard(
                                icon: Icons.circle,
                                value: unreadLabel,
                                label: 'Unread',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _webMetricCard(
                                icon: Icons.check,
                                value: readLabel,
                                label: 'Read',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      markAllButton,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _webMetricCard(
                            icon: Icons.layers_rounded,
                            value: totalLabel,
                            label: 'Total',
                            width: 145,
                          ),
                          _webMetricCard(
                            icon: Icons.circle,
                            value: unreadLabel,
                            label: 'Unread',
                            width: 145,
                          ),
                          _webMetricCard(
                            icon: Icons.check,
                            value: readLabel,
                            label: 'Read',
                            width: 145,
                          ),
                          markAllButton,
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _webMetricCard({
    required IconData icon,
    required String value,
    required String label,
    double? width,
  }) {
    return Container(
      width: width,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEEF1EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE9F4EB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: _green),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17201A),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68716B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFilters({
    required String totalLabel,
    required String unreadLabel,
    required String readLabel,
    required bool enabled,
  }) {
    final filters = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _webFilterButton('all', 'All', totalLabel, enabled),
        _webFilterButton('unread', 'Unread', unreadLabel, enabled),
        _webFilterButton('read', 'Read', readLabel, enabled),
      ],
    );
    final search = SizedBox(
      height: 46,
      child: TextField(
        key: const ValueKey('notifications-search'),
        onChanged: (value) => setState(() => _webSearch = value),
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          hintStyle: const TextStyle(color: Color(0xFF89918B)),
          prefixIcon: const Icon(Icons.search, color: _green),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE8DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.4),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: constraints.maxWidth >= 760
            ? Row(
                children: [
                  filters,
                  const SizedBox(width: 16),
                  Expanded(child: search),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filters,
                  const SizedBox(height: 12),
                  search,
                ],
              ),
      ),
    );
  }

  Widget _webFilterButton(
    String filter,
    String label,
    String count,
    bool enabled,
  ) {
    final selected = _webFilter == filter;
    return OutlinedButton(
      key: ValueKey('notifications-filter-$filter'),
      onPressed: enabled ? () => setState(() => _webFilter = filter) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF29332B),
        backgroundColor: selected ? _green : Colors.white,
        side: BorderSide(
          color: selected ? _green : const Color(0xFFDCE5DE),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text('$label ($count)'),
    );
  }

  Widget _buildWebNotificationCard(NotificationEntry entry) {
    final notification = entry.notification;
    final style = _notificationStyle(notification.title);
    final leading = SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(style.icon, size: 29, color: style.accent),
          ),
          if (!notification.isRead)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17201A),
              ),
            ),
            if (notification.taskId != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${notification.taskId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17632B),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          notification.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF68716B),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF5EE),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 18, color: _green),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Service Engineer : ${entry.acceptedBy ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17632B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final timestamp = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF818982)),
            const SizedBox(width: 7),
            Text(
              _relativeTime(notification.createdAt),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF59615B),
              ),
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: style.accent, width: 3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100E3E1B),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('notification-card-${notification.id}'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onNotificationTap(entry),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              leading,
                              const SizedBox(width: 14),
                              Container(
                                width: 1,
                                height: 76,
                                color: const Color(0xFFE8EEE9),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: content),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: timestamp,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 76,
                            color: const Color(0xFFE8EEE9),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: content),
                          const SizedBox(width: 20),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: timestamp,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  ({Color background, Color accent, IconData icon}) _notificationStyle(
    String title,
  ) {
    final normalized = title.toLowerCase();
    if (normalized.contains('on hold')) {
      return (
        background: const Color(0xFFFFF3D9),
        accent: const Color(0xFFE59713),
        icon: Icons.notifications_none,
      );
    }
    if (normalized.contains('engineer assigned') ||
        normalized.contains('service engineer assigned')) {
      return (
        background: const Color(0xFFE4F1FF),
        accent: const Color(0xFF1683E8),
        icon: Icons.people_outline,
      );
    }
    if (normalized.contains('closed')) {
      return (
        background: const Color(0xFFE6F4EA),
        accent: _green,
        icon: Icons.check_circle_outline,
      );
    }
    if (normalized.contains('overdue')) {
      return (
        background: const Color(0xFFFFEFE0),
        accent: const Color(0xFFEF8A16),
        icon: Icons.warning_amber_outlined,
      );
    }
    return (
      background: const Color(0xFFF0F2F1),
      accent: const Color(0xFF89918B),
      icon: Icons.notifications_none,
    );
  }

  Widget _buildHeader(BuildContext context, bool hasUnread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 39, 16, 24),
      child: Row(
        children: [
          // Back button (mobile only; web uses the top bar's back arrow)
          if (!kIsWeb) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 17),
          ],
          // Title (mobile only; web shows it in the top bar)
          if (!kIsWeb)
            const Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.6,
                ),
              ),
            )
          else
            const Spacer(),
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsControllerProvider.notifier).markRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF125420),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Centered message inside a scrollable so pull-to-refresh still works.
  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Color(0xFF9B9B9B),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationsFeed feed) {
    final items = feed.items;
    final showFooter = feed.hasMore || feed.loadMoreError != null;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) return _buildFooter(feed);
        if (index >= items.length - 3 &&
            feed.hasMore &&
            feed.loadMoreError == null &&
            !feed.loadingMore) {
          // Prefetch the next page as the end comes into view (guarded to avoid
          // spawning duplicate microtasks on every rebuild).
          Future.microtask(
            () => ref.read(notificationsControllerProvider.notifier).loadMore(),
          );
        }
        final isLast = index == items.length - 1;
        return _buildNotificationCard(items[index], isLast, index);
      },
    );
  }

  Widget _buildFooter(NotificationsFeed feed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: feed.loadMoreError != null
            ? TextButton(
                onPressed: () => ref
                    .read(notificationsControllerProvider.notifier)
                    .loadMore(),
                child: const Text('Couldn\'t load more. Retry'),
              )
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _green),
              ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationEntry entry,
    bool isLast,
    int index,
  ) {
    final notification = entry.notification;
    return GestureDetector(
      onTap: () => _onNotificationTap(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Timeline line (vertical line connecting to next card)
            if (!isLast)
              Positioned(
                left:
                    63.5, // Center of the timeline dot area (70 + 18/2 - 16 padding offset)
                top: 122, // Start from bottom of card content area
                child: Container(
                  width: 1,
                  height: 24, // Height to connect to next card
                  color: const Color(0xFFE8E8E8),
                ),
              ),
            // Card content
            Container(
              height: 137,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xBFE0D9EE), // rgba(224,217,238,0.75)
                    blurRadius: 32,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Bell icon with green circle background
                  Positioned(
                    left: 16.6,
                    top: 14.6,
                    child: Container(
                      width: 44.8,
                      height: 44.8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9), // Light green background
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications,
                          color: Color(0xFF2E7D32), // Dark green bell
                          size: 25.6,
                        ),
                      ),
                    ),
                  ),

                  // Green dot indicator (outer light green circle)
                  Positioned(
                    left: 70,
                    top: 15,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Light green
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            // Dark green while unread, grey once read.
                            color: notification.isRead
                                ? const Color(0xFFBDBDBD)
                                : const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Timeline vertical line inside card
                  Positioned(
                    left: 79.56,
                    top: 27,
                    child: Container(
                      width: 1,
                      height: 95,
                      color: const Color(0xFFE8E8E8),
                    ),
                  ),

                  // Title: "Unaccepted Task  #445255"
                  Positioned(
                    left: 103,
                    top: 16,
                    right: 16,
                    child: Text(
                      _titleWithTask(notification.title, notification.taskId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.42,
                      ),
                    ),
                  ),

                  // Message: two lines
                  Positioned(
                    left: 103,
                    top: 43,
                    right: 16,
                    child: Text(
                      notification.description,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.5),
                        letterSpacing: -0.39,
                        height: 1.7,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Technician badge
                  Positioned(
                    left: 103,
                    top: 97,
                    right: 90,
                    child: Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF0EA),
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Center(
                        child: Text(
                          'Service Engineer : ${entry.acceptedBy ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF125420),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Time: "1 Day ago"
                  Positioned(
                    right: 16,
                    top: 99,
                    child: Text(
                      _relativeTime(notification.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.36,
                        height: 1.83,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Detail Screen
class NotificationDetailScreen extends StatelessWidget {
  final NotificationEntry entry;

  const NotificationDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final notification = entry.notification;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with 30% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.white);
                },
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 39, 16, 24),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                      // Title
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Notification detail card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xBFE0D9EE),
                                blurRadius: 32,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Purple gradient header with illustration
                              Container(
                                height: 173,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFFE8D5F0)
                                          .withValues(alpha: 0.6),
                                      const Color(0xFFF5EDF8)
                                          .withValues(alpha: 0.3),
                                      Colors.white,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // White card in background
                                    Positioned(
                                      top: 60,
                                      child: Container(
                                        width: 140,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bell icon
                                    Positioned(
                                      top: 25,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD54F),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFFD54F)
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.notifications,
                                              color: Color(0xFFFF8F00),
                                              size: 34,
                                            ),
                                          ),
                                          // Red badge
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  '1',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title row with badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _titleWithTask(
                                              notification.title,
                                              notification.taskId,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        // Technician badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF125420),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                entry.acceptedBy ?? '—',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF125420),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Full message
                                    Text(
                                      notification.description,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            Colors.black.withValues(alpha: 0.6),
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Time (aligned right)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _relativeTime(notification.createdAt),
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    if (notification.taskId != null) ...[
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        onTap: () => context.push(
                                          '${Routes.taskDetails}/${notification.taskId}',
                                        ),
                                        child: Container(
                                          height: 40,
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBF0EA),
                                            borderRadius:
                                                BorderRadius.circular(48),
                                          ),
                                          child: const Text(
                                            'View Task',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF125420),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _titleWithTask(String title, int? taskId) =>
    taskId == null ? title : '$title  #$taskId';

String _relativeTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  return '${time.day.toString().padLeft(2, '0')}/'
      '${time.month.toString().padLeft(2, '0')}/${time.year}';
}
