import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/announcement_provider.dart';
import '../../domain/announcement.dart';

const _announcementGreen = Color(0xFF125420);
const _announcementInk = Color(0xFF1C2B20);
const _announcementMuted = Color(0xFF6B6B6B);

class MobileAnnouncementsScreen extends ConsumerWidget {
  const MobileAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final announcements = ref.watch(announcementControllerProvider);
    final canCreate =
        user != null && Permissions.canCreateAnnouncements(user.role);
    final unreadCount = user == null
        ? 0
        : announcements.valueOrNull?.unreadCountFor(user.id) ?? 0;

    return DefaultTabController(
      length: canCreate ? 2 : 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
          ),
          title: const Text('Announcements'),
          actions: [
            if (unreadCount > 0)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _announcementGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount unread',
                    style: const TextStyle(
                      color: _announcementGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Refresh announcements',
              onPressed: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: canCreate
              ? const TabBar(
                  labelColor: _announcementGreen,
                  indicatorColor: _announcementGreen,
                  tabs: [
                    Tab(text: 'Inbox'),
                    Tab(text: 'History'),
                  ],
                )
              : null,
        ),
        body: announcements.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _announcementGreen),
          ),
          error: (error, _) => _AnnouncementLoadError(
            error: error,
            onRetry: () =>
                ref.read(announcementControllerProvider.notifier).refresh(),
          ),
          data: (data) {
            if (user == null) {
              return const _AnnouncementMessage(
                icon: Icons.lock_outline,
                title: 'Sign in to view announcements',
                subtitle: 'Your announcements are available after sign-in.',
              );
            }
            final inbox = data.inboxFor(user.id);
            final history = data.announcements
                .where(
                  (announcement) =>
                      user.role == UserRole.superAdmin ||
                      announcement.senderId == user.id,
                )
                .toList()
              ..sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );

            final inboxTab = _AnnouncementList(
              items: [
                for (final item in inbox)
                  _AnnouncementListItem(
                    announcement: item.announcement,
                    isRead: item.notification.isRead,
                    onTap: () => _openInboxItem(context, ref, item),
                  ),
              ],
              emptyIcon: Icons.campaign_outlined,
              emptyTitle: 'No announcements yet',
              emptySubtitle: 'Announcements sent to you will appear here.',
              onRefresh: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
            );
            final historyTab = _AnnouncementList(
              items: [
                for (final announcement in history)
                  _AnnouncementListItem(
                    announcement: announcement,
                    isRead: true,
                    showRecipients: true,
                    onTap: () => _openHistoryItem(context, announcement),
                  ),
              ],
              emptyIcon: Icons.history,
              emptyTitle: 'No announcement history',
              emptySubtitle: 'Announcements you send will appear here.',
              onRefresh: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
            );

            return canCreate
                ? TabBarView(children: [inboxTab, historyTab])
                : inboxTab;
          },
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                backgroundColor: _announcementGreen,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Create announcement'),
                onPressed: () => _openComposer(
                  context,
                  ref,
                  announcements.valueOrNull?.recipientDirectory ?? const [],
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _openInboxItem(
    BuildContext context,
    WidgetRef ref,
    ({AnnouncementNotification notification, Announcement announcement}) item,
  ) async {
    final navigator = Navigator.of(context);
    if (!item.notification.isRead) {
      try {
        await ref
            .read(announcementControllerProvider.notifier)
            .markRead(item.announcement.id);
      } catch (error) {
        if (context.mounted) {
          _showAnnouncementError(context, 'Could not mark as read', error);
        }
      }
    }
    if (!context.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailsScreen(
          announcement: item.announcement,
        ),
      ),
    );
  }

  Future<void> _openHistoryItem(
    BuildContext context,
    Announcement announcement,
  ) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailsScreen(
            announcement: announcement,
            showRecipients: true,
          ),
        ),
      );

  Future<void> _openComposer(
    BuildContext context,
    WidgetRef ref,
    List<AnnouncementRecipient> recipients,
  ) async {
    if (recipients.isEmpty) {
      _showAnnouncementError(
        context,
        'Recipient list unavailable',
        StateError('No permitted recipients were returned for this account.'),
      );
      return;
    }
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobileAnnouncementComposerScreen(
          recipients: recipients,
        ),
      ),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement sent successfully.')),
      );
    }
  }
}

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  final List<_AnnouncementListItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: _announcementGreen,
        onRefresh: onRefresh,
        child: items.isEmpty
            ? _AnnouncementMessage(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _AnnouncementCard(
                  item: items[index],
                ),
              ),
      );
}

class _AnnouncementListItem {
  const _AnnouncementListItem({
    required this.announcement,
    required this.isRead,
    required this.onTap,
    this.showRecipients = false,
  });

  final Announcement announcement;
  final bool isRead;
  final bool showRecipients;
  final VoidCallback onTap;
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final _AnnouncementListItem item;

  @override
  Widget build(BuildContext context) {
    final announcement = item.announcement;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: item.onTap,
        leading: CircleAvatar(
          backgroundColor: item.isRead
              ? Colors.grey.shade100
              : _announcementGreen.withValues(alpha: 0.1),
          child: Icon(
            item.isRead ? Icons.mark_email_read_outlined : Icons.campaign,
            color: item.isRead ? _announcementMuted : _announcementGreen,
          ),
        ),
        title: Text(
          announcement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _announcementInk,
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From ${announcement.senderName} · '
                '${_announcementDate(context, announcement.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                announcement.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.showRecipients)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${announcement.recipients.length} recipient'
                    '${announcement.recipients.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: _announcementGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: item.isRead
            ? const Icon(Icons.check_circle_outline, color: _announcementMuted)
            : const _UnreadDot(),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: _announcementGreen,
          shape: BoxShape.circle,
        ),
      );
}

class _AnnouncementMessage extends StatelessWidget {
  const _AnnouncementMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 52, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _announcementInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _announcementMuted,
                        fontSize: 13,
                      ),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 14),
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
        ),
      );
}

class _AnnouncementLoadError extends StatelessWidget {
  const _AnnouncementLoadError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _AnnouncementMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load announcements',
        subtitle: _announcementErrorText(error),
        onRetry: onRetry,
      );
}

class AnnouncementDetailsScreen extends StatelessWidget {
  const AnnouncementDetailsScreen({
    required this.announcement,
    this.showRecipients = false,
    super.key,
  });

  final Announcement announcement;
  final bool showRecipients;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Announcement'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              announcement.title,
              style: const TextStyle(
                color: _announcementInk,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'From ${announcement.senderName} · '
              '${_announcementDate(context, announcement.createdAt)}',
              style: const TextStyle(
                color: _announcementMuted,
                fontSize: 13,
              ),
            ),
            const Divider(height: 28),
            SelectableText(
              announcement.message,
              style: const TextStyle(
                color: _announcementInk,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (showRecipients) ...[
              const SizedBox(height: 28),
              Text(
                'Recipients (${announcement.recipients.length})',
                style: const TextStyle(
                  color: _announcementInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (announcement.recipients.isEmpty)
                const Text(
                  'Recipient details are not available.',
                  style: TextStyle(color: _announcementMuted),
                )
              else
                for (final recipient in announcement.recipients)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.person_outline,
                      color: _announcementGreen,
                    ),
                    title: Text(recipient.name),
                    subtitle: Text(recipient.role.label),
                  ),
            ],
          ],
        ),
      );
}

class MobileAnnouncementComposerScreen extends ConsumerStatefulWidget {
  const MobileAnnouncementComposerScreen({
    required this.recipients,
    super.key,
  });

  final List<AnnouncementRecipient> recipients;

  @override
  ConsumerState<MobileAnnouncementComposerScreen> createState() =>
      _MobileAnnouncementComposerScreenState();
}

class _MobileAnnouncementComposerScreenState
    extends ConsumerState<MobileAnnouncementComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  List<AnnouncementRecipient> _selectedRecipients = const [];
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Create announcement')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _message,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a message.'
                      : null,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: _announcementGreen,
                    ),
                    title: const Text('Recipients'),
                    subtitle: Text(
                      _selectedRecipients.isEmpty
                          ? 'No recipients selected'
                          : '${_selectedRecipients.length} selected',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectRecipients,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_sending ? 'Sending...' : 'Send announcement'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _announcementGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _selectRecipients() async {
    final selected =
        await Navigator.of(context).push<List<AnnouncementRecipient>>(
      MaterialPageRoute(
        builder: (_) => MobileRecipientSelectionScreen(
          recipients: widget.recipients,
          initialSelection: _selectedRecipients,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedRecipients = selected);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipients.isEmpty) {
      _showAnnouncementError(
        context,
        'Select recipients',
        StateError('Select at least one recipient.'),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(announcementControllerProvider.notifier).send(
            title: _title.text,
            message: _message.text,
            recipients: _selectedRecipients,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showAnnouncementError(context, 'Could not send announcement', error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class MobileRecipientSelectionScreen extends StatefulWidget {
  const MobileRecipientSelectionScreen({
    required this.recipients,
    this.initialSelection = const [],
    super.key,
  });

  final List<AnnouncementRecipient> recipients;
  final List<AnnouncementRecipient> initialSelection;

  @override
  State<MobileRecipientSelectionScreen> createState() =>
      _MobileRecipientSelectionScreenState();
}

class _MobileRecipientSelectionScreenState
    extends State<MobileRecipientSelectionScreen> {
  final _search = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds
        .addAll(widget.initialSelection.map((recipient) => recipient.id));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.recipients
        .where(
          (recipient) =>
              recipient.name.toLowerCase().contains(query) ||
              recipient.role.label.toLowerCase().contains(query),
        )
        .toList();
    final allVisibleSelected = visible.isNotEmpty &&
        visible.every((recipient) => _selectedIds.contains(recipient.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select recipients'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop([
              for (final recipient in widget.recipients)
                if (_selectedIds.contains(recipient.id)) recipient,
            ]),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search people or roles',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          CheckboxListTile(
            value: allVisibleSelected,
            onChanged: visible.isEmpty
                ? null
                : (_) => setState(() {
                      if (allVisibleSelected) {
                        _selectedIds.removeAll(
                          visible.map((recipient) => recipient.id),
                        );
                      } else {
                        _selectedIds.addAll(
                          visible.map((recipient) => recipient.id),
                        );
                      }
                    }),
            title: const Text('Select all shown'),
            subtitle: Text('${_selectedIds.length} selected'),
            activeColor: _announcementGreen,
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const _AnnouncementMessage(
                    icon: Icons.person_search_outlined,
                    title: 'No recipients found',
                    subtitle: 'Try a different search.',
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final recipient = visible[index];
                      return CheckboxListTile(
                        value: _selectedIds.contains(recipient.id),
                        activeColor: _announcementGreen,
                        title: Text(recipient.name),
                        subtitle: Text(recipient.role.label),
                        onChanged: (selected) => setState(() {
                          if (selected == true) {
                            _selectedIds.add(recipient.id);
                          } else {
                            _selectedIds.remove(recipient.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _announcementErrorText(Object error) {
  if (error is FailureException) {
    final failure = error.failure;
    if (failure is AuthenticationFailure) {
      return failure.message == 'Access denied'
          ? 'You do not have permission to access this announcement.'
          : 'Your session is no longer valid. Please sign in again.';
    }
    if (failure is ServerFailure) {
      if (failure.statusCode == 404) {
        return 'The announcement service could not find this resource.';
      }
      if (failure.statusCode >= 500) {
        return 'The announcement service is temporarily unavailable. Try again.';
      }
    }
    return failure.displayMessage;
  }
  return error.toString();
}

void _showAnnouncementError(
  BuildContext context,
  String title,
  Object error,
) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$title: ${_announcementErrorText(error)}')),
    );
}

String _announcementDate(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final formattedDate =
      MaterialLocalizations.of(context).formatMediumDate(local);
  final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
  );
  return '$formattedDate · $formattedTime';
}
