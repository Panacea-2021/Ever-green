import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../tasks/data/task_provider.dart';
import '../../data/performance_provider.dart';

/// Super Admin / Manager performance report for both technicians and
/// managers, filterable by Today / This Week / This Month / Custom range.
class TechnicianPerformanceScreen extends ConsumerStatefulWidget {
  const TechnicianPerformanceScreen({super.key});

  @override
  ConsumerState<TechnicianPerformanceScreen> createState() =>
      _TechnicianPerformanceScreenState();
}

class _TechnicianPerformanceScreenState
    extends ConsumerState<TechnicianPerformanceScreen> {
  static const Color _green = Color(0xFF106220);
  int _tab = 0; // 0 = Technicians, 1 = Managers

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(performanceRangeProvider);
    final async = ref.watch(taskItemsProvider);
    final stats = _tab == 0
        ? ref.watch(technicianPerformanceProvider)
        : ref.watch(managerPerformanceProvider);

    if (kIsWeb) return _webBuild(range, async, stats);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          // Faint background, matching the Users page.
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
            child: Column(
              children: [
                if (!kIsWeb) _header(context),
                _roleTabs(),
                _rangeBar(range),
                const SizedBox(height: 4),
                Expanded(
                  child: !async.hasValue && async.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _green),
                        )
                      : !async.hasValue && async.hasError
                          ? _error(async.error)
                          : RefreshIndicator(
                              color: _green,
                              onRefresh: () async {
                                ref.invalidate(tasksProvider);
                                await ref.read(tasksProvider.future);
                              },
                              child: stats.isEmpty
                                  ? LayoutBuilder(
                                      builder: (_, c) => SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: SizedBox(
                                          height: c.maxHeight,
                                          child: _empty(range),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        24,
                                      ),
                                      itemCount: stats.length,
                                      itemBuilder: (_, i) => _card(stats[i]),
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

  static const Color _webLine = Color(0xFFE2E8E3);
  static const Color _webInk = Color(0xFF14201A);

  Widget _webBuild(
    DateRange range,
    AsyncValue<Object?> async,
    List<PerformanceStats> stats,
  ) {
    Widget body;
    if (!async.hasValue && async.isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _green));
    } else if (!async.hasValue && async.hasError) {
      body = _error(async.error);
    } else {
      body = RefreshIndicator(
        color: _green,
        onRefresh: () async {
          ref.invalidate(tasksProvider);
          await ref.read(tasksProvider.future);
        },
        child: LayoutBuilder(
          builder: (_, c) {
            if (stats.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: c.maxHeight, child: _empty(range)),
              );
            }
            const gap = 18.0;
            final inner = c.maxWidth - 48;
            final cols = inner >= 1300
                ? 3
                : inner >= 760
                    ? 2
                    : 1;
            final w = (inner - gap * (cols - 1)) / cols;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final s in stats)
                      SizedBox(width: w, child: _webCard(s)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              color: const Color(0xFFF5F8F4).withValues(alpha: 0.9),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFF5F8F4)),
            ),
          ),
          Column(
            children: [
              _webToolbar(range),
              Expanded(child: body),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webToolbar(DateRange range) {
    Widget roleTab(String label, IconData icon, int index) {
      final sel = _tab == index;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: sel ? Colors.white : const Color(0xFF4B5A50),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : const Color(0xFF4B5A50),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _webLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  roleTab('Service Engineers', Icons.engineering_outlined, 0),
                  const SizedBox(width: 4),
                  roleTab('Managers', Icons.manage_accounts_outlined, 1),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in RangePreset.values) _webRangeChip(p, range),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _webRangeChip(RangePreset p, DateRange range) {
    final selected = range.preset == p;
    final label = p == RangePreset.custom && selected ? range.summary : p.label;
    final fg = selected ? _green : const Color(0xFF4B5A50);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectRange(p, range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? _green.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _green : _webLine,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p == RangePreset.custom
                    ? Icons.calendar_month_outlined
                    : Icons.schedule_outlined,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectRange(RangePreset p, DateRange range) async {
    if (p == RangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        initialDateRange: DateTimeRange(start: range.start, end: range.end),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _green,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        ref.read(performanceRangeProvider.notifier).state =
            DateRange.custom(picked.start, picked.end);
      }
    } else {
      ref.read(performanceRangeProvider.notifier).state =
          DateRange.fromPreset(p);
    }
  }

  Widget _webCard(PerformanceStats s) {
    final slaColor = s.slaCompliance >= 80
        ? _green
        : s.slaCompliance >= 50
            ? const Color(0xFFE08600)
            : const Color(0xFFD32F2F);
    return _WebHoverLift(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: s.isOverloaded ? const Color(0xFFE08600) : _webLine,
            width: s.isOverloaded ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 46,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E8A3A), _green],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0] : '?',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _webInk,
                      ),
                    ),
                  ),
                  if (s.overdue > 0)
                    _webBadge(
                      '${s.overdue} overdue',
                      Icons.error_outline,
                      const Color(0xFFD32F2F),
                    )
                  else if (s.isOverloaded)
                    _webBadge(
                      'Overloaded',
                      Icons.warning_amber_rounded,
                      const Color(0xFFE08600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _webLine),
            const SizedBox(height: 16),
            Row(
              children: [
                _webMetric(
                  'Created',
                  '${s.created}',
                  Icons.add_task_outlined,
                  const Color(0xFF1565C0),
                ),
                const SizedBox(width: 10),
                _webMetric(
                  'Completed',
                  '${s.completed}',
                  Icons.check_circle_outline,
                  _green,
                ),
                const SizedBox(width: 10),
                _webMetric(
                  'Active',
                  '${s.active}',
                  Icons.pending_actions_outlined,
                  const Color(0xFF6A1B9A),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _webMetric(
                  'Avg Resolve',
                  s.avgResolutionHours == 0
                      ? '-'
                      : '${s.avgResolutionHours.toStringAsFixed(0)}h',
                  Icons.timer_outlined,
                  const Color(0xFF00897B),
                ),
                const SizedBox(width: 10),
                _webMetric(
                  'SLA Met',
                  s.completed == 0
                      ? '-'
                      : '${s.slaCompliance.toStringAsFixed(0)}%',
                  Icons.verified_outlined,
                  slaColor,
                ),
                const SizedBox(width: 10),
                _webMetric(
                  'Rating',
                  s.avgRating == 0 ? '-' : s.avgRating.toStringAsFixed(1),
                  Icons.star_outline_rounded,
                  const Color(0xFFFFB300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _webBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _webMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6B6B),
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

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Performance',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTabs() {
    Widget tab(String label, int index) {
      final sel = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? _green : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: sel ? _green : const Color(0xFFE3E3E3),
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          tab('Service Engineers', 0),
          const SizedBox(width: 10),
          tab('Managers', 1),
        ],
      ),
    );
  }

  Widget _rangeBar(DateRange range) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final p in RangePreset.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _rangeChip(p, range),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(RangePreset p, DateRange range) {
    final selected = range.preset == p;
    final label = p == RangePreset.custom && selected ? range.summary : p.label;
    return GestureDetector(
      onTap: () async {
        if (p == RangePreset.custom) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            initialDateRange: DateTimeRange(start: range.start, end: range.end),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: _green,
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF1F1F1F),
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            ref.read(performanceRangeProvider.notifier).state =
                DateRange.custom(picked.start, picked.end);
          }
        } else {
          ref.read(performanceRangeProvider.notifier).state =
              DateRange.fromPreset(p);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE3E3E3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.26),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p == RangePreset.custom)
              Icon(
                Icons.calendar_today,
                size: 13,
                color: selected ? Colors.white : const Color(0xFF545454),
              ),
            if (p == RangePreset.custom) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(PerformanceStats s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: s.isOverloaded
            ? Border.all(color: const Color(0xFFE08600), width: 1.3)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0D9EE),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEBF0EA),
                child: Text(
                  s.name.isNotEmpty ? s.name[0] : '?',
                  style: const TextStyle(
                    color: _green,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              if (s.overdue > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.overdue} overdue',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                )
              else if (s.isOverloaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Overloaded',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE08600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Created', '${s.created}', const Color(0xFF1565C0)),
              _metric('Completed', '${s.completed}', _green),
              _metric('Active', '${s.active}', const Color(0xFF6A1B9A)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                'Avg Resolve',
                s.avgResolutionHours == 0
                    ? '-'
                    : '${s.avgResolutionHours.toStringAsFixed(0)}h',
                const Color(0xFF00897B),
              ),
              _metric(
                'SLA Met',
                s.completed == 0
                    ? '-'
                    : '${s.slaCompliance.toStringAsFixed(0)}%',
                s.slaCompliance >= 80
                    ? _green
                    : s.slaCompliance >= 50
                        ? const Color(0xFFE08600)
                        : const Color(0xFFD32F2F),
              ),
              _metric(
                'Rating',
                s.avgRating == 0 ? '-' : s.avgRating.toStringAsFixed(1),
                const Color(0xFFFFB300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Color(0xFF6B6B6B),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(tasksProvider),
              child: const Text('Retry', style: TextStyle(color: _green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(DateRange range) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No activity for ${range.summary.toLowerCase()}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a wider date range.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Color(0xFF9B9B9B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lifts its child slightly while hovered (web cards).
class _WebHoverLift extends StatefulWidget {
  const _WebHoverLift({required this.child});
  final Widget child;

  @override
  State<_WebHoverLift> createState() => _WebHoverLiftState();
}

class _WebHoverLiftState extends State<_WebHoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
