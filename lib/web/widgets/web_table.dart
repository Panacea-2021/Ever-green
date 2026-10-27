import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// A lightweight data table for the web dashboard: a header row + body rows
/// built from flexible cell widgets. Not tied to any model, so any screen can
/// render its own columns.
class WebTable extends StatelessWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  /// Header labels with their flex weights.
  final List<WebColumn> columns;

  /// Each row is a list of cell widgets, matching [columns] length/order.
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: WebTokens.softShadow,
      ),
      child: Column(
        children: [
          // Header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(
              color: WebTokens.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                for (final c in columns)
                  Expanded(
                    flex: c.flex,
                    child: Text(
                      c.label.toUpperCase(),
                      style: WebTokens.eyebrow(),
                    ),
                  ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text('Nothing to show.', style: WebTokens.bodyText(13.5)),
            )
          else
            for (var i = 0; i < rows.length; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  border: i == rows.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: WebTokens.line)),
                ),
                child: Row(
                  children: [
                    for (var j = 0; j < columns.length; j++)
                      Expanded(
                        flex: columns[j].flex,
                        child: rows[i][j],
                      ),
                  ],
                ),
              ),
        ],
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
  const WebCellText(this.text, {super.key, this.bold = false, this.color});
  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: WebTokens.bodyText(
        13.5,
        color: color ?? WebTokens.ink,
        weight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: WebTokens.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
