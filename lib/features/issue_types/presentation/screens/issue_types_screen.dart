import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';

const _green = Color(0xFF106220);
const _issueTypeNameMax = 60;

/// Super Admin / Manager list of issue (service) types used when raising
/// tickets: add new ones, rename, and turn them on or off. Inactive types
/// stay on existing tickets but can't be picked for new ones.
class IssueTypesScreen extends ConsumerStatefulWidget {
  const IssueTypesScreen({super.key});

  @override
  ConsumerState<IssueTypesScreen> createState() => _IssueTypesScreenState();
}

class _IssueTypesScreenState extends ConsumerState<IssueTypesScreen> {
  final Set<int> _busy = {};

  void _refresh() {
    ref.invalidate(allIssueTypesProvider);
    ref.invalidate(issueTypesProvider);
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

  Future<void> _edit([IssueType? existing]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _IssueTypeNameDialog(initial: existing?.name),
    );
    if (name == null || name == existing?.name) return;
    final repo = ref.read(evergreenRepositoryProvider);
    try {
      if (existing == null) {
        await repo.createIssueType(name);
      } else {
        await repo.updateIssueType(existing.id, name: name);
      }
      _refresh();
      _snack(existing == null ? 'Issue type added' : 'Issue type renamed');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _toggle(IssueType type, bool active) async {
    setState(() => _busy.add(type.id));
    try {
      await ref
          .read(evergreenRepositoryProvider)
          .updateIssueType(type.id, isActive: active);
      _refresh();
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(type.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(allIssueTypesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addIssueType'),
        backgroundColor: _green,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Issue Type',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: types.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _green),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load issue types\n$e',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (list) => RefreshIndicator(
                  color: _green,
                  onRefresh: () => ref.refresh(allIssueTypesProvider.future),
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No issue types yet')),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _tile(list[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'Issue Types',
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

  Widget _tile(IssueType type) {
    final busy = _busy.contains(type.id);
    return Container(
      key: Key('issueType-${type.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: type.isActive ? const Color(0xFFEBF0EA) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.build_circle_outlined,
            color: type.isActive ? _green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        type.isActive ? const Color(0xFF1F1F1F) : Colors.grey,
                  ),
                ),
                Text(
                  [
                    if (type.callType != null) 'Built-in',
                    type.isActive ? 'Active' : 'Inactive',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: busy ? null : () => _edit(type),
          ),
          Switch(
            value: type.isActive,
            activeThumbColor: _green,
            onChanged: busy ? null : (v) => _toggle(type, v),
          ),
        ],
      ),
    );
  }
}

class _IssueTypeNameDialog extends StatefulWidget {
  final String? initial;
  const _IssueTypeNameDialog({this.initial});

  @override
  State<_IssueTypeNameDialog> createState() => _IssueTypeNameDialogState();
}

class _IssueTypeNameDialogState extends State<_IssueTypeNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    return AlertDialog(
      title:
          Text(widget.initial == null ? 'New issue type' : 'Rename issue type'),
      content: TextField(
        key: const Key('issueTypeNameField'),
        controller: _controller,
        autofocus: true,
        maxLength: _issueTypeNameMax,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Installation'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _green),
          onPressed: name.isEmpty ? null : () => Navigator.pop(context, name),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
