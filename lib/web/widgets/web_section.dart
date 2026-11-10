import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';

/// A full-width section band with an optional background, that centers its
/// [child] within [WebTokens.maxContentWidth] and applies a responsive
/// horizontal gutter + vertical padding. The building block for every
/// landing-page section.
class WebSection extends StatelessWidget {
  const WebSection({
    super.key,
    required this.child,
    this.background,
    this.gradient,
    this.verticalPadding = 80,
    this.maxWidth = WebTokens.maxContentWidth,
  });

  final Widget child;
  final Color? background;
  final Gradient? gradient;
  final double verticalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final gutter = WebTokens.gutter(w);
    final vPad =
        w < WebTokens.mobileMax ? verticalPadding * 0.6 : verticalPadding;

    return Container(
      width: double.infinity,
      color: gradient == null ? background : null,
      decoration: gradient != null ? BoxDecoration(gradient: gradient) : null,
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: vPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Pill button used across the website (filled green or outline).
class WebButton extends StatefulWidget {
  const WebButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.icon,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  /// Light variant for use on dark/hero backgrounds (outline turns white).
  final bool light;

  @override
  State<WebButton> createState() => _WebButtonState();
}

class _WebButtonState extends State<WebButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    final fg = filled
        ? Colors.white
        : widget.light
            ? Colors.white
            : WebTokens.green;
    final borderColor = widget.light ? Colors.white70 : WebTokens.green;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: filled
                ? (_hover ? WebTokens.greenDark : WebTokens.green)
                : (_hover
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: borderColor, width: 1.4),
            boxShadow: filled && _hover
                ? [
                    BoxShadow(
                      color: WebTokens.green.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
