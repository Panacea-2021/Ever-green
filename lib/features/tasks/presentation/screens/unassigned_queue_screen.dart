import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../widgets/task_workflow.dart';

/// Super Admin / Manager view for triaging tickets (membership:
/// [TaskItem.queueBucket]; completed / closed tickets are in no tab):
/// - "Unassigned": no Service Engineer yet — overdue first — with Assign.
/// - "Awaiting": assigned, still open, never accepted or started, with the
///   acceptance timer, Reassign and Unassign.
/// - "Assigned": accepted / started / in progress / on hold, with Reassign
///   and Unassign.
class UnassignedQueueScreen extends ConsumerStatefulWidget {
  const UnassignedQueueScreen({super.key});

  @override
  ConsumerState<UnassignedQueueScreen> createState() =>
      _UnassignedQueueScreenState();
}

class _UnassignedQueueScreenState extends ConsumerState<UnassignedQueueScreen> {
  static const Color _green = Color(0xFF106220);
  int _tab = 0; // 0 = Unassigned, 1 = Awaiting Acceptance, 2 = Assigned

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskItemsProvider);
    final all = ref.watch(taskProvider);
    // Membership rules: TaskItem.queueBucket.
    final unassigned = ref.watch(unassignedTasksProvider);
    final awaiting = ref.watch(awaitingAcceptanceProvider);
    final assigned = ref.watch(assignedQueueProvider);

    final list = _tab == 0
        ? unassigned
        : _tab == 1
            ? awaiting
            : assigned;
    final overdueUnassigned = unassigned.where((t) => t.isOverdue()).length;
    final overdueAccept = awaiting.where((t) => t.isAcceptanceOverdue()).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/home_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(unassigned.length),
                  const SizedBox(height: 6),
                  if (_tab == 0 && overdueUnassigned > 0)
                    _overdueBanner(
                      '$overdueUnassigned ticket${overdueUnassigned == 1 ? '' : 's'} past SLA with no one assigned',
                    ),
                  if (_tab == 1 && overdueAccept > 0)
                    _overdueBanner(
                      '$overdueAccept ticket${overdueAccept == 1 ? '' : 's'} not accepted within ${TaskItem.acceptanceWindowMinutes} min — reassign',
                    ),
                  _tabs(unassigned.length, awaiting.length, assigned.length),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      color: _green,
                      onRefresh: () async {
                        ref.invalidate(tasksProvider);
                        await ref.read(tasksProvider.future);
                      },
                      child: all.isEmpty && async.isLoading
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child:
                                      CircularProgressIndicator(color: _green),
                                ),
                              ],
                            )
                          : all.isEmpty && async.hasError
                              ? _error(async.error)
                              : list.isEmpty
                                  ? LayoutBuilder(
                                      builder: (_, c) => SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: SizedBox(
                                          height: c.maxHeight,
                                          child: _empty(),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        4,
                                        16,
                                        24,
                                      ),
                                      itemCount: list.length,
                                      itemBuilder: (_, i) => _card(list[i]),
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

  Widget _header(int unassignedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Color(0xFF1C2B20)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Ticket Queue',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B20),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: unassignedCount > 0 ? const Color(0xFFD32F2F) : _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$unassignedCount unassigned',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overdueBanner(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD32F2F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs(int unassigned, int awaiting, int assigned) {
    Widget tab(String label, int index) {
      final sel = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: sel ? _green : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? _green : _green.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          tab('Unassigned ($unassigned)', 0),
          const SizedBox(width: 7),
          tab('Awaiting ($awaiting)', 1),
          const SizedBox(width: 7),
          tab('Assigned ($assigned)', 2),
        ],
      ),
    );
  }

  Widget _card(TaskItem t) {
    final overdue = t.isOverdue();
    final waiting = DateTime.now().difference(t.createdAt);
    final waitedText = waiting.inHours < 24
        ? '${waiting.inHours}h waiting'
        : '${waiting.inDays}d waiting';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue ? const Color(0xFFD32F2F) : Colors.grey.shade200,
          width: overdue ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2B20),
                  ),
                ),
              ),
              _priorityPill(t.priority),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (t.isIndividual) ...[t.contactName, t.address]
              else ...[t.equipment, t.companyName],
            ].where((s) => s.isNotEmpty).join('  •  '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag('Ticket #${t.ticketNo}', const Color(0xFFEBF0EA), _green),
              if (t.isIndividual)
                _tag('Individual', const Color(0xFFEBF0EA), _green),
              if (t.clientName.isNotEmpty)
                _tag(
                  'Raised by ${t.clientName}',
                  const Color(0xFFEAF2FF),
                  const Color(0xFF1565C0),
                ),
              if (_tab != 0 && t.assignee != '-')
                _tag(
                  '@${t.assignee}',
                  const Color(0xFFF3EAFE),
                  const Color(0xFF6A1B9A),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // For the "Awaiting" tab show the acceptance timer; otherwise the
          // SLA / waiting indicator.
          if (_tab == 1)
            _acceptanceRow(t)
          else
            Row(
              children: [
                Icon(
                  overdue ? Icons.warning_amber_rounded : Icons.schedule,
                  size: 15,
                  color: overdue
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF6B6B6B),
                ),
                const SizedBox(width: 6),
                Text(
                  overdue ? 'Overdue • $waitedText' : waitedText,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overdue
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_tab == 0)
            _primaryButton('Assign to Service Engineer', () => _assignSheet(t))
          else
            Row(
              children: [
                Expanded(
                  child: _primaryButton('Reassign', () => _assignSheet(t)),
                ),
                const SizedBox(width: 10),
                _outlineButton('Unassign', () => _unassign(t)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _acceptanceRow(TaskItem t) {
    final mins = t.pendingAcceptanceMinutes();
    final overdue = t.isAcceptanceOverdue();
    final color = overdue ? const Color(0xFFD32F2F) : const Color(0xFFE08600);
    final text = overdue
        ? 'Not accepted for ${mins}m • past ${TaskItem.acceptanceWindowMinutes}m window'
        : 'Awaiting acceptance • ${mins}m of ${TaskItem.acceptanceWindowMinutes}m';
    return Row(
      children: [
        Icon(
          overdue ? Icons.timer_off_outlined : Icons.hourglass_bottom,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD32F2F)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD32F2F),
          ),
        ),
      ),
    );
  }

  // ---- Actions ----

  void _assignSheet(TaskItem t) {
    final isReassign = !t.isUnassigned;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isReassign ? 'Reassign "${t.title}"' : 'Assign "${t.title}"',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isReassign)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Currently with ${t.assignee}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TechnicianChoices(
            builder: (techs, stats) => Column(
              children: [
          for (final tech in techs)
            Builder(
              builder: (_) {
                final s = statsFor(tech, stats);
                final isCurrent = tech.backendId == t.technicianId;
                final overloaded = s.isOverloaded;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !isCurrent,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEBF0EA),
                    child: Text(
                      tech.name.isNotEmpty ? tech.name[0] : '?',
                      style: const TextStyle(color: _green),
                    ),
                  ),
                  title: Text(
                    tech.name,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                  ),
                  subtitle: Text(
                    isCurrent
                        ? 'Current assignee'
                        : '${s.active} active task(s)',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: overloaded
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF6B6B6B),
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: _green)
                      : overloaded
                          ? const Text(
                              'Busy',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Color(0xFFD32F2F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                  onTap: isCurrent
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          if (overloaded) {
                            final ok =
                                await _confirmOverload(tech.name, s.active);
                            if (ok != true || !mounted) return;
                          }
                          _doAssign(t, tech, isReassign);
                        },
                );
              },
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _doAssign(TaskItem t, User tech, bool isReassign) {
    runTaskAction(
      context,
      () => ref.read(taskActionsProvider).assign(t, tech.backendId),
      success: isReassign
          ? 'Reassigned to ${tech.name}'
          : 'Assigned to ${tech.name}',
    );
  }

  void _unassign(TaskItem t) {
    runTaskAction(
      context,
      () => ref.read(taskActionsProvider).unassign(t),
      success: '${t.title} returned to the unassigned queue',
    );
  }

  Widget _error(Object? error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 120),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Color(0xFF6B6B6B),
          ),
        ),
        TextButton(
          onPressed: () => ref.invalidate(tasksProvider),
          child: const Text('Retry', style: TextStyle(color: _green)),
        ),
      ],
    );
  }

  Future<bool?> _confirmOverload(String name, int active) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Service Engineer is busy',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        content: Text(
          '$name already has $active active tasks. Assign anyway?',
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text(
              'Assign anyway',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
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

  Widget _priorityPill(TaskPriority p) {
    final c = switch (p) {
      TaskPriority.critical => const Color(0xFFD32F2F),
      TaskPriority.high => const Color(0xFFE08600),
      TaskPriority.medium => const Color(0xFF1565C0),
      TaskPriority.low => const Color(0xFF6B6B6B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.label,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _tab == 0
                ? Icons.inbox_outlined
                : Icons.assignment_turned_in_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            switch (_tab) {
              0 => 'No unassigned tickets',
              1 => 'Nothing awaiting acceptance',
              _ => 'No assigned tickets',
            },
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            switch (_tab) {
              0 => 'Every raised ticket has an owner.',
              1 => 'Every assigned ticket has been accepted.',
              _ => 'No Service Engineer is working a ticket right now.',
            },
            style: const TextStyle(
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
