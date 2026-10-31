import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// A white web card with a title row (optional count badge and action) above
/// its [child].
class WebPanel extends StatelessWidget {
  const WebPanel({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.actionLabel,
    this.onAction,
    this.padBody = false,
  });

  final String title;
  final Widget child;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Adds inner padding around [child] (lists); tables run edge to edge.
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTokens.line),
        boxShadow: WebTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTokens.heading(16),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: WebTokens.mintSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: WebTokens.bodyText(
                        11.5,
                        color: WebTokens.green,
                        weight: FontWeight.w700,
                        h: 1.3,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: WebTokens.green,
                      textStyle: const TextStyle(
                        fontFamily: WebTokens.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(actionLabel!),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (padBody)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}
