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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  _buildSearchBar(),
                  const SizedBox(height: 12),
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
            Icon(Icons.cloud_off_outlined,
                size: 72, color: Colors.grey.shade300),
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
