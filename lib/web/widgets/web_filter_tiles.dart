import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// One option in a [WebFilterTiles] row.
class WebFilterOption {
  const WebFilterOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// Null hides the number (e.g. while the list is still loading).
  final int? count;
}

/// Filter options laid out as equal-width tiles: tinted icon, count and
/// label, with the selected tile filled in its accent colour.
class WebFilterTiles extends StatelessWidget {
  const WebFilterTiles({
    super.key,
    required this.options,
    this.unselectedColor = Colors.white,
    this.selectedColor,
    this.minTileWidth,
    this.scrollController,
    this.compact = false,
  }) : assert(minTileWidth == null || scrollController != null);

  final List<WebFilterOption> options;
  final Color unselectedColor;
  final Color? selectedColor;
  final double? minTileWidth;
  final ScrollController? scrollController;
  final bool compact;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (options.isEmpty) return const SizedBox.shrink();
        if (minTileWidth != null) {
          final minRowWidth =
              minTileWidth! * options.length + _gap * (options.length - 1);
          final rowWidth =
              c.maxWidth < minRowWidth ? minRowWidth : c.maxWidth;
          final tileWidth =
              (rowWidth - _gap * (options.length - 1)) / options.length;
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: rowWidth,
                child: Row(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: tileWidth,
                        child: _FilterTile(
                          key: ValueKey('web-filter-${options[i].label}'),
                          option: options[i],
                          unselectedColor: unselectedColor,
                          selectedColor: selectedColor,
                          compact: compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        final cols = c.maxWidth >= 1100
            ? options.length
            : c.maxWidth >= 720
                ? (options.length > 4 ? 3 : options.length)
                : 2;
        final tileWidth = (c.maxWidth - _gap * (cols - 1)) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final o in options)
              SizedBox(
                width: tileWidth,
                child: _FilterTile(
                  key: ValueKey('web-filter-${o.label}'),
                  option: o,
                  unselectedColor: unselectedColor,
                  selectedColor: selectedColor,
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterTile extends StatefulWidget {
  const _FilterTile({
    super.key,
    required this.option,
    required this.unselectedColor,
    this.selectedColor,
    this.compact = false,
  });

  final WebFilterOption option;
  final Color unselectedColor;
  final Color? selectedColor;
  final bool compact;

  @override
  State<_FilterTile> createState() => _FilterTileState();
}

class _FilterTileState extends State<_FilterTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    final c = o.color;
    final sel = o.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: o.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover && !sel ? -2 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(
                    colors: [
                      widget.selectedColor ?? c,
                      Color.lerp(widget.selectedColor ?? c, Colors.black, 0.22)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel ? null : widget.unselectedColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: sel
                  ? Colors.transparent
                  : (_hover ? c.withValues(alpha: 0.45) : WebTokens.line),
            ),
            boxShadow: [
              BoxShadow(
                color: (sel ? (widget.selectedColor ?? c) : Colors.black)
                    .withValues(alpha: sel ? 0.28 : (_hover ? 0.08 : 0.04)),
                blurRadius: sel || _hover ? 20 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -26,
                child: Icon(
                  o.icon,
                  size: 78,
                  color: sel
                      ? Colors.white.withValues(alpha: 0.12)
                      : c.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.compact ? 10 : 14,
                  widget.compact ? 10 : 14,
                  widget.compact ? 10 : 14,
                  widget.compact ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: widget.compact ? 34 : 42,
                      height: widget.compact ? 34 : 42,
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withValues(alpha: 0.2)
                            : c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(widget.compact ? 10 : 13),
                      ),
                      child: Icon(o.icon, size: widget.compact ? 17 : 21, color: sel ? Colors.white : c),
                    ),
                    SizedBox(width: widget.compact ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.count == null ? '–' : '${o.count}',
                            style: TextStyle(
                              fontFamily: WebTokens.fontFamily,
                              fontSize: widget.compact ? 17 : 21,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : WebTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            o.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: WebTokens.fontFamily,
                              fontSize: widget.compact ? 11 : 12.5,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : WebTokens.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sel)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
