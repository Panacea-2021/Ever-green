import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';

const _green = Color(0xFF106220);
const _issueTypeNameMax = 60;

/// The admin-managed name lists: issue types (picked when raising a ticket)
/// and service types (set on equipment).
enum ManagedTypeKind {
  issue('Issue Types', 'issue type', 'Issue type', 'issueType',
      'e.g. Installation', Icons.build_circle_outlined,),
  service('Service Types', 'service type', 'Service type', 'serviceType',
      'e.g. Chiller AMC', Icons.miscellaneous_services_outlined,);

  const ManagedTypeKind(
    this.title,
    this.noun,
    this.label,
    this.keyPrefix,
    this.hint,
    this.icon,
  );
  final String title;
  final String noun;
  final String label;
  final String keyPrefix;
  final String hint;
  final IconData icon;
}

typedef _TypeRow = ({int id, String name, bool isActive, bool builtIn});

/// Super Admin / Manager list of issue types used when raising tickets:
/// add new ones, rename, and turn them on or off. Inactive types stay on
/// existing tickets but can't be picked for new ones.
class IssueTypesScreen extends ConsumerStatefulWidget {
  const IssueTypesScreen({super.key, this.kind = ManagedTypeKind.issue});

  final ManagedTypeKind kind;

  @override
  ConsumerState<IssueTypesScreen> createState() => _IssueTypesScreenState();
}

/// Same screen for service types, which are set on equipment and shown when
/// raising a ticket for it.
class ServiceTypesScreen extends IssueTypesScreen {
  const ServiceTypesScreen({super.key}) : super(kind: ManagedTypeKind.service);
}

class _IssueTypesScreenState extends ConsumerState<IssueTypesScreen> {
  final Set<int> _busy = {};

  ManagedTypeKind get _kind => widget.kind;
  bool get _isIssue => _kind == ManagedTypeKind.issue;

  void _refresh() {
    if (_isIssue) {
      ref.invalidate(allIssueTypesProvider);
      ref.invalidate(issueTypesProvider);
    } else {
      ref.invalidate(allServiceTypesProvider);
      ref.invalidate(serviceTypesProvider);
    }
  }

  AsyncValue<List<_TypeRow>> _watchRows() => _isIssue
      ? ref.watch(allIssueTypesProvider).whenData(
            (l) => [
              for (final t in l)
                (
                  id: t.id,
                  name: t.name,
                  isActive: t.isActive,
                  builtIn: t.callType != null,
                ),
            ],
          )
      : ref.watch(allServiceTypesProvider).whenData(
            (l) => [
              for (final t in l)
                (id: t.id, name: t.name, isActive: t.isActive, builtIn: false),
            ],
          );

  Future<void> _create(String name) {
    final repo = ref.read(evergreenRepositoryProvider);
    return _isIssue ? repo.createIssueType(name) : repo.createServiceType(name);
  }

  Future<void> _update(int id, {String? name, bool? isActive}) {
    final repo = ref.read(evergreenRepositoryProvider);
    return _isIssue
        ? repo.updateIssueType(id, name: name, isActive: isActive)
        : repo.updateServiceType(id, name: name, isActive: isActive);
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

  Future<void> _edit([_TypeRow? existing]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _IssueTypeNameDialog(kind: _kind, initial: existing?.name),
    );
    if (name == null || name == existing?.name) return;
    try {
      if (existing == null) {
        await _create(name);
      } else {
        await _update(existing.id, name: name);
      }
      _refresh();
      _snack('${_kind.label} ${existing == null ? 'added' : 'renamed'}');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _toggle(_TypeRow type, bool active) async {
    setState(() => _busy.add(type.id));
    try {
      await _update(type.id, isActive: active);
      _refresh();
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(type.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _watchRows();
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        key: Key(_isIssue ? 'addIssueType' : 'addServiceType'),
        backgroundColor: _green,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New ${_kind.title.substring(0, _kind.title.length - 1)}',
          style: const TextStyle(
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
                        'Could not load ${_kind.noun}s\n$e',
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
                  onRefresh: () async => _refresh(),
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(child: Text('No ${_kind.noun}s yet')),
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
          Expanded(
            child: Text(
              _kind.title,
              style: const TextStyle(
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

  Widget _tile(_TypeRow type) {
    final busy = _busy.contains(type.id);
    return Container(
      key: Key('${_kind.keyPrefix}-${type.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: type.isActive ? const Color(0xFFEBF0EA) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            _kind.icon,
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
                    if (type.builtIn) 'Built-in',
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
  final ManagedTypeKind kind;
  final String? initial;
  const _IssueTypeNameDialog({required this.kind, this.initial});

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
      title: Text(
        '${widget.initial == null ? 'New' : 'Rename'} ${widget.kind.noun}',
      ),
      content: TextField(
        key: Key('${widget.kind.keyPrefix}NameField'),
        controller: _controller,
        autofocus: true,
        maxLength: _issueTypeNameMax,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: widget.kind.hint),
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
