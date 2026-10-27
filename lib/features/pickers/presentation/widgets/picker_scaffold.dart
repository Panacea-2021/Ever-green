import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Color pickerGreen = Color(0xFF106220);

/// Full-page searchable list shared by the company and equipment pickers:
/// design header, pill search bar, and loading / error / empty states.
class PickerScaffold<T> extends StatefulWidget {
  const PickerScaffold({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.matches,
    required this.itemBuilder,
    required this.onRetry,
    required this.emptyText,
  });

  final String title;
  final String searchHint;
  final AsyncValue<List<T>> items;
  final bool Function(T item, String query) matches;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;

  /// Shown when there is nothing to pick at all.
  final String emptyText;

  @override
  State<PickerScaffold<T>> createState() => _PickerScaffoldState<T>();
}

class _PickerScaffoldState<T> extends State<PickerScaffold<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _searchBar(),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          ),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: TextField(
        autofocus: false,
        onChanged: (v) => setState(() => _query = v),
        cursorColor: pickerGreen,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9B9B9B)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: pickerGreen, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final items = widget.items;
    if (!items.hasValue) {
      if (items.hasError) {
        return _message(
          Icons.cloud_off_outlined,
          'Couldn\'t load the list',
          '${items.error}',
          action: TextButton(
            onPressed: widget.onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontFamily: 'Montserrat', color: pickerGreen),
            ),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: pickerGreen),
      );
    }
    final all = items.value!;
    if (all.isEmpty) {
      return _message(Icons.inbox_outlined, widget.emptyText, '');
    }
    final q = _query.trim().toLowerCase();
    final visible =
        q.isEmpty ? all : all.where((i) => widget.matches(i, q)).toList();
    if (visible.isEmpty) {
      return _message(
        Icons.search_off,
        'No matches',
        'Nothing matches "${_query.trim()}"',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: visible.length,
      itemBuilder: (context, i) => widget.itemBuilder(context, visible[i]),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Color(0xFF9B9B9B),
                ),
              ),
            ],
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}

/// A selectable list card in the design's white rounded-card style.
class PickerCard extends StatelessWidget {
  const PickerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
    required this.onTap,
    this.selected = false,
    this.tag,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;
  final bool selected;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? pickerGreen : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.9),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF0EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: pickerGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF0EA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag!,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: pickerGreen,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      for (final line in lines)
                        if (line.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              line,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  color: selected ? pickerGreen : const Color(0xFF9B9B9B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
