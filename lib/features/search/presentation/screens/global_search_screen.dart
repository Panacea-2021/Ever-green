import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../amcs/domain/models/amc_contract.dart' show displayDate;
import '../../../auth/domain/models/user_model.dart';
import '../../domain/global_search.dart';

const _green = Color(0xFF106220);

/// One search box over companies, equipment, tasks and service engineers.
/// Each tab lists the items matching the query (all items when it is blank)
/// and its label carries the match count. Every list is already scoped to the
/// signed-in user by the backend; tabs are limited by [searchTabsFor].
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _Hit {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _Hit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.badgeColor = _green,
  });
}

/// One tab's data source and its filtered hits.
class _TabResult {
  final AsyncValue<Object?> source;
  final List<_Hit> hits;
  final VoidCallback retry;
  final Future<void> Function() refresh;

  const _TabResult(this.source, this.hits, this.retry, this.refresh);

  bool get loading => source.isLoading && !source.hasValue;
  bool get failed => source.hasError && !source.hasValue;
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  Timer? _timer;
  String _query = '';
  SearchTab? _selected;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // clear button visibility
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _submit(String value) {
    _timer?.cancel();
    setState(() => _query = value.trim());
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  String _join(Iterable<String?> parts) =>
      parts.where((p) => p != null && p.trim().isNotEmpty).join(' • ');

  // ---------------------------------------------------------------------------
  // Hits
  // ---------------------------------------------------------------------------

  _Hit _companyHit(Company c) => _Hit(
        title: c.name,
        subtitle: _join([c.branchName, c.location, c.serviceLabel]),
        icon: Icons.business_outlined,
        badge: c.isAmcExpired ? 'Expired' : null,
        badgeColor: const Color(0xFFC62828),
        onTap: () => context.push(
          '${Routes.companyDetails}/${c.id}',
          extra: {
            'companyName': c.name,
            'location':
                c.branchName.isNotEmpty ? c.branchName : (c.location ?? ''),
          },
        ),
      );

  _Hit _equipmentHit(Equipment e, String? companyName) => _Hit(
        title: e.name,
        subtitle: _join([
          e.egSerialNumber,
          _join([e.make, e.model]),
          companyName,
        ]),
        icon: Icons.precision_manufacturing_outlined,
        onTap: () => context.push(
          '${Routes.equipmentDetails}/${e.id}',
          extra: {
            'equipmentName': e.name,
            'location': e.location,
            'imageUrl': e.imageUrl,
            'make': e.make,
            'model': e.model,
            'serialNumber': e.serialNumber,
            'companyId': (e.companyId ?? e.company?.id)?.toString(),
            'companyName': companyName,
          },
        ),
      );

  _Hit _taskHit(ServiceTask t) {
    final contact = taskContact(t);
    final created = t.createdAt;
    final who = t.company?.displayName ?? contact.name;
    return _Hit(
      title: t.name.isNotEmpty ? t.name : 'Ticket ${t.ticketNo}',
      subtitle: _join([
        t.ticketNo.isNotEmpty ? '#${t.ticketNo}' : null,
        t.equipment?.name,
        who,
      ]),
      icon: Icons.task_alt,
      badge: t.status.label,
      badgeColor: _statusColor(t.status),
      onTap: () => context.push(
        '${Routes.taskDetails}/${t.id}',
        extra: {
          'taskTitle': t.name,
          'location': t.equipment?.location ?? contact.address,
          'status': t.status.label,
          'imageUrl': mediaUrl(t.equipment?.imageUrl),
          'companyName': who,
          'clientName': t.client?.name ?? contact.name,
          'mobile': t.client?.phone ?? contact.phone,
          'technician': t.technician?.name,
          'technicianMobile': t.technician?.phone,
          'serialNumber': t.equipment?.egSerialNumber,
          'description': t.description,
          if (created != null) 'createdOn': displayDate(created),
        },
      ),
    );
  }

  _Hit _engineerHit(User u) => _Hit(
        title: u.name,
        subtitle: _join([engineerDesignation(u), u.phone]),
        icon: Icons.engineering_outlined,
        badge: u.isActive ? null : 'Inactive',
        badgeColor: const Color(0xFF8A8A8A),
        onTap: () => context.push(
          Routes.technicianTasks,
          extra: {'technicianId': u.id, 'technicianName': u.name},
        ),
      );

  Color _statusColor(TaskStatus s) => switch (s) {
        TaskStatus.open => const Color(0xFF1565C0),
        TaskStatus.hold => const Color(0xFFE65100),
        TaskStatus.inProgress => const Color(0xFF6A1B9A),
        TaskStatus.completed => _green,
        TaskStatus.closed => const Color(0xFF616161),
      };

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  _TabResult _results(SearchTab tab, List<SearchTab> tabs) {
    switch (tab) {
      case SearchTab.companies:
        final src = ref.watch(companiesProvider);
        final items = filterByQuery(
          src.valueOrNull ?? const <Company>[],
          _query,
          companySearchFields,
        );
        return _TabResult(
          src,
          items.map(_companyHit).toList(),
          () => ref.invalidate(companiesProvider),
          () => ref.refresh(companiesProvider.future),
        );
      case SearchTab.equipments:
        final src = ref.watch(equipmentsProvider(null));
        final companies = tabs.contains(SearchTab.companies)
            ? ref.watch(companiesProvider).valueOrNull ?? const <Company>[]
            : const <Company>[];
        final names = {for (final c in companies) c.id: c.displayName};
        String? nameOf(Equipment e) =>
            e.company?.displayName ?? names[e.companyId];
        final items = filterByQuery(
          src.valueOrNull ?? const <Equipment>[],
          _query,
          (Equipment e) => equipmentSearchFields(e, companyName: nameOf(e)),
        );
        return _TabResult(
          src,
          [for (final e in items) _equipmentHit(e, nameOf(e))],
          () => ref.invalidate(equipmentsProvider(null)),
          () => ref.refresh(equipmentsProvider(null).future),
        );
      case SearchTab.tasks:
        final src = ref.watch(tasksProvider);
        final items = filterByQuery(
          src.valueOrNull ?? const <ServiceTask>[],
          _query,
          taskSearchFields,
        );
        return _TabResult(
          src,
          items.map(_taskHit).toList(),
          () => ref.invalidate(tasksProvider),
          () => ref.refresh(tasksProvider.future),
        );
      case SearchTab.serviceEngineers:
        final src = ref.watch(techniciansProvider);
        final items = filterByQuery(
          src.valueOrNull ?? const <User>[],
          _query,
          engineerSearchFields,
        );
        return _TabResult(
          src,
          items.map(_engineerHit).toList(),
          () => ref.invalidate(techniciansProvider),
          () => ref.refresh(techniciansProvider.future),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final tabs = searchTabsFor(role);
    final selected = tabs.contains(_selected) ? _selected! : tabs.first;
    final results = {for (final t in tabs) t: _results(t, tabs)};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          // Same patterned background treatment as the Home screen.
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                _searchField(),
                _tabBar(tabs, selected, results),
                const SizedBox(height: 8),
                Expanded(child: _tabBody(selected, results[selected]!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _submit,
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search companies, equipment, tasks…',
            hintStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Color(0xFF9B9B9B),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9B9B9B)),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, color: Color(0xFF9B9B9B)),
                    onPressed: _clear,
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
        ),
      ),
    );
  }

  /// Underline-style tabs (active: green label with a green underline as wide
  /// as the label), each with its match count.
  Widget _tabBar(
    List<SearchTab> tabs,
    SearchTab selected,
    Map<SearchTab, _TabResult> results,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: _tabItem(tab, tab == selected, results[tab]!),
            ),
        ],
      ),
    );
  }

  Widget _tabItem(SearchTab tab, bool active, _TabResult result) {
    final color = active ? _green : const Color(0xFF8A8A8A);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = tab),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tab.label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
                if (!result.loading && !result.failed) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${result.hits.length}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: active ? 1 : 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(SearchTab tab, _TabResult r) {
    if (r.loading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (r.failed) {
      return _centerMsg(
        Icons.cloud_off_outlined,
        "Couldn't load ${tab.label.toLowerCase()}",
        'Check your connection and try again.',
        onRetry: r.retry,
      );
    }
    final noun = tab.label.toLowerCase();
    return RefreshIndicator(
      color: _green,
      onRefresh: r.refresh,
      child: r.hits.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 280,
                  child: _query.isEmpty
                      ? _centerMsg(
                          Icons.inbox_outlined,
                          'No $noun yet',
                          'Nothing to show here.',
                        )
                      : _centerMsg(
                          Icons.search_off,
                          'No matching $noun',
                          'Try a different term.',
                        ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: r.hits.length,
              itemBuilder: (_, i) => _hitTile(r.hits[i]),
            ),
    );
  }

  Widget _hitTile(_Hit h) {
    return _PressableScale(
      onTap: h.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(h.icon, color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  if (h.subtitle.isNotEmpty)
                    Text(
                      h.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                ],
              ),
            ),
            if (h.badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: h.badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  h.badge!,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: h.badgeColor,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }

  Widget _centerMsg(
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            sub,
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
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Search',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small press-scale wrapper for the result cards.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
