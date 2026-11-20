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
    this.lightSelected = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// Null hides the number (e.g. while the list is still loading).
  final int? count;

  /// When true, the selected tile uses a light tinted background with
  /// coloured text/border instead of the strong gradient fill.
  final bool lightSelected;
}

/// Filter options laid out as equal-width tiles: tinted icon, count and
/// label, with the selected tile filled in its accent colour.
class WebFilterTiles extends StatelessWidget {
  const WebFilterTiles({
    super.key,
    required this.options,
    this.minTileWidth,
  });

  final List<WebFilterOption> options;

  /// When set, tiles wrap into balanced rows of equal-width tiles once a
  /// single row would make each tile narrower than this. Null keeps the
  /// original single-row layout (used by modules with fewer tiles).
  final double? minTileWidth;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final minWidth = minTileWidth;
    if (minWidth == null) return _singleRow(options);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return _singleRow(options);
        final width = constraints.maxWidth;
        final fitting =
            ((width + _gap) / (minWidth + _gap)).floor().clamp(1, options.length);
        if (fitting >= options.length) return _singleRow(options);

        // Keep rows balanced: six tiles become 3 + 3 rather than 5 + 1.
        final columns = fitting >= 3 ? 3 : fitting;
        final tileWidth = (width - _gap * (columns - 1)) / columns;

        return Column(
          children: [
            for (var start = 0; start < options.length; start += columns) ...[
              if (start > 0) const SizedBox(height: _gap),
              Row(
                children: [
                  for (var i = start;
                      i < start + columns && i < options.length;
                      i++) ...[
                    if (i > start) const SizedBox(width: _gap),
                    SizedBox(
                      width: tileWidth,
                      child: _FilterTile(
                        key: ValueKey('web-filter-${options[i].label}'),
                        option: options[i],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _singleRow(List<WebFilterOption> options) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(
            child: _FilterTile(
              key: ValueKey('web-filter-${options[i].label}'),
              option: options[i],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterTile extends StatefulWidget {
  const _FilterTile({super.key, required this.option});

  final WebFilterOption option;

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
    final lightSel = sel && o.lightSelected;
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
            gradient: (sel && !lightSel)
                ? LinearGradient(
                    colors: [c, Color.lerp(c, Colors.black, 0.22)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: lightSel
                ? c.withValues(alpha: 0.12)
                : (sel ? null : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lightSel
                  ? c
                  : (sel
                      ? Colors.transparent
                      : (_hover ? c.withValues(alpha: 0.45) : WebTokens.line)),
              width: lightSel ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (sel ? c : Colors.black)
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
                  color: lightSel
                      ? c.withValues(alpha: 0.08)
                      : (sel
                          ? Colors.white.withValues(alpha: 0.12)
                          : c.withValues(alpha: 0.06)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: lightSel
                            ? c.withValues(alpha: 0.18)
                            : (sel
                                ? Colors.white.withValues(alpha: 0.2)
                                : c.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(o.icon, size: 21, color: lightSel ? c : (sel ? Colors.white : c)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.count == null ? '–' : '${o.count}',
                            style: TextStyle(
                              fontFamily: WebTokens.fontFamily,
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: lightSel ? c : (sel ? Colors.white : WebTokens.ink),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            o.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: WebTokens.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: lightSel
                                  ? c
                                  : (sel
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : WebTokens.body),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sel)
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: lightSel ? c : Colors.white,
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
