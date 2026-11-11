import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../web/widgets/web_filter_tiles.dart';
import '../../../../web/widgets/web_header_actions.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../widgets/task_action_handler.dart';
import '../widgets/task_workflow.dart';

/// Super Admin / Manager view for triaging tickets (membership:
/// [TaskItem.inQueueTab]; a ticket can be in several tabs):
/// - "Unassigned": every open ticket.
/// - "Awaiting": open with no Service Engineer for 15+ minutes.
/// - "Assigned": every unclosed ticket with a Service Engineer.
/// - "Escalation": unclosed and escalated, or the status hasn't moved for
///   24 hours.
/// Tapping a card opens the ticket's details.
class UnassignedQueueScreen extends ConsumerStatefulWidget {
  const UnassignedQueueScreen({super.key});

  @override
  ConsumerState<UnassignedQueueScreen> createState() =>
      _UnassignedQueueScreenState();
}

class _UnassignedQueueScreenState extends ConsumerState<UnassignedQueueScreen>
    with WebHeaderActionsMixin {
  static const Color _green = Color(0xFF106220);
  QueueTab _tab = QueueTab.unassigned;

  TaskActionHandler get _handler => TaskActionHandler(context, ref);

  @override
  Widget build(BuildContext context) {
    // Clear header actions on web - this screen has no header buttons
    if (kIsWeb) {
      setHeaderActions([]);
    }
    final async = ref.watch(taskItemsProvider);
    final all = ref.watch(taskProvider);
    final tabs = ref.watch(queueTabsProvider);
    final noEngineer = ref.watch(unassignedCountProvider);

    final list = tabs[_tab]!;
    final overdueOpen =
        tabs[QueueTab.unassigned]!.where((t) => t.isOverdue()).length;
    final awaitingCount = tabs[QueueTab.awaiting]!.length;
    final escalationCount = tabs[QueueTab.escalation]!.length;

    // Use dedicated web layout
    if (kIsWeb) {
      return _webBuild(
        async: async,
        all: all,
        tabs: tabs,
        list: list,
        noEngineer: noEngineer,
        overdueOpen: overdueOpen,
        awaitingCount: awaitingCount,
        escalationCount: escalationCount,
      );
    }

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
                  _header(noEngineer),
                  const SizedBox(height: 6),
                  if (_tab == QueueTab.unassigned && overdueOpen > 0)
                    _overdueBanner(
                      '$overdueOpen open ticket${overdueOpen == 1 ? '' : 's'} past SLA',
                    ),
                  if (_tab == QueueTab.awaiting && awaitingCount > 0)
                    _overdueBanner(
                      '$awaitingCount ticket${awaitingCount == 1 ? '' : 's'} with no Service Engineer for over ${TaskItem.unassignedWaitMinutes} min — assign now',
                    ),
                  if (_tab == QueueTab.escalation && escalationCount > 0)
                    _overdueBanner(
                      '$escalationCount ticket${escalationCount == 1 ? '' : 's'} escalated or stuck in the same status for ${TaskItem.staleStatusHours}h+',
                    ),
                  _tabs(tabs),
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

  /// Dedicated web layout for proper rendering in the web frame.
  Widget _webBuild({
    required AsyncValue<List<TaskItem>> async,
    required List<TaskItem> all,
    required Map<QueueTab, List<TaskItem>> tabs,
    required List<TaskItem> list,
    required int noEngineer,
    required int overdueOpen,
    required int awaitingCount,
    required int escalationCount,
  }) {
    const cream = Color(0xFFFBFCFA);

    Widget content;
    if (all.isEmpty && async.isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100),
          child: CircularProgressIndicator(color: _green),
        ),
      );
    } else if (all.isEmpty && async.hasError) {
      content = _error(async.error);
    } else if (list.isEmpty) {
      content = _empty();
    } else {
      content = _webGrid(list);
    }

    return Scaffold(
      backgroundColor: cream,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () async {
          ref.invalidate(tasksProvider);
          await ref.read(tasksProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with unassigned count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: noEngineer > 0
                              ? const Color(0xFFD32F2F)
                              : _green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$noEngineer unassigned',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overdue banner
                  if (_tab == QueueTab.unassigned && overdueOpen > 0)
                    _webOverdueBanner(
                      '$overdueOpen open ticket${overdueOpen == 1 ? '' : 's'} past SLA',
                    ),
                  if (_tab == QueueTab.awaiting && awaitingCount > 0)
                    _webOverdueBanner(
                      '$awaitingCount ticket${awaitingCount == 1 ? '' : 's'} with no Service Engineer for over ${TaskItem.unassignedWaitMinutes} min — assign now',
                    ),
                  if (_tab == QueueTab.escalation && escalationCount > 0)
                    _webOverdueBanner(
                      '$escalationCount ticket${escalationCount == 1 ? '' : 's'} escalated or stuck in the same status for ${TaskItem.staleStatusHours}h+',
                    ),
                  // Filter tiles
                  _webTabs(tabs),
                  const SizedBox(height: 22),
                  // Content
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webOverdueBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD32F2F)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD32F2F),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
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

  Widget _header(int unassignedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
          if (kIsWeb)
            const Spacer()
          else ...[
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
          ],
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

  static const _webTabMeta = <QueueTab, (String, IconData, Color)>{
    QueueTab.unassigned: (
      'Unassigned',
      Icons.person_off_outlined,
      Color(0xFFD32F2F),
    ),
    QueueTab.awaiting: (
      'Awaiting',
      Icons.hourglass_top_rounded,
      Color(0xFFE08600),
    ),
    QueueTab.assigned: (
      'Assigned',
      Icons.assignment_ind_outlined,
      Color(0xFF106220),
    ),
    QueueTab.escalation: (
      'Escalation',
      Icons.trending_up,
      Color(0xFF6A1B9A),
    ),
  };

  Widget _webTabs(Map<QueueTab, List<TaskItem>> tabs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: WebFilterTiles(
        options: [
          for (final tab in QueueTab.values)
            WebFilterOption(
              label: _webTabMeta[tab]!.$1,
              icon: _webTabMeta[tab]!.$2,
              color: _webTabMeta[tab]!.$3,
              count: tabs[tab]!.length,
              selected: _tab == tab,
              onTap: () => setState(() => _tab = tab),
            ),
        ],
      ),
    );
  }

  Widget _tabs(Map<QueueTab, List<TaskItem>> tabs) {
    if (kIsWeb) return _webTabs(tabs);
    Widget tab(String label, QueueTab value) {
      final sel = _tab == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = value),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF545454),
              ),
            ),
          ),
        ),
      );
    }

    String label(String name, QueueTab value) =>
        '$name\n(${tabs[value]!.length})';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          tab(label('Unassigned', QueueTab.unassigned), QueueTab.unassigned),
          const SizedBox(width: 5),
          tab(label('Awaiting', QueueTab.awaiting), QueueTab.awaiting),
          const SizedBox(width: 5),
          tab(label('Assigned', QueueTab.assigned), QueueTab.assigned),
          const SizedBox(width: 5),
          tab(label('Escalation', QueueTab.escalation), QueueTab.escalation),
        ],
      ),
    );
  }

  static String _span(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  static String _statusLabel(TaskItem t) => switch (t.serviceStatus) {
        ServiceStatus.open => t.hasAssignee ? 'Assigned' : 'Open',
        ServiceStatus.inProgress => 'In Progress',
        ServiceStatus.hold => 'On Hold',
        ServiceStatus.completed => 'Completed',
        ServiceStatus.closed => 'Closed',
      };

  Widget _card(TaskItem t) {
    final overdue = t.isOverdue();
    final alert =
        _tab == QueueTab.awaiting || _tab == QueueTab.escalation || overdue;
    final canAct = t.serviceStatus == ServiceStatus.open ||
        t.serviceStatus == ServiceStatus.inProgress ||
        t.serviceStatus == ServiceStatus.hold;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('${Routes.taskDetails}/${t.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert ? const Color(0xFFD32F2F) : Colors.grey.shade200,
            width: alert ? 1.4 : 1,
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
                if (t.isIndividual) ...[
                  t.contactName,
                  t.address,
                ] else ...[
                  t.equipment,
                  t.companyName,
                ],
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
                _tag(_statusLabel(t), const Color(0xFFF1F1F1),
                    const Color(0xFF545454),),
                if (t.isIndividual)
                  _tag('Individual', const Color(0xFFEBF0EA), _green),
                if (t.escalated)
                  _tag('Escalated', const Color(0xFFFDE8E8),
                      const Color(0xFFD32F2F),),
                if (t.clientName.isNotEmpty)
                  _tag(
                    'Raised by ${t.clientName}',
                    const Color(0xFFEAF2FF),
                    const Color(0xFF1565C0),
                  ),
                if (t.hasAssignee)
                  _tag(
                    '@${t.assignee}',
                    const Color(0xFFF3EAFE),
                    const Color(0xFF6A1B9A),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _timeRow(t),
            if (canAct) ...[
              const SizedBox(height: 12),
              if (!t.hasAssignee)
                _primaryButton(
                  'Assign to Service Engineer',
                  () => _assignSheet(t),
                )
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
          ],
        ),
      ),
    );
  }

  Widget _webGrid(List<TaskItem> list) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        const gap = 18.0;
        final rows = (list.length + cols - 1) ~/ cols;
        return Column(
          children: [
            for (var r = 0; r < rows; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var j = 0; j < cols; j++) ...[
                        if (j > 0) const SizedBox(width: gap),
                        Expanded(
                          child: (r * cols + j) < list.length
                              ? _WebQueueHover(child: _webCard(list[r * cols + j]))
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _webCard(TaskItem t) {
    final overdue = t.isOverdue();
    final alert =
        _tab == QueueTab.awaiting || _tab == QueueTab.escalation || overdue;
    final canAct = t.serviceStatus == ServiceStatus.open ||
        t.serviceStatus == ServiceStatus.inProgress ||
        t.serviceStatus == ServiceStatus.hold;
    final accent = _webTabMeta[_tab]!.$3;
    const red = Color(0xFFD32F2F);

    Widget infoRow(IconData icon, String value) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 15, color: Colors.black.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5A50),
                  ),
                ),
              ),
            ],
          ),
        );

    final infos = <(IconData, String)>[
      if (t.isIndividual) ...[
        (Icons.person_outline, t.contactName),
        (Icons.place_outlined, t.address),
      ] else ...[
        (Icons.precision_manufacturing_outlined, t.equipment),
        (Icons.apartment_outlined, t.companyName),
      ],
    ].where((e) => e.$2.isNotEmpty).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('${Routes.taskDetails}/${t.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: alert ? red.withValues(alpha: 0.6) : const Color(0xFFE2E8E3),
            width: alert ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.12),
                    accent.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(color: accent.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      t.isIndividual
                          ? Icons.person_pin_circle_outlined
                          : Icons.confirmation_number_outlined,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ticket #${t.ticketNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color.lerp(accent, Colors.black, 0.25),
                      ),
                    ),
                  ),
                  _priorityPill(t.priority),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14201A),
                      ),
                    ),
                    for (final info in infos) infoRow(info.$1, info.$2),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(_statusLabel(t), const Color(0xFFF1F1F1),
                            const Color(0xFF545454),),
                        if (t.isIndividual)
                          _tag('Individual', const Color(0xFFEBF0EA), _green),
                        if (t.escalated)
                          _tag('Escalated', const Color(0xFFFDE8E8), red),
                        if (t.clientName.isNotEmpty)
                          _tag(
                            'Raised by ${t.clientName}',
                            const Color(0xFFEAF2FF),
                            const Color(0xFF1565C0),
                          ),
                        if (t.hasAssignee)
                          _tag(
                            '@${t.assignee}',
                            const Color(0xFFF3EAFE),
                            const Color(0xFF6A1B9A),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: alert
                            ? red.withValues(alpha: 0.07)
                            : const Color(0xFFF6F9F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _timeRow(t),
                    ),
                    const Spacer(),
                    if (canAct) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (!t.hasAssignee)
                            Expanded(
                              child: _primaryButton(
                                'Assign',
                                () => _assignSheet(t),
                              ),
                            )
                          else ...[
                            Expanded(
                              child: _primaryButton(
                                'Reassign',
                                () => _assignSheet(t),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _outlineButton('Unassign', () => _unassign(t)),
                          ],
                          const SizedBox(width: 8),
                          _TicketActionsMenu(
                            task: t,
                            handler: _handler,
                            onDeleted: () => ref.invalidate(tasksProvider),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Awaiting: time with no engineer. Escalation: time in the current
  /// status. Otherwise: age, flagged when past SLA.
  Widget _timeRow(TaskItem t) {
    const red = Color(0xFFD32F2F);
    const grey = Color(0xFF6B6B6B);
    final now = DateTime.now();
    final IconData icon;
    final String text;
    final Color color;
    switch (_tab) {
      case QueueTab.awaiting:
        icon = Icons.person_off_outlined;
        text = 'No Service Engineer for '
            '${_span(Duration(minutes: t.unassignedMinutes(now)))}';
        color = red;
      case QueueTab.escalation:
        icon = Icons.trending_up;
        text = t.isStatusStale(now)
            ? '${_statusLabel(t)} for ${_span(t.statusAge(now))} with no change'
            : 'Escalated${(t.escalationReason ?? '').isEmpty ? '' : ' • ${t.escalationReason}'}';
        color = red;
      case QueueTab.unassigned:
      case QueueTab.assigned:
        final overdue = t.isOverdue(now);
        final waited = '${_span(now.difference(t.createdAt))} since raised';
        icon = overdue ? Icons.warning_amber_rounded : Icons.schedule;
        text = overdue ? 'Overdue • $waited' : waited;
        color = overdue ? red : grey;
    }
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

    // On web, show as a dialog for better UX
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 550),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReassign
                                  ? 'Reassign Service Engineer'
                                  : 'Assign Service Engineer',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF14201A),
                              ),
                            ),
                            if (isReassign) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Currently: ${t.assignee}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  color: Color(0xFF6B6B6B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Color(0xFF8A988E)),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: TechnicianChoices(
                      builder: (techs, stats) => Column(
                        children: [
                          for (final tech in techs)
                            _webTechnicianTile(
                              dialogContext,
                              t,
                              tech,
                              statsFor(tech, stats),
                              isReassign,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Mobile: use bottom sheet
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
                                  final ok = await _confirmOverload(
                                      tech.name, s.active,);
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

  Widget _webTechnicianTile(
    BuildContext dialogContext,
    TaskItem t,
    User tech,
    TechnicianStats s,
    bool isReassign,
  ) {
    final isCurrent = tech.backendId == t.technicianId;
    final overloaded = s.isOverloaded;
    return MouseRegion(
      cursor: isCurrent ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        enabled: !isCurrent,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEBF0EA),
          child: Text(
            tech.name.isNotEmpty ? tech.name[0] : '?',
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          tech.name,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isCurrent ? 'Current assignee' : '${s.active} active task(s)',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            color: overloaded ? const Color(0xFFD32F2F) : const Color(0xFF6B6B6B),
          ),
        ),
        trailing: isCurrent
            ? const Icon(Icons.check, color: _green)
            : overloaded
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Busy',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color(0xFFD32F2F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
        onTap: isCurrent
            ? null
            : () async {
                Navigator.pop(dialogContext);
                if (overloaded) {
                  final ok = await _confirmOverload(tech.name, s.active);
                  if (ok != true || !mounted) return;
                }
                _doAssign(t, tech, isReassign);
              },
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
            _tab == QueueTab.unassigned
                ? Icons.inbox_outlined
                : Icons.assignment_turned_in_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            switch (_tab) {
              QueueTab.unassigned => 'No open tickets',
              QueueTab.awaiting => 'Nothing awaiting assignment',
              QueueTab.assigned => 'No assigned tickets',
              QueueTab.escalation => 'No escalations',
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
              QueueTab.unassigned => 'Every ticket has been picked up.',
              QueueTab.awaiting =>
                'No ticket has waited ${TaskItem.unassignedWaitMinutes} min for an engineer.',
              QueueTab.assigned =>
                'No Service Engineer is working a ticket right now.',
              QueueTab.escalation =>
                'Every ticket moved status in the last ${TaskItem.staleStatusHours}h.',
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

class _WebQueueHover extends StatefulWidget {
  const _WebQueueHover({required this.child});

  final Widget child;

  @override
  State<_WebQueueHover> createState() => _WebQueueHoverState();
}

class _WebQueueHoverState extends State<_WebQueueHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.09 : 0.04),
              blurRadius: _hover ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// 3-dots action menu for ticket queue cards.
/// Shows all available actions based on user role and task state.
class _TicketActionsMenu extends ConsumerWidget {
  const _TicketActionsMenu({
    required this.task,
    required this.handler,
    required this.onDeleted,
  });

  final TaskItem task;
  final TaskActionHandler handler;
  final VoidCallback onDeleted;

  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final actions = taskButtonsFor(task, user);
    // Filter out serviceReport since we'll show it separately
    final menuActions = actions
        .where((b) => b.action != TaskAction.serviceReport)
        .toList();

    // Add delete action if user can delete (Super Admin / Manager)
    final role = user?.role ?? UserRole.client;
    final canDelete = role == UserRole.superAdmin || role == UserRole.manager;

    return PopupMenuButton<TaskAction>(
      icon: const Icon(
        Icons.more_vert,
        color: Color(0xFF5A6B5E),
        size: 22,
      ),
      tooltip: 'More actions',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      itemBuilder: (context) => [
        // Header
        PopupMenuItem<TaskAction>(
          enabled: false,
          height: 42,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.settings, color: _green, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Actions',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14201A),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Service Report always first
        const PopupMenuItem<TaskAction>(
          value: TaskAction.serviceReport,
          height: 44,
          child: const _ActionMenuItem(
            icon: Icons.description_outlined,
            label: 'Service Report',
          ),
        ),
        // Action items
        for (final button in menuActions)
          PopupMenuItem<TaskAction>(
            value: button.action,
            height: 44,
            child: _ActionMenuItem(
              icon: button.action.icon,
              label: button.action.label,
              color: button.kind == TaskButtonKind.danger ? _danger : null,
            ),
          ),
        // Add delete if allowed and not already in the list
        if (canDelete &&
            !menuActions.any((b) => b.action == TaskAction.delete)) ...[
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<TaskAction>(
            value: TaskAction.delete,
            height: 44,
            child: const _ActionMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete Task',
              color: _danger,
            ),
          ),
        ],
      ],
      onSelected: (action) => handler.run(task, action, onDeleted: onDeleted),
    );
  }
}

/// Single menu item row with icon and label.
class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF3A4A3E);
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c,
            ),
          ),
        ),
      ],
    );
  }
}
