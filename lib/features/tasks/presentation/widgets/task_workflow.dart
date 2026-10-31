import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';

const Color _green = Color(0xFF106220);
const Color _danger = Color(0xFFD32F2F);

/// Visual style of a task action button.
enum TaskButtonKind { filled, outline, danger }

/// Task card actions from the design, in display order.
enum TaskAction {
  serviceReport('Service Report', Icons.description_outlined),
  approve('Approve', Icons.check_circle_outline),
  reject('Reject', Icons.cancel_outlined),
  reassign('Reassign', Icons.swap_horiz_rounded),
  unassign('Unassign', Icons.person_remove_alt_1_outlined),
  assign('Assign', Icons.person_add_alt_1_outlined),
  priority('Priority', Icons.flag_outlined),
  status('Status', Icons.sync_alt_rounded),
  escalate('Escalate', Icons.trending_up_rounded),
  accept('Accept', Icons.task_alt_rounded),
  addScreenshot('Add Screenshot', Icons.add_a_photo_outlined),
  complete('Complete Work', Icons.done_all_rounded),
  hold('Hold', Icons.pause_rounded),
  startWork('Start Work', Icons.play_arrow_rounded),
  rate('Confirm & Rate', Icons.star_rounded),
  delete('Delete', Icons.delete_outline);

  const TaskAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

class TaskButton {
  final TaskAction action;
  final TaskButtonKind kind;
  const TaskButton(this.action, [this.kind = TaskButtonKind.outline]);
}

/// Overflow-menu entries on a task card.
enum TaskMenuItem { assign, status, edit, delete }

/// The design's role rules for the task card buttons:
/// - everyone: Service Report, in every phase
/// - admins and senior technicians: Approve / Reject incoming requests
/// - Super Admin (every tab) / Manager (active tasks): assign, unassign,
///   priority, status, escalate when overdue
/// - Senior Technician: assign / reassign while open
/// - the assigned technician: accept, start, hold, screenshots, complete
/// - client-side roles: confirm & rate completed work
List<TaskButton> taskButtonsFor(TaskItem t, User? user) {
  final role = user?.role ?? UserRole.client;
  final isSuperAdmin = role == UserRole.superAdmin;
  final isManagerial = isSuperAdmin || role == UserRole.manager;
  final isMine = t.technicianId != null && t.technicianId == user?.backendId;
  final buttons = <TaskButton>[];
  void add(TaskAction a, [TaskButtonKind kind = TaskButtonKind.outline]) =>
      buttons.add(TaskButton(a, kind));

  add(TaskAction.serviceReport, TaskButtonKind.filled);

  if ((isManagerial || role == UserRole.seniorTechnician) &&
      !t.isClosed &&
      t.approval == ApprovalState.requested) {
    add(TaskAction.approve, TaskButtonKind.filled);
    add(TaskAction.reject, TaskButtonKind.danger);
  }

  if (isSuperAdmin || (isManagerial && !t.isClosed)) {
    if (t.hasAssignee) {
      add(TaskAction.reassign);
      add(TaskAction.unassign);
    } else {
      add(TaskAction.assign, TaskButtonKind.filled);
    }
    add(TaskAction.priority);
    add(TaskAction.status);
    if (!t.escalated && t.isOverdue() && !t.isClosed) {
      add(TaskAction.escalate, TaskButtonKind.danger);
    }
  }

  if (role == UserRole.seniorTechnician && !t.isClosed) {
    add(t.hasAssignee ? TaskAction.reassign : TaskAction.assign);
  }

  // The backend only lets the assigned technician progress a ticket.
  if (role.isTechnicianLevel && !t.isClosed && isMine) {
    if (t.isAwaitingAcceptance) {
      add(TaskAction.accept, TaskButtonKind.filled);
    } else if (t.status == TaskStatus.inProgress) {
      add(TaskAction.addScreenshot);
      add(TaskAction.complete, TaskButtonKind.filled);
      add(TaskAction.hold);
    } else {
      add(TaskAction.startWork, TaskButtonKind.filled);
      if (t.status != TaskStatus.hold) add(TaskAction.hold);
    }
  }

  if (role.isClientSide &&
      t.approval == ApprovalState.completed &&
      t.rating == null) {
    add(TaskAction.rate, TaskButtonKind.filled);
  }

  return buttons;
}

/// Just the actions of [taskButtonsFor].
List<TaskAction> taskActionsFor(TaskItem t, User? user) =>
    [for (final b in taskButtonsFor(t, user)) b.action];

/// Which overflow-menu items apply to [role].
List<TaskMenuItem> taskMenuFor(UserRole role) {
  final isManagerial = role == UserRole.superAdmin || role == UserRole.manager;
  final canAssign = isManagerial || role == UserRole.seniorTechnician;
  return [
    if (canAssign) TaskMenuItem.assign,
    if (isManagerial) TaskMenuItem.status,
    if (isManagerial) TaskMenuItem.edit,
    if (isManagerial) TaskMenuItem.delete,
  ];
}

/// Task Details actions: every [taskButtonsFor] action plus Delete for the
/// roles whose task menu allows it.
List<TaskButton> taskDetailButtonsFor(TaskItem t, User? user) {
  final role = user?.role ?? UserRole.client;
  return [
    ...taskButtonsFor(t, user),
    if (taskMenuFor(role).contains(TaskMenuItem.delete))
      const TaskButton(TaskAction.delete, TaskButtonKind.danger),
  ];
}

/// Just the actions of [taskDetailButtonsFor].
List<TaskAction> taskDetailActionsFor(TaskItem t, User? user) =>
    [for (final b in taskDetailButtonsFor(t, user)) b.action];

/// The backend lets admins and senior service engineers triage priority;
/// only Super Admin keeps that on closed tickets.
bool canToggleTaskPriority(TaskItem t, UserRole role) {
  if (role == UserRole.superAdmin) return true;
  if (t.isClosed) return false;
  return role == UserRole.manager || role == UserRole.seniorTechnician;
}

/// Whether the board card shows Assign / Reassign for [role].
bool canAssignFromCard(TaskItem t, UserRole role) {
  if (role == UserRole.superAdmin) return true;
  if (t.isClosed) return false;
  return role == UserRole.manager || role == UserRole.seniorTechnician;
}

/// Runs [action] behind a blocking spinner, then shows [success] or the
/// failure message. Returns whether it succeeded.
Future<bool> runTaskAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
  );
  try {
    await action();
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(success), backgroundColor: _green),
    );
    return true;
  } catch (e) {
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('$e'), backgroundColor: _danger),
    );
    return false;
  }
}

/// Active technicians a ticket can be assigned to, with loading / error
/// states. A Senior Technician assigns to junior technicians only.
class TechnicianChoices extends ConsumerWidget {
  const TechnicianChoices({
    super.key,
    required this.builder,
    this.emptyText = 'No active Service Engineers available.',
  });

  final Widget Function(List<User> techs, List<TechnicianStats> stats) builder;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(techniciansProvider);
    final stats = ref.watch(technicianStatsProvider);
    final role = ref.watch(currentUserRoleProvider);
    if (!async.hasValue && async.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (!async.hasValue && async.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '${async.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Color(0xFF6B6B6B),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(techniciansProvider),
              child: const Text('Retry', style: TextStyle(color: _green)),
            ),
          ],
        ),
      );
    }
    final techs = (async.value ?? const <User>[])
        .where((u) => u.isActive)
        .where(
          (u) =>
              role != UserRole.seniorTechnician ||
              u.role == UserRole.technician,
        )
        .toList();
    if (techs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          emptyText,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Color(0xFF6B6B6B),
          ),
        ),
      );
    }
    return builder(techs, stats);
  }
}

/// Stats for [tech], or zeros when they have no tickets yet.
TechnicianStats statsFor(User tech, List<TechnicianStats> stats) {
  for (final s in stats) {
    if (s.technicianId == tech.backendId) return s;
  }
  return TechnicianStats(
    name: tech.name,
    technicianId: tech.backendId,
    active: 0,
    completed: 0,
    avgResolutionHours: 0,
    avgRating: 0,
  );
}

/// Asks for a short reason (reject / disable). Returns null when cancelled.
Future<String?> askTaskReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(context, reason);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _danger),
          child: Text(
            widget.confirmLabel,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Red "Delete Task" confirmation dialog. Returns true when confirmed.
Future<bool> confirmTaskDelete(BuildContext context, TaskItem t) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete Task',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3 * anim.value,
          sigmaY: 3 * anim.value,
        ),
        child: Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * curved.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33D32F2F),
                          blurRadius: 36,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDE8E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: _danger,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Delete Task',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delete "${t.title}" (Ticket ${t.ticketNo})?\n'
                          'This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFD8D8D8),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF545454),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE53935),
                                        Color(0xFFD32F2F),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _danger.withValues(alpha: 0.32),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => Navigator.pop(ctx, true),
                                      child: const Center(
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return ok == true;
}

/// Picks one image from [source] and returns its local path.
Future<String?> pickImageFrom(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 70);
  return file?.path;
}

/// Asks for camera or gallery and returns the picked image path.
Future<String?> pickTaskImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
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
          ListTile(
            leading: const Icon(Icons.camera_alt, color: _green),
            title: const Text(
              'Camera',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: _green),
            title: const Text(
              'Gallery',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return pickImageFrom(source);
}

/// Thumbnail for a locally picked image path.
Widget localImageThumb(String path, {double size = 72}) {
  final fallback = Container(
    width: size,
    height: size,
    color: Colors.grey.shade200,
    child: Icon(Icons.image, color: Colors.grey.shade400),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: kIsWeb
        ? Image.network(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
  );
}

/// Network image for a stored backend file, asset paths otherwise.
Widget taskImage(
  String url, {
  BoxFit fit = BoxFit.cover,
  required Widget fallback,
}) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => fallback);
  }
  if (url.isEmpty) return fallback;
  return Image.asset(url, fit: fit, errorBuilder: (_, __, ___) => fallback);
}

/// "Edit Task" bottom sheet. Equipment tickets edit the title (equipment and
/// company are shown read-only); individual tickets also edit the contact
/// name, mobile number and address.
Future<void> showEditTaskSheet(
  BuildContext context,
  TaskItem t, {
  double bottomInset = 12,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditTaskSheet(
      task: t,
      bottomInset: bottomInset,
      parentContext: context,
    ),
  );
}

class _EditTaskSheet extends ConsumerStatefulWidget {
  const _EditTaskSheet({
    required this.task,
    required this.bottomInset,
    required this.parentContext,
  });

  final TaskItem task;
  final double bottomInset;
  final BuildContext parentContext;

  @override
  ConsumerState<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<_EditTaskSheet> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _equipment = TextEditingController(text: widget.task.equipment);
  late final _company = TextEditingController(text: widget.task.companyName);
  late final _name = TextEditingController(text: widget.task.contactName);
  late final _phone = TextEditingController(text: widget.task.contactPhone);
  late final _address = TextEditingController(text: widget.task.address);

  @override
  void dispose() {
    for (final c in [_title, _equipment, _company, _name, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _danger),
    );
  }

  void _save() {
    final t = widget.task;
    final title = _title.text.trim();
    if (title.isEmpty) return _error('Title is required');
    String? name, phone, address;
    if (t.isIndividual) {
      name = _name.text.trim();
      phone = normalizeContactPhone(_phone.text);
      address = _address.text.trim();
      if (name.isEmpty) return _error('Person name is required');
      final phoneError = validateContactPhone(phone);
      if (phoneError != null) return _error(phoneError);
      if (address.isEmpty) return _error('Address is required');
      if (name == t.contactName) name = null;
      if (phone == t.contactPhone) phone = null;
      if (address == t.address) address = null;
    }
    final newTitle = title == t.title ? null : title;
    Navigator.pop(context);
    if (newTitle == null && name == null && phone == null && address == null) {
      return;
    }
    final actions = ref.read(taskActionsProvider);
    runTaskAction(
      widget.parentContext,
      () => actions.update(
        t,
        name: newTitle,
        contactName: name,
        contactPhone: phone,
        address: address,
      ),
      success: 'Task updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 8, 20, keyboard + widget.bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADADA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Edit Task',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _field('Task title', _title),
            if (t.isIndividual) ...[
              const SizedBox(height: 12),
              _field('Person name', _name),
              const SizedBox(height: 12),
              _field(
                'Mobile number',
                _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field('Address', _address, maxLines: 3),
            ] else ...[
              const SizedBox(height: 12),
              _field('Equipment', _equipment, enabled: false),
              const SizedBox(height: 12),
              _field('Company', _company, enabled: false),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF125420), _green],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _save,
                    child: const Center(
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A8A8A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
