import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../data/pm_provider.dart';
import '../../domain/models/pm_schedule.dart';
import '../../domain/pm_occurrences.dart';

/// Upcoming preventive maintenance for all equipment (from each equipment's
/// PM frequency and the PM schedules), plus schedule management: recurring
/// schedules, generating due visits, and reviewing generated visits.
class PmScheduleScreen extends ConsumerStatefulWidget {
  const PmScheduleScreen({super.key});

  @override
  ConsumerState<PmScheduleScreen> createState() => _PmScheduleScreenState();
}

class _PmScheduleScreenState extends ConsumerState<PmScheduleScreen> {
  static const Color _green = Color(0xFF106220);
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Index into [PmWindow.values]; the last index is the Schedules view.
  int _view = PmWindow.week.index;
  DateTimeRange? _range;
  int _tab = 0; // Schedules view: 0 = Schedules, 1 = Generated visits
  bool _generating = false;
  final Set<String> _busy = {};

  bool get _schedulesView => _view == PmWindow.values.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _schedulesView && _tab == 0
          ? FloatingActionButton.extended(
              backgroundColor: _green,
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Schedule',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            _viewTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _schedulesView ? _schedulesSection() : _upcomingSection(),
            ),
          ],
        ),
      ),
    );
  }

  /// Underline tabs (same style as the task board status tabs).
  Widget _viewTabs() {
    final labels = [for (final w in PmWindow.values) w.label, 'Schedules'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (_, i) {
          final sel = _view == i && (_range == null || i == labels.length - 1);
          return GestureDetector(
            onTap: () => setState(() {
              _view = i;
              if (i < PmWindow.values.length) _range = null;
            }),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? _green : const Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: sel ? 24 : 0,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _schedulesSection() {
    final async = ref.watch(pmProvider);
    final pm = async.valueOrNull ?? const PmState();
    return Column(
      children: [
        _generateBar(pm.schedules),
        _tabs(pm.schedules.length, pm.generated.length),
        const SizedBox(height: 4),
        Expanded(
          child: async.hasValue
              ? RefreshIndicator(
                  color: _green,
                  onRefresh: () => ref.refresh(pmProvider.future),
                  child: _tab == 0
                      ? _schedulesList(pm.schedules)
                      : _generatedList(pm.generated),
                )
              : async.hasError
                  ? _empty(
                      'Could not load schedules',
                      '${async.error}',
                      onRetry: () => ref.invalidate(pmProvider),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
        ),
      ],
    );
  }

  Widget _upcomingSection() {
    final async = ref.watch(pmDueSourcesProvider);
    final now = DateTime.now();
    final window = PmWindow.values[_view];
    final range = _range;
    final (from, to) =
        range == null ? window.range(now) : (range.start, range.end);
    final sources = async.valueOrNull;
    final items = sources == null
        ? const <PmDue>[]
        : computePmDue(
            equipments: sources.equipments,
            schedules: sources.schedules,
            lastVisits: sources.lastVisits,
            from: from,
            to: to,
            today: now,
            includeOverdue: range == null && window.includesOverdue,
          );
    return Column(
      children: [
        _rangeRow(items.length, sources != null),
        const SizedBox(height: 8),
        Expanded(
          child: sources != null
              ? RefreshIndicator(
                  color: _green,
                  onRefresh: _refreshUpcoming,
                  child: _upcomingList(items, now),
                )
              : async.hasError
                  ? _empty(
                      'Could not load equipment',
                      '${async.error}',
                      onRetry: () => ref.invalidate(equipmentsProvider(null)),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
        ),
      ],
    );
  }

  Future<void> _refreshUpcoming() {
    ref.invalidate(equipmentsProvider(null));
    ref.invalidate(tasksProvider);
    ref.invalidate(pmProvider);
    return ref.read(pmDueSourcesProvider.future);
  }

  /// Date-range chip (same outlined chip style as the audit log filters).
  Widget _rangeRow(int count, bool loaded) {
    final range = _range;
    final selected = range != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickRange,
            child: Container(
              height: 34,
              padding: EdgeInsets.only(left: 14, right: selected ? 6 : 14),
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
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: selected ? _green : Colors.black45,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    selected
                        ? '${_short(range.start)} – ${_short(range.end)}'
                        : 'Pick dates',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? _green : Colors.black54,
                    ),
                  ),
                  if (selected)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _range = null),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 14, color: _green),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (loaded)
            Text(
              '$count due',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 3, today.month, today.day),
      initialDateRange: _range ??
          DateTimeRange(
            start: today,
            end: DateTime(today.year, today.month, today.day + 30),
          ),
      helpText: 'Maintenance due between',
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
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Widget _upcomingList(List<PmDue> items, DateTime now) {
    if (items.isEmpty) {
      return _scrollable(
        _empty(
          'No maintenance due',
          _range == null
              ? 'Nothing is scheduled in this period.'
              : 'Nothing is scheduled between these dates.',
        ),
      );
    }
    final rows = <Object>[];
    String? lastHeader;
    for (final item in items) {
      final header = item.overdue ? 'Overdue' : _dayHeader(item.dueDate, now);
      if (header != lastHeader) {
        rows.add(header);
        lastHeader = header;
      }
      rows.add(item);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
            child: Text(
              row,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: row == 'Overdue'
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF545454),
              ),
            ),
          );
        }
        return _dueCard(row as PmDue, now);
      },
    );
  }

  Widget _dueCard(PmDue d, DateTime now) {
    final today = d.isToday(now);
    final (String dueText, Color dueBg, Color dueFg) = d.overdue
        ? (
            'Overdue · ${_fmt(d.dueDate)}',
            const Color(0xFFFDE8E8),
            const Color(0xFFD32F2F)
          )
        : today
            ? ('Due today', const Color(0xFFFFF3E0), const Color(0xFFE08600))
            : ('Due ${_fmt(d.dueDate)}', const Color(0xFFEBF0EA), _green);
    final subtitle = [d.companyName, d.location]
        .where((v) => v.trim().isNotEmpty)
        .join(' · ');
    return GestureDetector(
      onTap: d.equipmentId == null ? null : () => _openEquipment(d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: d.overdue || today
              ? Border.all(color: dueFg.withValues(alpha: 0.35))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: d.overdue || today ? dueBg : const Color(0xFFEBF0EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.build_outlined,
                color: d.overdue || today ? dueFg : _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.equipmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _pill(
                        d.frequencyLabel,
                        const Color(0xFFEAF2FF),
                        const Color(0xFF1565C0),
                      ),
                      _pill(dueText, dueBg, dueFg),
                    ],
                  ),
                ],
              ),
            ),
            if (d.equipmentId != null)
              const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }

  void _openEquipment(PmDue d) {
    final e = d.equipment;
    context.push(
      '${Routes.equipmentDetails}/${d.equipmentId}',
      extra: {
        'equipmentName': d.equipmentName,
        'location': e?.location,
        'imageUrl': e?.imageUrl,
        'make': e?.make,
        'model': e?.model,
        'serialNumber': e?.serialNumber,
        'companyId': (e?.companyId ?? e?.company?.id)?.toString(),
        'companyName': d.companyName.isEmpty ? null : d.companyName,
      },
    );
  }

  String _dayHeader(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Today';
    if (d == DateTime(today.year, today.month, today.day + 1)) {
      return 'Tomorrow';
    }
    return '${_weekdays[d.weekday - 1]}, ${_short(d)}';
  }

  String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}'
      '${d.year == DateTime.now().year ? '' : ' ${d.year}'}';

  Widget _header() {
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
              'PM Schedule',
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

  Widget _generateBar(List<PmSchedule> schedules) {
    final dueCount = schedules.where((s) => s.isDue()).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF0EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.autorenew, color: _green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dueCount == 0
                    ? 'No visits due right now'
                    : '$dueCount schedule${dueCount == 1 ? '' : 's'} due for a visit',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF125420),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: dueCount == 0 || _generating ? null : _generateNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(
                'Generate',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs(int schedules, int generated) {
    Widget tab(String label, int index) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _green : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF545454),
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
          tab('Schedules ($schedules)', 0),
          const SizedBox(width: 10),
          tab('Visits ($generated)', 1),
        ],
      ),
    );
  }

  Widget _schedulesList(List<PmSchedule> schedules) {
    if (schedules.isEmpty) {
      return _scrollable(
        _empty('No schedules yet', 'Add one with the button below.'),
      );
    }
    final sorted = [...schedules]
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _scheduleCard(sorted[i]),
    );
  }

  Widget _scheduleCard(PmSchedule s) {
    final due = s.isDue();
    return GestureDetector(
      onLongPress: _busy.contains(s.id) ? null : () => _confirmDelete(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF0EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.build_outlined, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.equipmentName,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  Text(
                    s.companyName,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(
                        s.frequency.label,
                        const Color(0xFFEAF2FF),
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 6),
                      _pill(
                        due ? 'Due now' : 'Next ${_fmt(s.nextDue)}',
                        due ? const Color(0xFFFDE8E8) : const Color(0xFFEBF0EA),
                        due ? const Color(0xFFD32F2F) : _green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: s.active,
              activeThumbColor: _green,
              onChanged: _busy.contains(s.id) ? null : (_) => _toggleActive(s),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(PmSchedule s) async {
    final id = int.tryParse(s.id);
    if (id == null) return;
    setState(() => _busy.add(s.id));
    try {
      await ref.read(pmApiProvider).update(id, isActive: !s.active);
      ref.invalidate(pmProvider);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  Future<void> _confirmDelete(PmSchedule s) async {
    final id = int.tryParse(s.id);
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete schedule?',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        content: Text(
          '${s.equipmentName} — ${s.companyName}',
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(s.id));
    try {
      await ref.read(pmApiProvider).delete(id);
      ref.invalidate(pmProvider);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade400 : _green,
      ),
    );
  }

  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }

  Widget _generatedList(List<PmGeneratedTask> tasks) {
    if (tasks.isEmpty) {
      return _scrollable(
        _empty(
          'No visits generated yet',
          'Tap Generate when schedules are due.',
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final t = tasks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF0EA),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.event_available, color: _green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.equipmentName} — ${t.companyName}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    Text(
                      'Due ${_fmt(t.dueDate)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _empty(String title, String subtitle, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
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
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Montserrat', color: _green),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateNow() async {
    setState(() => _generating = true);
    try {
      final count = (await ref.read(pmApiProvider).generate()).length;
      ref.invalidate(pmProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Nothing due to generate'
                : 'Generated $count maintenance visit${count == 1 ? '' : 's'}',
          ),
          backgroundColor: _green,
        ),
      );
      if (count > 0) setState(() => _tab = 1);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _openAddSheet() {
    final equipController = TextEditingController();
    final companyController = TextEditingController();
    Equipment? equipment;
    Company? company;
    var saving = false;
    PmFrequency frequency = PmFrequency.quarterly;
    DateTime nextDue = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New PM Schedule',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sheetField(
                    'Equipment name',
                    equipController,
                    onTap: () async {
                      final picked = await _pickEquipment(ctx, company);
                      if (picked == null) return;
                      setSheet(() {
                        equipment = picked;
                        equipController.text = picked.name;
                        final c = picked.company;
                        if (c != null) {
                          company = c;
                          companyController.text = c.displayName;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    'Company name',
                    companyController,
                    onTap: () async {
                      final picked = await _pickCompany(ctx);
                      if (picked == null) return;
                      setSheet(() {
                        if (company?.id != picked.id) {
                          equipment = null;
                          equipController.clear();
                        }
                        company = picked;
                        companyController.text = picked.displayName;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Frequency',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in PmFrequency.values)
                        ChoiceChip(
                          label: Text(f.label),
                          selected: frequency == f,
                          selectedColor: _green,
                          labelStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: frequency == f
                                ? Colors.white
                                : const Color(0xFF545454),
                          ),
                          onSelected: (_) => setSheet(() => frequency = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'First visit: ',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _fmt(nextDue),
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: nextDue,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setSheet(() => nextDue = picked);
                          }
                        },
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: _green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = equipment;
                              if (selected == null || company == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Equipment and company are required',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setSheet(() => saving = true);
                              try {
                                await ref.read(pmApiProvider).create(
                                      equipmentId: selected.id,
                                      frequency: frequency,
                                      nextDue: nextDue,
                                    );
                                ref.invalidate(pmProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheet(() => saving = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('$e'),
                                      backgroundColor: Colors.red.shade400,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Schedule',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Equipment?> _pickEquipment(BuildContext ctx, Company? company) async {
    final List<Equipment> all;
    try {
      all = await ref.read(pmEquipmentOptionsProvider.future);
    } catch (e) {
      _snack('$e', error: true);
      return null;
    }
    final items = company == null
        ? all
        : all
            .where((e) => (e.companyId ?? e.company?.id) == company.id)
            .toList();
    if (!ctx.mounted) return null;
    return _pickFrom<Equipment>(
      ctx,
      'Equipment name',
      items,
      (e) => e.name,
      (e) => [
        e.egSerialNumber,
        if (company == null) e.company?.displayName ?? '',
      ].where((v) => v.isNotEmpty).join(' · '),
    );
  }

  Future<Company?> _pickCompany(BuildContext ctx) async {
    final List<Company> companies;
    try {
      companies = await ref.read(companiesProvider.future);
    } catch (e) {
      _snack('$e', error: true);
      return null;
    }
    if (!ctx.mounted) return null;
    return _pickFrom<Company>(
      ctx,
      'Company name',
      companies,
      (c) => c.displayName,
      (c) => c.location ?? '',
    );
  }

  Future<T?> _pickFrom<T>(
    BuildContext ctx,
    String title,
    List<T> items,
    String Function(T) label,
    String Function(T) subtitle,
  ) {
    return showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        var query = '';
        return StatefulBuilder(
          builder: (sheet, setList) {
            final q = query.toLowerCase();
            final filtered = q.isEmpty
                ? items
                : items
                    .where(
                      (i) =>
                          label(i).toLowerCase().contains(q) ||
                          subtitle(i).toLowerCase().contains(q),
                    )
                    .toList();
            return SizedBox(
              height: MediaQuery.of(sheet).size.height * 0.7,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(sheet).viewInsets.bottom + 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setList(() => query = v.trim()),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? _empty('Nothing found', 'Try a different search.')
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final sub = subtitle(item);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    label(item),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: sub.isEmpty
                                      ? null
                                      : Text(
                                          sub,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 12,
                                            color: Color(0xFF6B6B6B),
                                          ),
                                        ),
                                  onTap: () => Navigator.pop(sheet, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(
    String hint,
    TextEditingController controller, {
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
