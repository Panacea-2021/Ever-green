import 'package:flutter/material.dart';
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

  void _onNotificationTap(NotificationEntry entry) {
    final n = entry.notification;
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
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                      error: (e, _) => _message(
                        icon: Icons.cloud_off_outlined,
                        title: "Couldn't load notifications",
                        subtitle: '$e',
                        onRetry: _refresh,
                      ),
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

  Widget _buildHeader(BuildContext context, bool hasUnread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 39, 16, 24),
      child: Row(
        children: [
          // Back button
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
          // Title
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
          ),
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
            feed.loadMoreError == null) {
          // Prefetch the next page as the end comes into view.
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
