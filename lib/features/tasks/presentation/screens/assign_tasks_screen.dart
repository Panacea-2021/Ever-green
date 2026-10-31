import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../widgets/task_list_card.dart';
import '../widgets/task_workflow.dart';

/// Manager / admin screen for assigning unassigned tickets to technicians.
/// Backed by the live [taskProvider]; the assign action updates real data.
class AssignTasksScreen extends ConsumerStatefulWidget {
  const AssignTasksScreen({super.key});

  @override
  ConsumerState<AssignTasksScreen> createState() => _AssignTasksScreenState();
}

class _AssignTasksScreenState extends ConsumerState<AssignTasksScreen> {
  static const Color _green = Color(0xFF106220);
  String _query = '';
  bool _onlyUnassigned = true;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskItemsProvider);
    final all = ref.watch(taskProvider);

    final visible = all.where((t) {
      if (t.isClosed) return false;
      if (_onlyUnassigned && t.hasAssignee) return false;
      return t.matchesQuery(_query);
    }).toList()
      ..sort((a, b) {
        if (a.priority.rank != b.priority.rank) {
          return b.priority.rank - a.priority.rank;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

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
                  _header(visible.length),
                  _searchBar(),
                  _filterRow(),
                  const SizedBox(height: 4),
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
                          : visible.isEmpty
                              ? LayoutBuilder(
                                  builder: (_, c) => SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: c.maxHeight,
                                      child: all.isEmpty && async.hasError
                                          ? Center(
                                              child: Text(
                                                '${async.error}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            )
                                          : _empty(),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: visible.length,
                                  itemBuilder: (_, i) => TaskListCard(
                                    task: visible[i],
                                    trailing: _assignButton(visible[i]),
                                  ),
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

  Widget _header(int count) {
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
              'Assign Tasks',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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

  Widget _filterRow() {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _green : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF545454),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          chip(
            'Unassigned',
            _onlyUnassigned,
            () => setState(() => _onlyUnassigned = true),
          ),
          const SizedBox(width: 8),
          chip(
            'All open',
            !_onlyUnassigned,
            () => setState(() => _onlyUnassigned = false),
          ),
        ],
      ),
    );
  }

  Widget _assignButton(TaskItem t) {
    final assigned = t.hasAssignee;
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _assignSheet(t),
        icon: Icon(
          assigned ? Icons.swap_horiz : Icons.person_add_alt_1,
          size: 16,
        ),
        label: Text(
          assigned ? 'Reassign' : 'Assign',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _onlyUnassigned ? 'No unassigned tasks' : 'No open tasks',
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

  void _assignSheet(TaskItem t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t.hasAssignee ? 'Reassign "${t.title}"' : 'Assign "${t.title}"',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TechnicianChoices(
              builder: (techs, stats) => Column(
                children: [
                  for (final tech in techs)
                    Builder(
                      builder: (_) {
                        final s = statsFor(tech, stats);
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
                          title: Text(
                            tech.name,
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                          subtitle: Text(
                            '${s.active} active task(s)',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: overloaded
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF6B6B6B),
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
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            if (overloaded) {
                              final ok =
                                  await _confirmOverload(tech.name, s.active);
                              if (ok != true || !mounted) return;
                            }
                            await runTaskAction(
                              context,
                              () => ref
                                  .read(taskActionsProvider)
                                  .assign(t, tech.backendId),
                              success: 'Assigned to ${tech.name}',
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
