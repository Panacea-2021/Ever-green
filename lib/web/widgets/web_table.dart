import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// A lightweight data table for the web dashboard: a header row + body rows
/// built from flexible cell widgets. Not tied to any model, so any screen can
/// render its own columns. Rows highlight on hover and can be tapped.
class WebTable extends StatelessWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.emptyText = 'Nothing to show.',
  });

  /// Header labels with their flex weights.
  final List<WebColumn> columns;

  /// Each row is a list of cell widgets, matching [columns] length/order.
  final List<List<Widget>> rows;

  final ValueChanged<int>? onRowTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: const BoxDecoration(
            color: WebTokens.cream,
            border: Border(
              top: BorderSide(color: WebTokens.line),
              bottom: BorderSide(color: WebTokens.line),
            ),
          ),
          child: Row(
            children: [
              for (final c in columns)
                Expanded(
                  flex: c.flex,
                  child: Text(
                    c.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: WebTokens.faint,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text(emptyText, style: WebTokens.bodyText(13.5)),
          )
        else
          for (var i = 0; i < rows.length; i++)
            _WebTableRow(
              cells: rows[i],
              columns: columns,
              last: i == rows.length - 1,
              onTap: onRowTap == null ? null : () => onRowTap!(i),
            ),
      ],
    );
  }
}

class _WebTableRow extends StatefulWidget {
  const _WebTableRow({
    required this.cells,
    required this.columns,
    required this.last,
    this.onTap,
  });

  final List<Widget> cells;
  final List<WebColumn> columns;
  final bool last;
  final VoidCallback? onTap;

  @override
  State<_WebTableRow> createState() => _WebTableRowState();
}

class _WebTableRowState extends State<_WebTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _hover && widget.onTap != null
                ? WebTokens.mintSoft.withValues(alpha: 0.55)
                : Colors.transparent,
            border: widget.last
                ? null
                : const Border(bottom: BorderSide(color: WebTokens.line)),
          ),
          child: Row(
            children: [
              for (var j = 0; j < widget.columns.length; j++)
                Expanded(
                  flex: widget.columns[j].flex,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.cells[j],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebColumn {
  const WebColumn(this.label, {this.flex = 1});
  final String label;
  final int flex;
}

/// Convenience cell: plain text with the dashboard's body style.
class WebCellText extends StatelessWidget {
  const WebCellText(
    this.text, {
    super.key,
    this.bold = false,
    this.color,
    this.subtitle,
  });

  final String text;
  final bool bold;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.isEmpty ? '-' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: WebTokens.bodyText(
        13.5,
        color: color ?? WebTokens.ink,
        weight: bold ? FontWeight.w700 : FontWeight.w500,
        h: 1.3,
      ),
    );
    final main = text.length > 18
        ? Tooltip(
            message: text,
            waitDuration: const Duration(milliseconds: 400),
            child: label,
          )
        : label;
    if (subtitle == null || subtitle!.isEmpty) return main;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        const SizedBox(height: 2),
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WebTokens.bodyText(11.5, color: WebTokens.faint, h: 1.3),
        ),
      ],
    );
  }
}

/// Convenience cell: a colored status/priority pill.
class WebCellPill extends StatelessWidget {
  const WebCellPill(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
