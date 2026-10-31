import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/backend_models.dart' show HoldType;
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/service_report_service.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import 'task_workflow.dart';

const Color _green = Color(0xFF106220);

/// Runs the role-based task actions (sheets, dialogs and backend calls) for a
/// screen. Shared by the Task Board card buttons and the Task Details actions.
class TaskActionHandler {
  TaskActionHandler(this.context, this.ref, {this.bottomInset = 12});

  final BuildContext context;
  final WidgetRef ref;

  /// Extra bottom padding for sheets (e.g. the bottom nav overhang).
  final double bottomInset;

  TaskActions get _actions => ref.read(taskActionsProvider);

  /// Dispatches [action] for [t]. [onDeleted] runs after a successful delete.
  Future<void> run(TaskItem t, TaskAction action,
      {VoidCallback? onDeleted}) async {
    switch (action) {
      case TaskAction.serviceReport:
        await serviceReport(t);
      case TaskAction.approve:
        await runTaskAction(
          context,
          () => _actions.approveRequest(t),
          success: '${t.title} approved',
        );
      case TaskAction.reject:
        await _reject(t);
      case TaskAction.reassign:
        await assign(t, reassign: true);
      case TaskAction.unassign:
        await runTaskAction(
          context,
          () => _actions.unassign(t),
          success: '${t.title} returned to the unassigned queue',
        );
      case TaskAction.assign:
        await assign(t);
      case TaskAction.priority:
        await _prioritySheet(t);
      case TaskAction.status:
        await _statusSheet(t);
      case TaskAction.escalate:
        await runTaskAction(
          context,
          () => _actions.escalate(t,
              reason: 'Overdue by ${-t.hoursToSla()}h (SLA)'),
          success: '${t.title} escalated to Manager',
        );
      case TaskAction.accept:
        await runTaskAction(
          context,
          () => _actions.accept(t),
          success: 'You accepted "${t.title}"',
        );
      case TaskAction.addScreenshot:
        await _addScreenshot(t);
      case TaskAction.complete:
        await _resolutionSheet(t);
      case TaskAction.hold:
        await _holdSheet(t);
      case TaskAction.startWork:
        await runTaskAction(
          context,
          () => _actions.startWork(t),
          success: 'Work started on "${t.title}"',
        );
      case TaskAction.rate:
        await _rateSheet(t);
      case TaskAction.delete:
        final ok = await confirmTaskDelete(context, t);
        if (!ok || !context.mounted) return;
        final deleted = await runTaskAction(
          context,
          () => _actions.delete(t),
          success: 'Task deleted',
        );
        if (deleted) onDeleted?.call();
    }
  }

  /// Star toggle: high / critical -> medium, anything else -> high.
  Future<void> togglePriority(TaskItem t) {
    final isHigh =
        t.priority == TaskPriority.high || t.priority == TaskPriority.critical;
    final next = isHigh ? TaskPriority.medium : TaskPriority.high;
    return runTaskAction(
      context,
      () => _actions.update(t, priority: next),
      success: 'Priority -> ${next.label}',
    );
  }

  // ---- Service report ----

  /// "Service Report" dialog: Share opens the share sheet, Print the system
  /// print / preview dialog.
  Future<void> serviceReport(TaskItem t) async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Service Report',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Generate service report for "${t.title}"?',
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Montserrat')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.share, size: 16, color: Colors.white),
            label: const Text(
              'Share',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.print, size: 16, color: Colors.white),
            label: const Text(
              'Print',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    await _runReport(t, share: choice);
  }

  /// Admins get the backend-generated report; everyone else (and admins when
  /// the backend cannot produce one) gets the locally rendered report.
  Future<void> _runReport(TaskItem t, {required bool share}) async {
    final role = ref.read(currentUserRoleProvider);
    final messenger = ScaffoldMessenger.of(context);
    Uint8List? bytes;
    if (role == UserRole.superAdmin || role == UserRole.manager) {
      try {
        bytes = await _actions.serviceReportPdf(t);
      } catch (_) {
        bytes = null;
      }
    }
    try {
      if (share) {
        await ServiceReportService.share(t, bytes: bytes);
      } else {
        await ServiceReportService.open(t, bytes: bytes);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not generate report'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  // ---- Assign ----

  /// Service Engineer picker; busy engineers need a confirmation.
  Future<void> assign(TaskItem t, {bool reassign = false}) async {
    final picked = await showModalBottomSheet<(User, TechnicianStats)>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: _sheetShape,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(20, 20, 20, _inset(ctx) + 8),
        children: [
          Text(
            reassign
                ? 'Reassign Service Engineer'
                : 'Assign to Service Engineer',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reassign && t.hasAssignee) ...[
            const SizedBox(height: 4),
            Text(
              'Currently: ${t.assignee}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TechnicianChoices(
            builder: (techs, stats) => Column(
              children: [
                for (final tech in techs)
                  _technicianTile(ctx, tech, statsFor(tech, stats)),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final (tech, s) = picked;
    if (s.isOverloaded) {
      final ok = await _confirmOverload(tech.name, s.active);
      if (ok != true || !context.mounted) return;
    }
    await runTaskAction(
      context,
      () => _actions.assign(t, tech.backendId),
      success: reassign && t.hasAssignee
          ? 'Reassigned to ${tech.name}'
          : 'Assigned to ${tech.name}',
    );
  }

  Widget _technicianTile(BuildContext ctx, User tech, TechnicianStats s) {
    final overloaded = s.isOverloaded;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEBF0EA),
        child: Text(
          tech.name.isNotEmpty ? tech.name[0] : '?',
          style: const TextStyle(color: _green),
        ),
      ),
      title: Text(tech.name, style: const TextStyle(fontFamily: 'Montserrat')),
      subtitle: Text(
        '${s.active} active task(s)',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          color: overloaded ? const Color(0xFFD32F2F) : const Color(0xFF6B6B6B),
        ),
      ),
      trailing: overloaded
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
      onTap: () => Navigator.pop(ctx, (tech, s)),
    );
  }

  Future<bool?> _confirmOverload(String name, int active) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Montserrat')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  // ---- Workflow sheets ----

  Future<void> _reject(TaskItem t) async {
    final reason = await askTaskReason(
      context,
      title: 'Reject request',
      hint: 'Reason for rejecting',
      confirmLabel: 'Reject',
    );
    if (reason == null || !context.mounted) return;
    await runTaskAction(
      context,
      () => _actions.rejectRequest(t, reason: reason),
      success: '${t.title} rejected',
    );
  }

  /// Picks a screenshot; it is uploaded with the work report on
  /// "Complete Work".
  Future<void> _addScreenshot(TaskItem t) async {
    final path = await pickTaskImage(context);
    if (path == null || !context.mounted) return;
    final notifier = ref.read(pendingScreenshotsProvider.notifier);
    final list = [...?notifier.state[t.id], path];
    notifier.state = {...notifier.state, t.id: list};
    _snack('Screenshot added (${t.attachments.length + list.length})');
  }

  /// Hold needs a reason on the backend: pick one of its hold types.
  Future<void> _holdSheet(TaskItem t) async {
    final type = await _pickSheet<HoldType>(
      title: 'Hold reason',
      tiles: (ctx) => [
        for (final h in HoldType.values)
          ListTile(
            leading: Icon(
              switch (h) {
                HoldType.spareRequired => Icons.build_circle_outlined,
                HoldType.expertServiceRequired => Icons.engineering_outlined,
                HoldType.others => Icons.more_horiz,
              },
              color: const Color(0xFF9A9A9A),
            ),
            title: Text(h.label, style: _tileStyle(false)),
            onTap: () => Navigator.pop(ctx, h),
          ),
      ],
    );
    if (type == null || !context.mounted) return;
    await runTaskAction(
      context,
      () => _actions.hold(t, type: type),
      success: 'Status -> ${TaskStatus.hold.label}',
    );
  }

  /// Status change (Super Admin / Manager): any lifecycle stage, including
  /// reopening a closed task.
  Future<void> _statusSheet(TaskItem t) async {
    final s = await _pickSheet<TaskStatus>(
      title: 'Change status',
      tiles: (ctx) => [
        for (final s in TaskStatus.values)
          ListTile(
            leading: Icon(
              _statusIcon(s),
              color: s == t.status ? _green : const Color(0xFF9A9A9A),
            ),
            title: Text(s.label, style: _tileStyle(s == t.status)),
            trailing: s == t.status
                ? const Icon(Icons.check, color: _green, size: 18)
                : null,
            onTap: () => Navigator.pop(ctx, s),
          ),
      ],
    );
    if (s == null || s == t.status || !context.mounted) return;
    switch (s) {
      case TaskStatus.hold:
        await _holdSheet(t);
      case TaskStatus.inProgress:
        await runTaskAction(
          context,
          () => _actions.startWork(t),
          success: 'Status -> ${s.label}',
        );
      case TaskStatus.open:
        await runTaskAction(
          context,
          () => _actions.setStatus(t, ServiceStatus.open),
          success: t.isClosed ? '${t.title} reopened' : 'Status -> ${s.label}',
        );
      case TaskStatus.closed:
        await runTaskAction(
          context,
          () => _actions.setStatus(t, ServiceStatus.closed),
          success: 'Status -> ${s.label}',
        );
    }
  }

  Future<void> _prioritySheet(TaskItem t) async {
    final p = await _pickSheet<TaskPriority>(
      title: 'Set priority',
      tiles: (ctx) => [
        for (final p in TaskPriority.values)
          ListTile(
            leading: Icon(Icons.flag, color: _priorityColor(p)),
            title: Text(
              '${p.label}  (SLA ${p.slaHours}h)',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(ctx, p),
          ),
      ],
    );
    if (p == null || !context.mounted) return;
    await runTaskAction(
      context,
      () => _actions.update(t, priority: p),
      success: 'Priority -> ${p.label}',
    );
  }

  /// Work-done notes plus screenshots; on submit the work report is sent and
  /// the task is completed (pending client confirmation / rating).
  Future<void> _resolutionSheet(TaskItem t) async {
    final notesController =
        TextEditingController(text: t.resolutionNotes ?? '');
    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: _sheetShape,
      builder: (_) => Consumer(
        builder: (ctx, sheetRef, _) {
          final pending =
              sheetRef.watch(pendingScreenshotsProvider)[t.id] ?? const [];
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, _inset(ctx) + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete work',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Describe the work done. The client will see this.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  style:
                      const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Work done, parts replaced, observations…',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.image_outlined,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${t.attachments.length + pending.length} '
                      'screenshot(s) attached',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _addScreenshot(t),
                      icon: const Icon(Icons.add_a_photo_outlined,
                          size: 18, color: _green),
                      label: const Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final notes = notesController.text.trim();
                      if (notes.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Please describe the work done')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, notes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Submit & Close',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (notes == null || !context.mounted) return;
    final pending =
        ref.read(pendingScreenshotsProvider)[t.id] ?? const <String>[];
    final role = ref.read(currentUserRoleProvider);
    final ok = await runTaskAction(
      context,
      () => _actions.complete(
        t,
        actionTaken: notes,
        imagePaths: pending,
        asTechnician: role.isTechnicianLevel,
      ),
      success: 'Work submitted for "${t.title}"',
    );
    if (ok && context.mounted) {
      final notifier = ref.read(pendingScreenshotsProvider.notifier);
      notifier.state = {...notifier.state}..remove(t.id);
    }
  }

  Future<void> _rateSheet(TaskItem t) async {
    int stars = 5;
    final commentController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: _sheetShape,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, _inset(ctx) + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate this service',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setSheet(() => stars = i),
                      icon: Icon(
                        i <= stars ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFB300),
                        size: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Optional feedback',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;
    final comment = commentController.text.trim();
    await runTaskAction(
      context,
      () => _actions.confirm(
        t,
        rating: stars,
        feedback: comment.isEmpty ? null : comment,
      ),
      success: 'Thanks for your feedback!',
    );
  }

  // ---- Helpers ----

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  );

  double _inset(BuildContext ctx) =>
      MediaQuery.of(ctx).viewInsets.bottom + bottomInset;

  /// A titled bottom sheet of choices returning the picked value.
  Future<T?> _pickSheet<T>({
    required String title,
    required List<Widget> Function(BuildContext ctx) tiles,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: _sheetShape,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: _inset(ctx)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADADA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ...tiles(ctx),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _tileStyle(bool selected) => TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? _green : const Color(0xFF1F1F1F),
      );

  IconData _statusIcon(TaskStatus s) => switch (s) {
        TaskStatus.open => Icons.inbox_outlined,
        TaskStatus.hold => Icons.pause_circle_outline,
        TaskStatus.inProgress => Icons.engineering_outlined,
        TaskStatus.closed => Icons.check_circle_outline,
      };

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.critical => const Color(0xFFD32F2F),
        TaskPriority.high => const Color(0xFFE08600),
        TaskPriority.medium => const Color(0xFF1565C0),
        TaskPriority.low => const Color(0xFF6B6B6B),
      };

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _green),
    );
  }
}
