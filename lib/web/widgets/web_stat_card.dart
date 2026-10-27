import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// A KPI tile for the web dashboard: icon chip, big value, label, and an
/// optional trend/sub caption. Hover lifts the card slightly.
class WebStatCard extends StatefulWidget {
  const WebStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;

  @override
  State<WebStatCard> createState() => _WebStatCardState();
}

class _WebStatCardState extends State<WebStatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _hover ? WebTokens.cardShadow : WebTokens.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 22),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 18),
            Text(widget.value, style: WebTokens.display(30)),
            const SizedBox(height: 4),
            Text(widget.label, style: WebTokens.bodyText(13.5)),
            if (widget.caption != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.caption!,
                style: WebTokens.bodyText(
                  12,
                  color: widget.accent,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
