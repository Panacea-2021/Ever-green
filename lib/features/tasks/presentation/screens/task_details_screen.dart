import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../widgets/task_action_button.dart';
import '../widgets/task_action_handler.dart';
import '../widgets/task_workflow.dart';

/// Task details screen matching Figma design with:
/// - Hero image header with title overlay
/// - Task title, location, status badge
/// - Company Information card
/// - Task Details card with footer
/// - Role-based Actions card (the workflow moved off the board cards)
/// - Disable/Edit buttons at bottom (Super Admin / Manager)
class TaskDetailsScreen extends ConsumerWidget {
  final String taskId;

  final String? taskTitle;
  final String? location;
  final String? status;
  final String? imageUrl;
  final String? companyName;
  final String? clientName;
  final String? mobile;
  final String? technician;
  final String? technicianMobile;
  final String? createdOn;
  final String? serialNumber;
  final String? description;
  final String? lastUpdatedOn;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    this.taskTitle,
    this.location,
    this.status,
    this.imageUrl,
    this.companyName,
    this.clientName,
    this.mobile,
    this.technician,
    this.technicianMobile,
    this.createdOn,
    this.serialNumber,
    this.description,
    this.lastUpdatedOn,
  });

  static const Color _green = Color(0xFF106220);
  static const Color _greenTitle = Color(0xFF11682E);
  static const Color _blueTitle = Color(0xFF5B899E);
  static const Color _lightGreenBg = Color(0xFFEBF0EA);
  static const String _defaultImage = 'assets/images/task_img_1.png';

  static String _fmt(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}-${two(l.month)}-${l.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskItemsProvider);
    final tasks = async.value ?? const <TaskItem>[];
    final match = tasks.where((t) => t.id == taskId).toList();

    // Use passed values or fallback to provider data
    final task = match.isNotEmpty ? match.first : null;

    if (task == null && taskTitle == null && async.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    final equipment = task?.source?.equipment;
    final serial = equipment == null
        ? ''
        : [equipment.egSerialNumber, equipment.serialNumber ?? '']
            .where((s) => s.isNotEmpty)
            .join(' / ');
    final taskImg = task?.imageUrl ?? '';

    final individual = task?.isIndividual ?? false;
    final title = taskTitle ?? task?.title ?? 'Task';
    final loc = location ??
        (individual ? task?.address : null) ??
        task?.source?.company?.location ??
        equipment?.location ??
        '';
    final stat = status ?? task?.lifecycleLabel ?? 'Not Started';
    final img = imageUrl ??
        (taskImg.startsWith('http') ? taskImg : _defaultImage);
    final company = companyName ?? task?.companyName ?? '';
    final client = clientName ?? task?.clientName ?? '';
    final mob = mobile ?? task?.clientPhone ?? '';
    final tech = technician ??
        (task != null && task.hasAssignee ? task.assignee : '');
    final techMob = technicianMobile ?? task?.technicianPhone ?? '';
    final created = createdOn ?? _fmt(task?.createdAt);
    final sNo = serialNumber ?? serial;
    final desc = description ?? task?.description ?? '';
    final lastUpdated = lastUpdatedOn ?? _fmt(task?.source?.updatedAt);

    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? UserRole.client;
    final actions = task == null
        ? const <TaskButton>[]
        : taskDetailButtonsFor(task, user);
    final canEdit = taskMenuFor(role).contains(TaskMenuItem.edit);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image Header
                  _buildHeroHeader(context, img),

                  // Task Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),

                  // Location + Status
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF125420), size: 16),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            loc,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF125420),
                              letterSpacing: -0.42,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(stat),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (individual)
                    _buildContactCard(context, task!)
                  else
                    _buildCompanyCard(company, client, mob),

                  const SizedBox(height: 20),

                  _buildTaskDetailsCard(
                    tech,
                    techMob,
                    created,
                    individual ? null : sNo,
                    desc,
                    lastUpdated,
                  ),

                  if (task != null && actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildActionsCard(context, ref, task, actions),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          if (canEdit)
            _buildBottomButtons(context, ref, task, title, loc, stat, company, client, mob, tech, techMob, created, sNo, desc),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String img) {
    final fallback = Container(
      color: const Color(0xFF87CEEB),
      child: const Center(
        child: Icon(Icons.build, size: 80, color: Colors.white54),
      ),
    );
    return SizedBox(
      height: 344,
      child: Stack(
        children: [
          // Hero Image
          Positioned.fill(
            child: taskImage(img, fallback: fallback),
          ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Back button and title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _lightGreenBg,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF125420), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF125420),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(String company, String client, String mobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: _greenTitle.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, color: _greenTitle, size: 26),
          ),
          const SizedBox(height: 14),

          // Title
          const Text(
            'Company Information',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _greenTitle,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 24),

          // Name
          Align(
            alignment: Alignment.centerLeft,
            child: _infoField('Name', company.isEmpty ? '-' : company),
          ),
          const SizedBox(height: 14),

          // Client
          Align(
            alignment: Alignment.centerLeft,
            child: _infoField('Client', client.isEmpty ? '-' : client),
          ),
          const SizedBox(height: 14),

          // Mobile
          Align(
            alignment: Alignment.centerLeft,
            child: _infoField('Mobile', mobile.isEmpty ? '-' : mobile),
          ),
        ],
      ),
    );
  }

  /// Individual tickets: the person, a tap-to-copy mobile number and the
  /// address, in place of the company / equipment details.
  Widget _buildContactCard(BuildContext context, TaskItem task) {
    final phone = task.contactPhone;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: _greenTitle.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: _greenTitle, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'Contact',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _greenTitle,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: _infoField(
              'Name',
              task.contactName.isEmpty ? '-' : task.contactName,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: phone.isEmpty
                ? _infoField('Mobile', '-')
                : InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: phone));
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mobile number copied'),
                          backgroundColor: _green,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _infoField('Mobile', phone, link: true)),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, size: 16, color: _green),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _infoField(
              'Address',
              task.address.isEmpty ? '-' : task.address,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetailsCard(
    String technician,
    String techMobile,
    String createdOn,
    String? serialNo,
    String description,
    String lastUpdated,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: _blueTitle.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_outlined, color: _blueTitle, size: 24),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  'Task Details',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _blueTitle,
                    letterSpacing: -0.54,
                  ),
                ),
                const SizedBox(height: 24),

                // Technician
                Align(
                  alignment: Alignment.centerLeft,
                  child: _infoField(
                    'Service Engineer',
                    technician.isEmpty ? '-' : technician,
                  ),
                ),
                const SizedBox(height: 12),

                // Mobile
                Align(
                  alignment: Alignment.centerLeft,
                  child: _infoField('Mobile', techMobile.isEmpty ? '-' : techMobile),
                ),
                const SizedBox(height: 12),

                // Created on
                Align(
                  alignment: Alignment.centerLeft,
                  child: _infoField('Created on', createdOn.isEmpty ? '-' : createdOn),
                ),
                const SizedBox(height: 12),

                if (serialNo != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _infoField('S.No', serialNo.isEmpty ? '-' : serialNo),
                  ),
                  const SizedBox(height: 12),
                ],

                // Description
                Align(
                  alignment: Alignment.centerLeft,
                  child: _infoField('Description', description.isEmpty ? '-' : description),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Last Updated Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            decoration: const BoxDecoration(
              color: _lightGreenBg,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.45,
                ),
                children: [
                  TextSpan(
                    text: 'Last Updated on : ',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: lastUpdated.isEmpty ? '-' : lastUpdated,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Role-based workflow actions (accept, start, hold, complete, approve,
  /// assign, status, escalate, rate, delete, ...) from [taskDetailButtonsFor].
  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    List<TaskButton> buttons,
  ) {
    final handler = TaskActionHandler(context, ref);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: _greenTitle.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: _greenTitle, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Actions',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _greenTitle,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final b in buttons)
                TaskActionButton(
                  key: ValueKey('task-action-${b.action.name}'),
                  label: _actionLabel(b.action),
                  icon: b.action.icon,
                  kind: b.kind,
                  onTap: () => handler.run(
                    task,
                    b.action,
                    onDeleted: () {
                      if (context.mounted) context.pop();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _actionLabel(TaskAction action) =>
      switch (action) {
        TaskAction.status => 'Change Status',
        TaskAction.delete => 'Delete Task',
        _ => action.label,
      };

  Widget _infoField(String label, String value, {bool link = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.45,
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: link ? _green : Colors.black),
          ),
        ],
      ),
    );
  }

  /// Disable: a pending request is rejected (with a reason); any other
  /// ticket is closed.
  Future<void> _disable(BuildContext context, WidgetRef ref, TaskItem? task) async {
    if (task == null) return;
    final actions = ref.read(taskActionsProvider);
    if (task.approval == ApprovalState.requested) {
      final reason = await askTaskReason(
        context,
        title: 'Disable task',
        hint: 'Reason for disabling',
        confirmLabel: 'Disable',
      );
      if (reason == null || !context.mounted) return;
      await runTaskAction(
        context,
        () => actions.rejectRequest(task, reason: reason),
        success: 'Task disabled',
      );
      return;
    }
    if (task.serviceStatus == ServiceStatus.closed) return;
    await runTaskAction(
      context,
      () => actions.setStatus(task, ServiceStatus.closed),
      success: 'Task disabled',
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    WidgetRef ref,
    TaskItem? task,
    String title,
    String loc,
    String stat,
    String company,
    String client,
    String mob,
    String tech,
    String techMob,
    String created,
    String sNo,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Disable button
            Expanded(
              child: GestureDetector(
                onTap: () => _disable(context, ref, task),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFF155622).withValues(alpha: 0.5), width: 1),
                  ),
                  child: const Text(
                    'Disable',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0E501B),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Edit button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (task != null && task.isIndividual) {
                    showEditTaskSheet(context, task);
                    return;
                  }
                  context.push(
                    '${Routes.addTask}/edit',
                    extra: {
                      'isEdit': true,
                      'companyName': company,
                      'editTask': {
                        'taskId': taskId,
                        'taskTitle': title,
                        'location': loc,
                        'status': stat,
                        'companyName': company,
                        'clientName': client,
                        'mobile': mob,
                        'technician': tech,
                        'technicianMobile': techMob,
                        'createdOn': created,
                        'serialNumber': sNo,
                        'description': desc,
                      },
                    },
                  );
                },
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _green,
                        Color.lerp(_green, Colors.black, 0.12)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
}
