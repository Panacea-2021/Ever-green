import 'package:flutter/foundation.dart' show kIsWeb;
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
    this.queryItemBuilder,
  });

  final String title;
  final String searchHint;
  final AsyncValue<List<T>> items;
  final bool Function(T item, String query) matches;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;

  /// Shown when there is nothing to pick at all.
  final String emptyText;

  /// Optional first row for the typed search text (e.g. "Use 'Block C'"),
  /// shown whenever the search box isn't empty.
  final Widget? Function(BuildContext context, String query)? queryItemBuilder;

  @override
  State<PickerScaffold<T>> createState() => _PickerScaffoldState<T>();
}

class _PickerScaffoldState<T> extends State<PickerScaffold<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webBuild(context);
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

  Widget _webBuild(BuildContext context) {
    final count = widget.items.valueOrNull?.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8E3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -70,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFBFE3C6).withValues(alpha: 0.5),
                            const Color(0xFFBFE3C6).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final heading = Row(
                          children: [
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(
                                side: BorderSide(color: Color(0xFFE2E8E3)),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(context).pop(),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 20,
                                    color: Color(0xFF14201A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [pickerGreen, Color(0xFF0C4A18)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.checklist_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Text(
                                widget.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF14201A),
                                ),
                              ),
                            ),
                            if (count != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: pickerGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                        final search = SizedBox(
                          width: c.maxWidth < 760 ? double.infinity : 380,
                          child: _webSearch(),
                        );
                        if (c.maxWidth < 760) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [heading, const SizedBox(height: 14), search],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: heading),
                            const SizedBox(width: 16),
                            search,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _webSearch() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      cursorColor: pickerGreen,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9B9B9B)),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F8F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: pickerGreen, width: 1.4),
        ),
      ),
    );
  }

  /// Picker cards three, two or one per row, equal height within a row.
  Widget _webGrid(List<T> visible) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        const gap = 16.0;
        final rows = (visible.length + cols - 1) ~/ cols;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          itemCount: rows,
          itemBuilder: (context, r) {
            final cells = <Widget>[];
            for (var j = 0; j < cols; j++) {
              if (j > 0) cells.add(const SizedBox(width: gap));
              final k = r * cols + j;
              cells.add(
                Expanded(
                  child: k < visible.length
                      ? widget.itemBuilder(context, visible[k])
                      : const SizedBox.shrink(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells,
                ),
              ),
            );
          },
        );
      },
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
    final q = _query.trim().toLowerCase();
    final queryItem = q.isEmpty
        ? null
        : widget.queryItemBuilder?.call(context, _query.trim());
    if (all.isEmpty && queryItem == null) {
      return _message(Icons.inbox_outlined, widget.emptyText, '');
    }
    final visible =
        q.isEmpty ? all : all.where((i) => widget.matches(i, q)).toList();
    if (visible.isEmpty && queryItem == null) {
      return _message(
        Icons.search_off,
        'No matches',
        'Nothing matches "${_query.trim()}"',
      );
    }
    if (kIsWeb) {
      if (queryItem == null) return _webGrid(visible);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: queryItem,
          ),
          Expanded(child: _webGrid(visible)),
        ],
      );
    }
    final offset = queryItem == null ? 0 : 1;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: visible.length + offset,
      itemBuilder: (context, i) => i < offset
          ? queryItem!
          : widget.itemBuilder(context, visible[i - offset]),
    );
  }

  Widget _message(IconData icon, String title, String subtitle,
      {Widget? action,}) {
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
    this.imageUrl,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;
  final bool selected;
  final String? tag;

  /// Shown in place of [icon] when set; [icon] is the fallback if it fails.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kIsWeb ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kIsWeb && selected ? const Color(0xFFF3F9F4) : Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 18 : 20),
        border: Border.all(
          color: selected
              ? pickerGreen
              : (kIsWeb ? const Color(0xFFE2E8E3) : Colors.transparent),
          width: 1.4,
        ),
        boxShadow: [
          kIsWeb
              ? BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              : BoxShadow(
                  color: const Color(0xFFE0D9EE).withValues(alpha: 0.9),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kIsWeb ? 18 : 20),
          hoverColor: pickerGreen.withValues(alpha: 0.04),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(kIsWeb ? 16 : 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF0EA),
                    shape: BoxShape.circle,
                  ),
                  child: (imageUrl ?? '').isEmpty
                      ? Icon(icon, color: pickerGreen, size: 24)
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: pickerGreen, size: 24),
                        ),
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
