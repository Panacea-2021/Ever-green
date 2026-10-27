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
                _header(context),
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
