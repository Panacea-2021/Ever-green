import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../web/theme/web_tokens.dart';
import '../../../../web/widgets/web_search_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/announcement_provider.dart';
import '../../domain/announcement.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _search = TextEditingController();
  final Set<String> _activeRecipientFilters = {};
  final Set<String> _selectedPeople = {};
  final Set<String> _excludedPeople = {};
  bool _allEligible = false;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final searchQuery = ref.watch(webModuleSearchQueryProvider);
    final role = currentUser?.role ?? UserRole.client;
    final canCreate = Permissions.canCreateAnnouncements(role);
    final announcementState = ref.watch(announcementControllerProvider);

    return announcementState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: WebTokens.green),
      ),
      error: (error, _) => _loadError(error),
      data: (data) {
        final directoryUsers = data.recipientDirectory
            .map(
              (recipient) => User(
                id: recipient.id,
                email: '',
                name: recipient.name,
                role: recipient.role,
                designation: recipient.role.designation,
              ),
            )
            .toList();
        final recipients = currentUser == null
            ? <User>[]
            : _eligibleUsers(directoryUsers, role);
        final directory = AsyncData<List<User>>(recipients);
        final selectedRecipients = _selectedRecipients(recipients);
        final history = data.announcements.where((announcement) {
          return announcement.senderId == currentUser?.id &&
              matchesWebSearchTerms(searchQuery, [
                announcement.title,
                announcement.message,
                announcement.senderName,
                ...announcement.recipients.map((recipient) => recipient.name),
              ]);
        }).toList();
        final inbox = currentUser == null
            ? const <({
                AnnouncementNotification notification,
                Announcement announcement
              })>[]
            : data
                .inboxFor(currentUser.id)
                .where(
                  (item) => matchesWebSearchTerms(
                    searchQuery,
                    [
                      item.announcement.title,
                      item.announcement.message,
                      item.announcement.senderName,
                    ],
                  ),
                )
                .toList();

        return ColoredBox(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pageHeading(data.unreadCountFor(currentUser?.id ?? '')),
                    if (canCreate && data.managementError != null) ...[
                      const SizedBox(height: 18),
                      _managementLoadError(data.managementError!),
                    ],
                    const SizedBox(height: 18),
                    if (canCreate && data.managementError == null) ...[
                      const SizedBox(height: 24),
                      const _SectionHeading(
                        title: 'Create announcement',
                        subtitle: 'Compose a message and choose its audience.',
                      ),
                      const SizedBox(height: 12),
                      _ComposerCard(
                        titleController: _title,
                        messageController: _message,
                        directory: directory,
                        recipients: recipients,
                        allEligible: _allEligible,
                        activeFilters: _activeRecipientFilters,
                        selectedPeople: _selectedPeople,
                        excludedPeople: _excludedPeople,
                        selectedRecipients: selectedRecipients,
                        searchController: _search,
                        sending: _sending,
                        onSearchChanged: () => setState(() {}),
                        onSelectAll: _toggleAll,
                        onToggleFilter: (filterKey) =>
                            _toggleRecipientFilter(filterKey, recipients),
                        onTogglePerson: _togglePerson,
                        onSend: () => _send(selectedRecipients),
                      ),
                      const SizedBox(height: 28),
                      const _SectionHeading(
                        title: 'Announcement history',
                        subtitle: 'Announcements created by you.',
                      ),
                      const SizedBox(height: 12),
                      _HistoryCard(
                        announcements: history,
                        onOpen: (announcement) =>
                            _showAnnouncement(announcement, history: true),
                      ),
                      const SizedBox(height: 28),
                    ],
                    _SectionHeading(
                      title: 'My notifications',
                      subtitle:
                          '${data.unreadCountFor(currentUser?.id ?? '')} unread',
                    ),
                    const SizedBox(height: 12),
                    _InboxCard(
                      items: inbox,
                      onOpen: _openNotification,
                    ),
                    if (canCreate && data.managementError == null) ...[
                      const SizedBox(height: 22),
                      _LocalTaskNotificationsLink(
                        onTap: () => context.go('/notifications'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pageHeading(int unreadCount) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [WebTokens.greenDeep, WebTokens.green],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: WebTokens.greenDeep.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Messages and updates for your Evergreen workspace',
                style: WebTokens.bodyText(
                  15,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$unreadCount unread',
                style: WebTokens.bodyText(
                  12,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _loadError(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text('Could not load announcements: $error'),
              TextButton(
                onPressed: () => ref.invalidate(announcementControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _managementLoadError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0C9C1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB34F43)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${message == 'Access denied' ? 'Access denied. Ask your Super Admin to verify your Manager role and company assignment.' : 'Announcement management could not be loaded: $message.'} '
                'Your notifications are still available below.',
                style: WebTokens.bodyText(13, color: WebTokens.ink),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  List<User> _eligibleUsers(List<User> users, UserRole senderRole) {
    return users
        .where(
          (user) =>
              user.isActive &&
              user.id.isNotEmpty &&
              AnnouncementPolicy.canSelectRecipient(senderRole, user.role),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<AnnouncementRecipient> _selectedRecipients(List<User> users) {
    final selected = <String, AnnouncementRecipient>{};
    final selectedFilters = AnnouncementRecipientFilter.forUsers(users)
        .where((filter) => _activeRecipientFilters.contains(filter.key));
    for (final user in users) {
      final included = _allEligible ||
          _selectedPeople.contains(user.id) ||
          AnnouncementRecipientFilter.matchesAny(selectedFilters, user);
      if (included && !_excludedPeople.contains(user.id)) {
        selected.putIfAbsent(
          user.id,
          () => AnnouncementRecipient(
            id: user.id,
            name: user.name,
            role: user.role,
          ),
        );
      }
    }
    return selected.values.toList();
  }

  void _toggleAll() {
    setState(() {
      _allEligible = !_allEligible;
      _excludedPeople.clear();
    });
  }

  void _toggleRecipientFilter(String filterKey, List<User> users) {
    setState(() {
      if (_activeRecipientFilters.contains(filterKey)) {
        _activeRecipientFilters.remove(filterKey);
      } else {
        _activeRecipientFilters.add(filterKey);
        final filter = AnnouncementRecipientFilter.forUsers(users)
            .where((candidate) => candidate.key == filterKey)
            .firstOrNull;
        if (filter != null) {
          _excludedPeople.removeWhere(
            (id) => users.any(
              (user) => user.id == id && filter.matches(user),
            ),
          );
        }
      }
    });
  }

  void _togglePerson(User user, bool isSelected) {
    setState(() {
      if (isSelected) {
        final selectedFilters = AnnouncementRecipientFilter.forUsers([user])
            .where((filter) => _activeRecipientFilters.contains(filter.key));
        if (_allEligible ||
            AnnouncementRecipientFilter.matchesAny(selectedFilters, user)) {
          _excludedPeople.add(user.id);
        } else {
          _selectedPeople.remove(user.id);
        }
      } else {
        _excludedPeople.remove(user.id);
        _selectedPeople.add(user.id);
      }
    });
  }

  Future<void> _send(List<AnnouncementRecipient> recipients) async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      _showMessage('Add a title and message before sending.');
      return;
    }
    if (recipients.isEmpty) {
      _showMessage('Select at least one recipient.');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(announcementControllerProvider.notifier).send(
            title: _title.text,
            message: _message.text,
            recipients: recipients,
          );
      _title.clear();
      _message.clear();
      setState(() {
        _allEligible = false;
        _selectedPeople.clear();
        _excludedPeople.clear();
      });
      _showMessage('Announcement sent successfully.');
    } catch (error) {
      _showMessage('Could not send announcement: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openNotification(
    AnnouncementNotification notification,
    Announcement announcement,
  ) async {
    try {
      await ref
          .read(announcementControllerProvider.notifier)
          .markRead(announcement.id);
    } catch (error) {
      _showMessage('Could not mark announcement as read: $error');
    }
    if (mounted) await _showAnnouncement(announcement);
  }

  Future<void> _showAnnouncement(
    Announcement announcement, {
    bool history = false,
  }) =>
      showDialog<void>(
        context: context,
        builder: (context) => _AnnouncementDetailsDialog(
          announcement: announcement,
          history: history,
        ),
      );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.titleController,
    required this.messageController,
    required this.directory,
    required this.recipients,
    required this.allEligible,
    required this.activeFilters,
    required this.selectedPeople,
    required this.excludedPeople,
    required this.selectedRecipients,
    required this.searchController,
    required this.sending,
    required this.onSearchChanged,
    required this.onSelectAll,
    required this.onToggleFilter,
    required this.onTogglePerson,
    required this.onSend,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final AsyncValue<List<User>> directory;
  final List<User> recipients;
  final bool allEligible;
  final Set<String> activeFilters;
  final Set<String> selectedPeople;
  final Set<String> excludedPeople;
  final List<AnnouncementRecipient> selectedRecipients;
  final TextEditingController searchController;
  final bool sending;
  final VoidCallback onSearchChanged;
  final VoidCallback onSelectAll;
  final ValueChanged<String> onToggleFilter;
  final void Function(User, bool) onTogglePerson;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              maxLength: 120,
              decoration: _inputDecoration(
                'Announcement title',
                Icons.short_text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              minLines: 4,
              maxLines: 8,
              maxLength: 4000,
              decoration: _inputDecoration(
                'Announcement message',
                Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recipients',
                    style: WebTokens.heading(16),
                  ),
                ),
                Text(
                  '${selectedRecipients.length} selected',
                  style: WebTokens.bodyText(
                    12,
                    color: WebTokens.green,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (directory.isLoading)
              const LinearProgressIndicator(color: WebTokens.green)
            else if (directory.hasError)
              _DirectoryError(error: directory.error!)
            else if (recipients.isEmpty)
              Text(
                'No recipient directory is available for this account.',
                style: WebTokens.bodyText(13),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('Select all eligible'),
                    selected: allEligible,
                    onSelected: (_) => onSelectAll(),
                  ),
                  for (final filter in _availableFilters(recipients))
                    FilterChip(
                      label: Text(filter.label),
                      selected: activeFilters.contains(filter.key),
                      onSelected: (_) => onToggleFilter(filter.key),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Selecting a role or Cold Room Service Engineer automatically selects matching users. Use the checkboxes to adjust recipients.',
                  style: WebTokens.bodyText(11),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                decoration: _inputDecoration(
                  'Search users by name',
                  Icons.search,
                ),
                onChanged: (_) => onSearchChanged(),
              ),
              const SizedBox(height: 8),
              _RecipientList(
                users: _filteredRecipients,
                selectedFilters: _availableFilters(recipients)
                    .where((filter) => activeFilters.contains(filter.key))
                    .toList(),
                selectedPeople: selectedPeople,
                excludedPeople: excludedPeople,
                allEligible: allEligible,
                onToggle: onTogglePerson,
              ),
            ],
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    sending || selectedRecipients.isEmpty ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: WebTokens.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(sending ? 'Sending…' : 'Send announcement'),
              ),
            ),
          ],
        ),
      );

  List<AnnouncementRecipientFilter> _availableFilters(List<User> users) =>
      AnnouncementRecipientFilter.forUsers(users);

  List<User> get _filteredRecipients {
    final filters = _availableFilters(recipients)
        .where((filter) => activeFilters.contains(filter.key))
        .toList();
    final query = searchController.text.trim().toLowerCase();
    return recipients.where((user) {
      final matchesFilter =
          filters.isEmpty || filters.any((filter) => filter.matches(user));
      final matchesSearch = user.name.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }
}

class _RecipientList extends StatelessWidget {
  const _RecipientList({
    required this.users,
    required this.selectedFilters,
    required this.selectedPeople,
    required this.excludedPeople,
    required this.allEligible,
    required this.onToggle,
  });

  final List<User> users;
  final List<AnnouncementRecipientFilter> selectedFilters;
  final Set<String> selectedPeople;
  final Set<String> excludedPeople;
  final bool allEligible;
  final void Function(User, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('No matching users.', style: WebTokens.bodyText(13)),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        border: Border.all(color: WebTokens.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: WebTokens.line),
        itemBuilder: (context, index) {
          final user = users[index];
          final included = allEligible ||
              selectedPeople.contains(user.id) ||
              AnnouncementRecipientFilter.matchesAny(selectedFilters, user);
          final selected = included && !excludedPeople.contains(user.id);
          return CheckboxListTile(
            value: selected,
            activeColor: WebTokens.green,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(user.name, style: WebTokens.bodyText(13)),
            subtitle: Text(
              '${user.role.label}${user.email.isEmpty ? '' : ' · ${user.email}'}',
              style: WebTokens.bodyText(11),
            ),
            onChanged: (value) => onToggle(user, selected),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.announcements,
    required this.onOpen,
  });

  final List<Announcement> announcements;
  final ValueChanged<Announcement> onOpen;

  @override
  Widget build(BuildContext context) => Container(
        decoration: _cardDecoration(),
        child: announcements.isEmpty
            ? const _EmptyState(
                icon: Icons.history,
                message: 'Your sent announcements will appear here.',
              )
            : Column(
                children: [
                  for (var index = 0;
                      index < announcements.length;
                      index++) ...[
                    _HistoryRow(
                      announcement: announcements[index],
                      onTap: () => onOpen(announcements[index]),
                    ),
                    if (index != announcements.length - 1)
                      const Divider(height: 1, color: WebTokens.line),
                  ],
                ],
              ),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.announcement, required this.onTap});

  final Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        title: Text(
          announcement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WebTokens.bodyText(
            14,
            color: WebTokens.ink,
            weight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${_preview(announcement.message)}\n'
            '${announcement.senderName} · ${_formatDate(announcement.createdAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WebTokens.bodyText(12),
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${announcement.recipients.length} recipients',
              style: WebTokens.bodyText(11),
            ),
            const SizedBox(height: 5),
            const _StatusPill(label: 'Sent', color: WebTokens.green),
          ],
        ),
      );
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.items, required this.onOpen});

  final List<
          ({AnnouncementNotification notification, Announcement announcement})>
      items;
  final void Function(AnnouncementNotification, Announcement) onOpen;

  @override
  Widget build(BuildContext context) => Container(
        decoration: _cardDecoration(),
        child: items.isEmpty
            ? const _EmptyState(
                icon: Icons.notifications_none,
                message: 'No announcement notifications for this account.',
              )
            : Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _InboxRow(
                      item: items[index],
                      onTap: () => onOpen(
                        items[index].notification,
                        items[index].announcement,
                      ),
                    ),
                    if (index != items.length - 1)
                      const Divider(height: 1, color: WebTokens.line),
                  ],
                ],
              ),
      );
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.item, required this.onTap});

  final ({
    AnnouncementNotification notification,
    Announcement announcement
  }) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(
          item.notification.isRead
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
          color: item.notification.isRead ? WebTokens.faint : WebTokens.green,
        ),
        title: Text(
          item.announcement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WebTokens.bodyText(
            14,
            color: WebTokens.ink,
            weight:
                item.notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${item.announcement.senderName} · '
          '${_formatDate(item.announcement.createdAt)}\n'
          '${_preview(item.announcement.message)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WebTokens.bodyText(12),
        ),
        isThreeLine: true,
        trailing: item.notification.isRead
            ? const _StatusPill(label: 'Read', color: WebTokens.faint)
            : const _StatusPill(label: 'Unread', color: WebTokens.green),
      );
}

class _AnnouncementDetailsDialog extends StatelessWidget {
  const _AnnouncementDetailsDialog({
    required this.announcement,
    this.history = false,
  });

  final Announcement announcement;
  final bool history;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(announcement.title, style: WebTokens.heading(20)),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(announcement.message, style: WebTokens.bodyText(14)),
                const SizedBox(height: 18),
                Text(
                  'From ${announcement.senderName} · '
                  '${_formatDate(announcement.createdAt)}',
                  style: WebTokens.bodyText(12),
                ),
                if (history) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Recipients (${announcement.recipients.length})',
                    style: WebTokens.bodyText(
                      13,
                      color: WebTokens.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final recipient in announcement.recipients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${recipient.name} · ${recipient.role.label}',
                        style: WebTokens.bodyText(12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const _StatusPill(label: 'Sent', color: WebTokens.green),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Could not load the recipient directory: $error',
          style: WebTokens.bodyText(12, color: Colors.red.shade700),
        ),
      );
}

class _LocalTaskNotificationsLink extends StatelessWidget {
  const _LocalTaskNotificationsLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.build_outlined, size: 18),
          label: const Text('Open task notifications'),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WebTokens.heading(18)),
          const SizedBox(height: 2),
          Text(subtitle, style: WebTokens.bodyText(12)),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(26),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 28, color: WebTokens.faint),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: WebTokens.bodyText(12),
              ),
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: WebTokens.bodyText(
            10,
            color: color,
            weight: FontWeight.w700,
          ),
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WebTokens.line),
      boxShadow: WebTokens.softShadow,
    );

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: WebTokens.faint),
      filled: true,
      fillColor: WebTokens.cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebTokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebTokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebTokens.green),
      ),
    );

String _preview(String message) =>
    message.length <= 110 ? message : '${message.substring(0, 110)}…';

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour =
      (local.hour % 12 == 0 ? 12 : local.hour % 12).toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month/$day/${local.year} $hour:$minute $period';
}
