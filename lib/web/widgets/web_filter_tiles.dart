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
  const WebFilterTiles({super.key, required this.options});

  final List<WebFilterOption> options;

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = options.length;
        final perRow = c.maxWidth >= 180.0 * n ? n : (c.maxWidth >= 560 ? 3 : 2);
        final width = (c.maxWidth - _gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final o in options)
              SizedBox(width: width, child: _FilterTile(option: o)),
          ],
        );
      },
    );
  }
}

class _FilterTile extends StatefulWidget {
  const _FilterTile({required this.option});

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
                    colors: [c, Color.lerp(c, Colors.black, 0.22)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: sel
                  ? Colors.transparent
                  : (_hover ? c.withValues(alpha: 0.45) : WebTokens.line),
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
                  color: sel
                      ? Colors.white.withValues(alpha: 0.12)
                      : c.withValues(alpha: 0.06),
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
                        color: sel
                            ? Colors.white.withValues(alpha: 0.2)
                            : c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(o.icon, size: 21, color: sel ? Colors.white : c),
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
                              fontSize: 12.5,
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
