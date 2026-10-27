import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../tasks/data/task_provider.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/widgets/task_list_card.dart';

/// Per-technician task view, backed by the live [taskProvider]. Shows the
/// selected technician's tasks grouped by status tabs, in the project design.
class TechnicianTasksScreen extends ConsumerStatefulWidget {
  final String? technicianId;
  final String? technicianName;

  const TechnicianTasksScreen({
    super.key,
    this.technicianId,
    this.technicianName,
  });

  @override
  ConsumerState<TechnicianTasksScreen> createState() =>
      _TechnicianTasksScreenState();
}

class _TechnicianTasksScreenState extends ConsumerState<TechnicianTasksScreen> {
  static const Color _green = Color(0xFF106220);
  int _selectedTab = 0;
  String _query = '';

  static const _tabs = <(String, TaskStatus)>[
    ('Open', TaskStatus.open),
    ('Hold', TaskStatus.hold),
    ('In Progress', TaskStatus.inProgress),
    ('Closed', TaskStatus.closed),
  ];

  @override
  Widget build(BuildContext context) {
    final name = widget.technicianName ?? '';
    final techId = int.tryParse(widget.technicianId ?? '');
    final async = ref.watch(taskItemsProvider);
    final all = ref.watch(taskProvider);

    // All tasks owned by this technician.
    final mine = all
        .where(
          (t) => techId != null
              ? t.technicianId == techId
              : t.hasAssignee && t.assignee == name,
        )
        .toList();

    final activeStatus = _tabs[_selectedTab].$2;
    final visible = mine.where((t) {
      if (t.status != activeStatus) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.equipment.toLowerCase().contains(q) ||
          t.companyName.toLowerCase().contains(q) ||
          t.ticketNo.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.priority.rank != b.priority.rank) {
          return b.priority.rank - a.priority.rank;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    int countFor(TaskStatus s) => mine.where((t) => t.status == s).length;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/home_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(name, mine.length),
                  _searchBar(),
                  _tabBar(countFor),
                  const SizedBox(height: 4),
                  Expanded(
                    child: all.isEmpty && async.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _green),
                          )
                        : RefreshIndicator(
                            color: _green,
                            onRefresh: () async {
                              ref.invalidate(tasksProvider);
                              await ref.read(tasksProvider.future);
                            },
                            child: visible.isEmpty
                                ? LayoutBuilder(
                                    builder: (_, c) => SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: SizedBox(
                                        height: c.maxHeight,
                                        child: all.isEmpty && async.hasError
                                            ? _error(async.error)
                                            : _empty(),
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
                                    itemCount: visible.length,
                                    itemBuilder: (_, i) =>
                                        TaskListCard(task: visible[i]),
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

  Widget _header(String name, int total) {
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
              child: const Icon(Icons.arrow_back,
                  size: 20, color: Color(0xFF1F1F1F),),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Service Engineer Tasks' : name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  '$total task${total == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFEBF0EA),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search tasks',
            prefixIcon: Icon(Icons.search, color: Color(0xFF9B9B9B)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _tabBar(int Function(TaskStatus) countFor) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _selectedTab == i;
          final count = countFor(_tabs[i].$2);
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? _green : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '${_tabs[i].$1} ($count)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF545454),
                ),
              ),
            ),
          );
        },
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

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No ${_tabs[_selectedTab].$1.toLowerCase()} tasks',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
