import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../web/widgets/web_header_actions.dart';
import '../../../technicians/data/performance_provider.dart';
import '../../data/audit_log_provider.dart';
import '../../domain/models/audit_log_entry.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen>
    with WebHeaderActionsMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // null = All; otherwise filter by this entity.
  AuditEntity? _entityFilter;

  // null = All time; otherwise only entries whose timestamp is in this range.
  DateRange? _dateRange;

  static const Color _green = Color(0xFF106220);
  static const Color _cream = Color(0xFFFBFCFA);
  static const Color _line = Color(0xFFE3ECE5);

  final ScrollController _webScroll = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _webScroll.dispose();
    super.dispose();
  }

  static const _entityFilters = <(String, AuditEntity?, IconData)>[
    ('All', null, Icons.grid_view_rounded),
    ('Users', AuditEntity.user, Icons.people_outline_rounded),
    ('Tasks', AuditEntity.task, Icons.task_alt_rounded),
    ('AMCs', AuditEntity.amc, Icons.handshake_outlined),
    ('Equipment', AuditEntity.equipment, Icons.precision_manufacturing_outlined),
  ];

  static const _dateFilters = <(String, RangePreset?, IconData)>[
    ('All time', null, Icons.all_inclusive_rounded),
    ('Today', RangePreset.today, Icons.today_rounded),
    ('This week', RangePreset.week, Icons.date_range_rounded),
    ('Month', RangePreset.month, Icons.calendar_month_rounded),
    ('Custom', RangePreset.custom, Icons.edit_calendar_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    // Clear header actions on web - this screen has no header buttons
    if (kIsWeb) {
      setHeaderActions([]);
    }

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

    if (kIsWeb) return _webBuild(async, filtered, canFilterEntity, feed?.total ?? 0);

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

  // ════════════════════════════════════════════════════════════════════════════
  // WEB BUILD
  // ════════════════════════════════════════════════════════════════════════════

  Widget _webBuild(
    AsyncValue<AuditLogFeed> async,
    List<AuditLogEntry> filtered,
    bool canFilterEntity,
    int total,
  ) {
    return Scaffold(
      backgroundColor: _cream,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Unified Filter Bar ─────────────────────────────────────────
            _webFilterBar(canFilterEntity, total),
            const SizedBox(height: 20),
            // ── Search Bar ─────────────────────────────────────────────────
            _webSearchBar(),
            const SizedBox(height: 20),
            // ── Activity List ──────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _green,
                onRefresh: _refresh,
                child: _webList(async, filtered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webScrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }

  Widget _webFilterBar(bool canFilterEntity, int total) {
    final hasFilters =
        _entityFilter != null || _dateRange != null || _query.isNotEmpty;
    final typeSection = _buildFilterSection(
      'Type',
      _entityFilters.map(
        (f) => _WebChip(
          label: f.$1,
          icon: f.$3,
          selected: _entityFilter == f.$2,
          onTap: () => setState(() => _entityFilter = f.$2),
        ),
      )
          .toList(),
    );
    final timeSection = _buildFilterSection(
      'Time',
      _dateFilters.map(
        (f) => _WebChip(
          label: f.$2 == RangePreset.custom &&
                  _dateRange?.preset == RangePreset.custom
              ? _dateRange!.summary
              : f.$1,
          icon: f.$3,
          selected: (f.$2 == null && _dateRange == null) ||
              (f.$2 != null && _dateRange?.preset == f.$2),
          onTap: () => _onDateChipTap(f.$2),
        ),
      )
          .toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final primarySection = canFilterEntity ? typeSection : timeSection;
        final secondarySection = canFilterEntity ? timeSection : null;
        final statsBadge = _webStatsBadge(total, hasFilters);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                primarySection,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: statsBadge,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: primarySection),
                    const SizedBox(width: 16),
                    statsBadge,
                  ],
                ),
              if (secondarySection != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _line),
                ),
                secondarySection,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String label, List<Widget> chips) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.35),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: chips,
          ),
        ),
      ],
    );
  }

  Widget _webStatsBadge(int total, bool hasFilters) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFilters) ...[
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() {
                _dateRange = null;
                _entityFilter = null;
                _query = '';
                _searchController.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_off_rounded, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A3F15), Color(0xFF1A801A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '$total entries',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _webSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: _green,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search by name, action, or details...',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.35),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
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
        return _webScrollableCenter(_buildErrorState(async.error!));
      }
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (filtered.isEmpty && !feed.hasMore) {
      return _webScrollableCenter(_buildEmptyState());
    }
    final showFooter = feed.hasMore || feed.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: _onWebScroll,
      child: ListView.builder(
        key: const PageStorageKey('audit-log-web'),
        controller: _webScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        itemCount: filtered.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < filtered.length) {
            return _webActivityCard(filtered[index]);
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

  Widget _webActivityCard(AuditLogEntry e) {
    final color = _actionColor(e.action);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _WebActivityHoverCard(
        accent: color,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    Color.lerp(color, Colors.black, 0.2)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _actionIcon(e.action),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action badge and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${e.action.label} ${e.entity.label}',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _relativeTime(e.timestamp),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Entity name
                  Text(
                    e.entityName,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14201A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (e.displayDetails.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.displayDetails,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Actor row
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, size: 16, color: _green),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: e.actorName,
                                  style: const TextStyle(color: Color(0xFF14201A)),
                                ),
                                if (e.actorRole.isNotEmpty)
                                  TextSpan(
                                    text: '  •  ${e.actorRole}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fullTime(e.timestamp),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOBILE BUILD HELPERS
  // ════════════════════════════════════════════════════════════════════════════

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
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
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
                  color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.6),
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
                if (e.displayDetails.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    e.displayDetails,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
        return Icons.add_circle_outline_rounded;
      case AuditAction.updated:
        return Icons.edit_outlined;
      case AuditAction.deleted:
        return Icons.delete_outline_rounded;
      case AuditAction.assigned:
        return Icons.assignment_ind_outlined;
      case AuditAction.loggedIn:
        return Icons.login_rounded;
      case AuditAction.loggedOut:
        return Icons.logout_rounded;
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

// ══════════════════════════════════════════════════════════════════════════════
// WEB COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

/// Modern chip for web filters
class _WebChip extends StatefulWidget {
  const _WebChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_WebChip> createState() => _WebChipState();
}

class _WebChipState extends State<_WebChip> {
  bool _hover = false;

  static const _green = Color(0xFF106220);

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0xFF138A2A), Color(0xFF106220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel
                ? null
                : _hover
                    ? const Color(0xFFEAF3EB)
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? _green : const Color(0xFFD4E3D6),
              width: sel ? 0 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: sel ? Colors.white : _green,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF14201A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hover card for activity entries
class _WebActivityHoverCard extends StatefulWidget {
  const _WebActivityHoverCard({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  State<_WebActivityHoverCard> createState() => _WebActivityHoverCardState();
}

class _WebActivityHoverCardState extends State<_WebActivityHoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover
                ? widget.accent.withValues(alpha: 0.3)
                : const Color(0xFFE3ECE5),
          ),
          boxShadow: [
            BoxShadow(
              color: (_hover ? widget.accent : Colors.black)
                  .withValues(alpha: _hover ? 0.12 : 0.04),
              blurRadius: _hover ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
