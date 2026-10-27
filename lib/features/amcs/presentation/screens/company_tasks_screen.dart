import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../data/amc_provider.dart';
import '../../domain/models/amc_contract.dart';
import '../widgets/amc_async_states.dart';

/// The design's four status tabs. Completed (awaiting client sign-off) is
/// grouped under Closed.
enum _Tab {
  open('Open', 'Open', 'assets/images/icon_stat_open.svg', Color(0xFF11682E)),
  hold('Hold', 'Hold', 'assets/images/icon_stat_hold.svg', Color(0xFF9E663B)),
  inProgress(
    'In Progress',
    'In progress',
    'assets/images/icon_stat_progress.svg',
    Color(0xFF5B899E),
  ),
  closed(
    'Closed',
    'Closed',
    'assets/images/icon_stat_closed.svg',
    Color(0xFF5B899E),
  );

  const _Tab(this.label, this.statLabel, this.icon, this.color);
  final String label;
  final String statLabel;
  final String icon;
  final Color color;

  bool matches(TaskStatus s) => switch (this) {
        _Tab.open => s == TaskStatus.open,
        _Tab.hold => s == TaskStatus.hold,
        _Tab.inProgress => s == TaskStatus.inProgress,
        _Tab.closed => s == TaskStatus.closed || s == TaskStatus.completed,
      };
}

String _statusLabel(TaskStatus s) => switch (s) {
      TaskStatus.open => 'Open',
      TaskStatus.hold => 'Hold',
      TaskStatus.inProgress => 'In Progress',
      TaskStatus.completed => 'Completed',
      TaskStatus.closed => 'Closed',
    };

class CompanyTasksScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String? companyName;

  const CompanyTasksScreen({
    super.key,
    required this.companyId,
    this.companyName,
  });

  @override
  ConsumerState<CompanyTasksScreen> createState() => _CompanyTasksScreenState();
}

class _CompanyTasksScreenState extends ConsumerState<CompanyTasksScreen> {
  _Tab _selectedTab = _Tab.open;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? get _companyId => int.tryParse(widget.companyId);

  List<ServiceTask> _companyTasks(List<ServiceTask> all) =>
      all.where((t) => t.company?.id == _companyId).toList();

  List<ServiceTask> _filtered(List<ServiceTask> tasks) {
    // When searching, search across all tasks; otherwise filter by tab
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return tasks.where((t) {
        return [
          t.ticketNo,
          _title(t),
          _location(t),
          t.equipment?.name ?? '',
          t.company?.displayName ?? '',
          t.equipment?.egSerialNumber ?? '',
          _statusLabel(t.status),
          if (t.createdAt != null) displayDate(t.createdAt!),
        ].any((v) => v.toLowerCase().contains(q));
      }).toList();
    }
    return tasks.where((t) => _selectedTab.matches(t.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final companyTasks = _companyTasks(tasksAsync.valueOrNull ?? const []);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.7),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildStatCards(companyTasks),
                const SizedBox(height: 18),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildTabBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: tasksAsync.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const AmcLoadingState(),
                    error: (e, _) => AmcErrorState(
                      error: e,
                      onRetry: () => ref.invalidate(tasksProvider),
                    ),
                    data: (all) => _buildTaskList(_filtered(_companyTasks(all))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canManage =>
      Permissions.canManageTasks(ref.watch(currentUserRoleProvider));

  Widget _buildHeader(BuildContext context) {
    final canAdd = Permissions.canAccessRoute(
      ref.watch(currentUserRoleProvider),
      Routes.addTask,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: SvgPicture.asset(
              'assets/images/icon_arrow_back.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Company Tasks',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          if (canAdd)
            GestureDetector(
              onTap: () {
                context.push(
                  '${Routes.addTask}/${widget.companyId}',
                  extra: {'companyName': widget.companyName},
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _green, width: 1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Per-status count cards (Figma: Open / Hold / In progress / Closed).
  Widget _buildStatCards(List<ServiceTask> tasks) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _Tab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final tab = _Tab.values[i];
          final count = tasks.where((t) => tab.matches(t.status)).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
            child: Container(
              width: 112,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE0D9EE),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(tab.icon, width: 41, height: 41),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: tab.color,
                          ),
                        ),
                        Text(
                          tab.statLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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

  Widget _buildSearchBar() {
    const none = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE0D9EE),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          cursorColor: _green,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search Tasks',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.25),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.black.withValues(alpha: 0.3),
              size: 24,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: none,
            focusedBorder: none,
            border: none,
          ),
        ),
      ),
    );
  }

  /// Underline-style status tabs; the active tab is green with a green
  /// underline as wide as its label.
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final tab in _Tab.values)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTab = tab),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: _selectedTab == tab
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _selectedTab == tab
                            ? _green
                            : const Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _selectedTab == tab ? 1 : 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2),
                        ),
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

  Widget _buildTaskList(List<ServiceTask> tasks) {
    return RefreshIndicator(
      color: _green,
      onRefresh: () => ref.refresh(tasksProvider.future),
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 260,
                  child: AmcEmptyState(
                    message: _searchQuery.isNotEmpty
                        ? 'No matching tasks'
                        : 'No ${_selectedTab.label} tasks',
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 100),
              itemCount: tasks.length,
              itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
            ),
    );
  }

  String _title(ServiceTask t) {
    if (t.name.isNotEmpty) return t.name;
    if (t.ticketNo.isNotEmpty) return t.ticketNo;
    return 'Task #${t.id}';
  }

  String _location(ServiceTask t) =>
      t.equipment?.location ?? t.company?.branchName ?? '';

  String _image(ServiceTask t) => mediaUrl(
        t.images.isNotEmpty ? t.images.first : t.equipment?.imageUrl,
      );

  /// A rejected ticket is the backend's "disabled" task.
  bool _isActive(ServiceTask t) => t.approval != ApprovalStage.rejected;

  Widget _buildTaskCard(ServiceTask task) {
    final companyLabel = task.company?.displayName ?? widget.companyName ?? '';
    final created = task.createdAt;
    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        height: 221,
        margin: const EdgeInsets.only(bottom: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE0D9EE),
              blurRadius: 32,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 15,
              top: 19,
              child: CompanyLogo(
                url: _image(task),
                width: 108,
                height: 135,
                fallbackIcon: Icons.build,
              ),
            ),
            Positioned(
              left: 138,
              top: 16,
              right: 44,
              child: Text(
                _title(task),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.51,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Builder(
                builder: (_) {
                  Offset tapPos = Offset.zero;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => tapPos = d.globalPosition,
                    onTap: () => _showTaskMenu(task, tapPos),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              left: 136,
              top: 48,
              child: Icon(
                Icons.location_on,
                color: Color(0xFF125420),
                size: 16,
              ),
            ),
            Positioned(
              left: 158,
              top: 47,
              width: 80,
              child: Text(
                _location(task),
                maxLines: 1,
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
            Positioned(
              left: 242,
              top: 44,
              child: Container(
                height: 25,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF0EA),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF125420),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(task.status),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF125420),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 137,
              top: 79,
              right: 12,
              child: _metaRow('Equipment', task.equipment?.name ?? ''),
            ),
            Positioned(
              left: 137,
              top: 103,
              right: 12,
              child: _metaRow('Company', companyLabel),
            ),
            Positioned(
              left: 137,
              top: 127,
              right: 12,
              child: _metaRow('S.No', task.equipment?.egSerialNumber ?? ''),
            ),
            // Created At footer band
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 19),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF0EA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: 'Created At : ',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                      TextSpan(
                        text: created == null ? '—' : displayDate(created),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.subtitles, color: Colors.black87, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: value.isEmpty ? '—' : value,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTaskMenu(ServiceTask task, Offset at) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;
    final position = RelativeRect.fromLTRB(
      (at.dx - 200).clamp(8.0, size.width - 8),
      at.dy + 8,
      size.width - at.dx,
      size.height - at.dy,
    );
    final active = _isActive(task);
    final canManage = _canManage;
    final choice = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 10,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _popupItem('view', Icons.visibility_outlined, 'View Details'),
        if (canManage) ...[
          _popupItem('edit', Icons.edit_outlined, 'Edit'),
          _popupItem(
            active ? 'disable' : 'enable',
            active ? Icons.block : Icons.check_circle_outline,
            active ? 'Disable' : 'Enable',
            isDestructive: active,
            // No backend action restores a rejected ticket.
            enabled: active,
          ),
        ],
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'view':
        _navigateToTaskDetails(task);
      case 'edit':
        _editTask(task);
      case 'disable':
        _disableTask(task);
    }
  }

  PopupMenuItem<String> _popupItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
    bool enabled = true,
  }) {
    final color = isDestructive ? _danger : _green;
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTaskDetails(ServiceTask task) {
    final created = task.createdAt;
    context.push(
      '${Routes.taskDetails}/${task.id}',
      extra: {
        'taskTitle': _title(task),
        'location': _location(task),
        'status': _statusLabel(task.status),
        'imageUrl': _image(task),
        'companyName': task.company?.displayName ?? widget.companyName,
        'serialNumber': task.equipment?.egSerialNumber,
        if (created != null) 'createdOn': displayDate(created),
      },
    );
  }

  void _editTask(ServiceTask task) {
    context.push(
      '${Routes.addTask}/${widget.companyId}',
      extra: {
        'companyName': widget.companyName,
        'isEdit': true,
        'editTask': {'taskId': task.id},
      },
    );
  }

  Future<void> _disableTask(ServiceTask task) async {
    final reason = await _askReason();
    if (reason == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(amcRepositoryProvider).rejectTask(task.id, reason);
      ref.invalidate(tasksProvider);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Task disabled',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _danger),
      );
    }
  }

  /// `rejectTask` requires a reason.
  Future<String?> _askReason() => showDialog<String>(
        context: context,
        builder: (_) => const _ReasonDialog(),
      );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Disable task?',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        cursorColor: _green,
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Reason',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black.withValues(alpha: 0.3),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _green),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final v = _controller.text.trim();
            if (v.isNotEmpty) Navigator.pop(context, v);
          },
          child: const Text(
            'Disable',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              color: _danger,
            ),
          ),
        ),
      ],
    );
  }
}
