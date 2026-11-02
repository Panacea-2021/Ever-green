import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../technicians/data/performance_provider.dart';
import '../../data/audit_log_provider.dart';
import '../../domain/models/audit_log_entry.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // null = All; otherwise filter by this entity.
  AuditEntity? _entityFilter;

  // null = All time; otherwise only entries whose timestamp is in this range.
  DateRange? _dateRange;

  static const Color _green = Color(0xFF106220);

  final ScrollController _webScroll = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _webScroll.dispose();
    super.dispose();
  }

  static const _webEntityFilters = <(String, AuditEntity?, IconData)>[
    ('All', null, Icons.apps_rounded),
    ('Users', AuditEntity.user, Icons.people_outline),
    ('Tasks', AuditEntity.task, Icons.assignment_outlined),
    ('AMCs', AuditEntity.amc, Icons.handshake_outlined),
    ('Equipment', AuditEntity.equipment, Icons.precision_manufacturing_outlined),
  ];

  static const _webDateFilters = <(String, RangePreset?, IconData)>[
    ('All time', null, Icons.all_inclusive),
    ('Today', RangePreset.today, Icons.today_outlined),
    ('This Week', RangePreset.week, Icons.date_range_outlined),
    ('This Month', RangePreset.month, Icons.calendar_month_outlined),
    ('Custom', RangePreset.custom, Icons.calendar_today),
  ];

  Widget _webBuild(
    AsyncValue<AuditLogFeed> async,
    List<AuditLogEntry> filtered,
    bool canFilterEntity,
  ) {
    final feed = async.valueOrNull;
    final side = _webSidePanel(canFilterEntity);
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _webListHeader(filtered.length, feed?.total ?? 0),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            color: _green,
            onRefresh: _refresh,
            child: _webList(async, filtered),
          ),
        ),
      ],
    );
    return Material(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 760) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _webCompactFilters(canFilterEntity),
                  const SizedBox(height: 14),
                  Expanded(child: main),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 250, child: side),
                const SizedBox(width: 24),
                Expanded(child: main),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _webSidePanel(bool canFilterEntity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3ECE5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canFilterEntity) ...[
              for (final f in _webEntityFilters)
                _webSideItem(
                  label: f.$1,
                  icon: f.$3,
                  selected: _entityFilter == f.$2,
                  onTap: () => setState(() => _entityFilter = f.$2),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Divider(height: 1, color: Colors.grey.shade300),
              ),
            ],
            for (final f in _webDateFilters)
              _webSideItem(
                label: f.$2 == RangePreset.custom &&
                        _dateRange?.preset == RangePreset.custom
                    ? _dateRange!.summary
                    : f.$1,
                icon: f.$3,
                selected: (f.$2 == null && _dateRange == null) ||
                    (f.$2 != null && _dateRange?.preset == f.$2),
                onTap: () => _onDateChipTap(f.$2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _webSideItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF106220), Color(0xFF1A801A)],
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: _green.withValues(alpha: 0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFF2F7F3),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: selected ? Colors.white : _green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _webCompactFilters(bool canFilterEntity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canFilterEntity) ...[
          _buildFilters(),
          const SizedBox(height: 10),
        ],
        _buildDateFilters(),
      ],
    );
  }

  Widget _webListHeader(int count, int total) {
    final rangeLabel = _dateRange == null ? 'All time' : _dateRange!.summary;
    final filtered =
        _dateRange != null || _entityFilter != null || _query.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3F15), Color(0xFF1A801A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'entry' : 'entries'} • $rangeLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (filtered) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() {
                  _dateRange = null;
                  _entityFilter = null;
                  _query = '';
                  _searchController.clear();
                }),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 15, color: _green),
                const SizedBox(width: 6),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _onWebScroll(ScrollNotification n) {
    if (n.depth == 0 &&
        n is ScrollUpdateNotification &&
        (n.scrollDelta ?? 0) > 0 &&
        n.metrics.extentAfter < 300) {
      ref.read(auditLogProvider(_entityFilter).notifier).loadMore();
    }
    return false;
  }

  Widget _webList(AsyncValue<AuditLogFeed> async, List<AuditLogEntry> filtered) {
    final feed = async.valueOrNull;
    if (feed == null) {
      if (async.hasError) {
        return _scrollableCenter(_buildErrorState(async.error!));
      }
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (filtered.isEmpty && !feed.hasMore) {
      return _scrollableCenter(_buildEmptyState());
    }
    final showFooter = feed.hasMore || feed.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: _onWebScroll,
      child: ListView.builder(
        key: const PageStorageKey('audit-log-web'),
        controller: _webScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 32),
        itemCount: filtered.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < filtered.length) {
            return _webTimelineEntry(
              filtered[index],
              isFirst: index == 0,
              isLast: index == filtered.length - 1 && !showFooter,
            );
          }
          if (feed.loadMoreError != null) {
            return Center(
              child: TextButton(
                onPressed: () => ref
                    .read(auditLogProvider(_entityFilter).notifier)
                    .loadMore(),
                child: const Text(
                  'Retry loading more',
                  style: TextStyle(fontFamily: 'Montserrat', color: _green),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _green),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _webTimelineEntry(
    AuditLogEntry e, {
    required bool isFirst,
    required bool isLast,
  }) {
    final color = _actionColor(e.action);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? 22 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 22 : null,
                  child: Container(width: 2, color: const Color(0xFFE1EBE3)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          Color.lerp(color, Colors.black, 0.25)!,
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _actionIcon(e.action),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _WebHoverCard(
                accent: color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _pill('${e.action.label} ${e.entity.label}', color),
                        const Spacer(),
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTime(e.timestamp),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      e.entityName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14201A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (e.details != null && e.details!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        e.details!,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F9F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 15, color: _green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: e.actorName,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  if (e.actorRole.isNotEmpty)
                                    TextSpan(
                                      text: '  •  ${e.actorRole}',
                                      style: TextStyle(
                                        color: Colors.black.withValues(alpha: 0.4),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fullTime(e.timestamp),
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canFilterEntity =
        Permissions.canFilterAuditByEntity(ref.watch(currentUserRoleProvider));
    final async = ref.watch(auditLogProvider(_entityFilter));
    final feed = async.valueOrNull;
    final all = feed?.items ?? const <AuditLogEntry>[];
    final filtered = all.where((e) {
      if (_entityFilter != null && e.entity != _entityFilter) return false;
      if (_dateRange != null && !_dateRange!.contains(e.timestamp)) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.actorName.toLowerCase().contains(q) ||
          e.entityName.toLowerCase().contains(q) ||
          (e.details ?? '').toLowerCase().contains(q) ||
          e.action.label.toLowerCase().contains(q);
    }).toList();

    if (kIsWeb) return _webBuild(async, filtered, canFilterEntity);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.78),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(feed?.total ?? 0),
                  const SizedBox(height: 4),
                  if (!kIsWeb) ...[
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                  ],
                  if (canFilterEntity) ...[
                    _buildFilters(),
                    const SizedBox(height: 10),
                  ],
                  _buildDateFilters(),
                  const SizedBox(height: 8),
                  _buildResultSummary(filtered.length),
                  const SizedBox(height: 6),
                  Expanded(
                    child: RefreshIndicator(
                      color: _green,
                      onRefresh: _refresh,
                      child: _buildList(async, filtered),
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

  Future<void> _refresh() async {
    ref.invalidate(auditLogProvider(_entityFilter));
    try {
      await ref.read(auditLogProvider(_entityFilter).future);
    } catch (_) {
      // Rendered as the error state.
    }
  }

  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }

  Widget _buildList(
    AsyncValue<AuditLogFeed> async,
    List<AuditLogEntry> filtered,
  ) {
    final feed = async.valueOrNull;
    if (feed == null) {
      if (async.hasError) {
        return _scrollableCenter(_buildErrorState(async.error!));
      }
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (filtered.isEmpty && !feed.hasMore) {
      return _scrollableCenter(_buildEmptyState());
    }
    final showFooter = feed.hasMore || feed.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 300) {
          ref.read(auditLogProvider(_entityFilter).notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < filtered.length) return _buildEntryCard(filtered[index]);
          if (feed.loadMoreError != null) {
            return Center(
              child: TextButton(
                onPressed: () => ref
                    .read(auditLogProvider(_entityFilter).notifier)
                    .loadMore(),
                child: const Text(
                  'Retry loading more',
                  style: TextStyle(fontFamily: 'Montserrat', color: _green),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _green),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Couldn't load activity",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _refresh,
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Montserrat', color: _green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          if (!kIsWeb) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child:
                  const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 14),
            const Text(
              'Activity History',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        child: TextField(
          controller: _searchController,
          cursorColor: _green,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search activity',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 24,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <MapEntry<String, AuditEntity?>>[
      const MapEntry('All', null),
      const MapEntry('Users', AuditEntity.user),
      const MapEntry('Tasks', AuditEntity.task),
      const MapEntry('AMCs', AuditEntity.amc),
      const MapEntry('Equipment', AuditEntity.equipment),
      const MapEntry('Issue Types', AuditEntity.issueType),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _entityFilter == f.value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _entityFilter = f.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _green : _green.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f.key,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.6),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilters() {
    // "All time" => null range; the rest map to DateRange presets.
    final chips = <MapEntry<String, RangePreset?>>[
      const MapEntry('All time', null),
      const MapEntry('Today', RangePreset.today),
      const MapEntry('This Week', RangePreset.week),
      const MapEntry('This Month', RangePreset.month),
      const MapEntry('Custom', RangePreset.custom),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = chips[index];
          final preset = c.value;
          final selected = (preset == null && _dateRange == null) ||
              (preset != null && _dateRange?.preset == preset);
          final label = preset == RangePreset.custom && selected
              ? _dateRange!.summary
              : c.key;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onDateChipTap(preset),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _green.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _green : _green.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preset == RangePreset.custom)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: selected ? _green : Colors.black45,
                      ),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? _green : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onDateChipTap(RangePreset? preset) async {
    if (preset == null) {
      setState(() => _dateRange = null);
      return;
    }
    if (preset == RangePreset.custom) {
      final now = DateTime.now();
      final initial = _dateRange ??
          DateRange.custom(now.subtract(const Duration(days: 7)), now);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        initialDateRange: DateTimeRange(start: initial.start, end: initial.end),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _green,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C2B20),
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() => _dateRange = DateRange.custom(picked.start, picked.end));
      }
      return;
    }
    setState(() => _dateRange = DateRange.fromPreset(preset));
  }

  Widget _buildResultSummary(int count) {
    final rangeLabel = _dateRange == null ? 'All time' : _dateRange!.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 14,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'entry' : 'entries'} • $rangeLabel',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          if (_dateRange != null || _entityFilter != null || _query.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _dateRange = null;
                  _entityFilter = null;
                  _query = '';
                  _searchController.clear();
                });
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final ownOnly =
        !Permissions.canFilterAuditByEntity(ref.read(currentUserRoleProvider));
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No activity found',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            if (ownOnly) ...[
              const SizedBox(height: 4),
              Text(
                'Your recent actions will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(AuditLogEntry e) {
    final color = _actionColor(e.action);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action icon tile
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_actionIcon(e.action), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action + entity pills + time
                Row(
                  children: [
                    _pill('${e.action.label} ${e.entity.label}', color),
                    const Spacer(),
                    Text(
                      _relativeTime(e.timestamp),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                // Entity name
                Text(
                  e.entityName,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                if (e.details != null && e.details!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    e.details!,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Actor row
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: e.actorName,
                              style: const TextStyle(color: Colors.black),
                            ),
                            if (e.actorRole.isNotEmpty)
                              TextSpan(
                                text: '  •  ${e.actorRole}',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fullTime(e.timestamp),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _actionColor(AuditAction action) {
    switch (action) {
      case AuditAction.created:
        return const Color(0xFF11682E);
      case AuditAction.updated:
        return const Color(0xFF3B82A6);
      case AuditAction.deleted:
        return const Color(0xFFBF0F0F);
      case AuditAction.assigned:
        return const Color(0xFF775DAC);
      case AuditAction.loggedIn:
        return const Color(0xFF11682E);
      case AuditAction.loggedOut:
        return const Color(0xFF9E663B);
    }
  }

  IconData _actionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.created:
        return Icons.add_circle_outline;
      case AuditAction.updated:
        return Icons.edit_outlined;
      case AuditAction.deleted:
        return Icons.delete_outline;
      case AuditAction.assigned:
        return Icons.assignment_ind_outlined;
      case AuditAction.loggedIn:
        return Icons.login;
      case AuditAction.loggedOut:
        return Icons.logout;
    }
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _fullTime(t);
  }

  String _fullTime(DateTime t) {
    final d = t;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day-$mon-${d.year} $hh:$mm';
  }
}

class _WebHoverCard extends StatefulWidget {
  const _WebHoverCard({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  State<_WebHoverCard> createState() => _WebHoverCardState();
}

class _WebHoverCardState extends State<_WebHoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hover
                ? widget.accent.withValues(alpha: 0.35)
                : const Color(0xFFE3ECE5),
          ),
          boxShadow: [
            BoxShadow(
              color: (_hover ? widget.accent : Colors.black)
                  .withValues(alpha: _hover ? 0.12 : 0.04),
              blurRadius: _hover ? 22 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: widget.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
