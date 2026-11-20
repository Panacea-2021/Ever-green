import 'package:flutter/material.dart';

/// Floating "back to top" control.
///
/// Drop it into a [Stack] above a scrollable that uses [controller]. It stays
/// hidden until the user scrolls past [threshold], then fades/slides in and
/// animates the scroll position back to the top when tapped.
class ScrollToTopButton extends StatefulWidget {
  const ScrollToTopButton({
    super.key,
    required this.controller,
    this.threshold = 280,
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.only(right: 24, bottom: 24),
  });

  /// Controller of the scrollable this button drives.
  final ScrollController controller;

  /// How far the user must scroll before the button appears.
  final double threshold;

  /// Where the button sits inside its [Stack].
  final Alignment alignment;

  /// Gap between the button and the edges of the [Stack].
  final EdgeInsets margin;

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF106220);

  bool _visible = false;
  bool _hover = false;

  /// Gentle repeating bob that nudges the arrow upwards.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _bobCurve = CurvedAnimation(
    parent: _bob,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScroll);
    _handleScroll();
  }

  @override
  void didUpdateWidget(covariant ScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleScroll);
      widget.controller.addListener(_handleScroll);
      _handleScroll();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    _bob.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final visible = widget.controller.offset > widget.threshold;
    if (visible != _visible) {
      setState(() => _visible = visible);
      // Only keep the loop running while the button is on screen.
      if (visible) {
        _bob.repeat(reverse: true);
      } else {
        _bob.stop();
        _bob.value = 0;
      }
    }
  }

  void _scrollToTop() {
    if (!widget.controller.hasClients) return;
    // Quick "push off" bounce before the page starts moving.
    _bob.animateTo(0.85, duration: const Duration(milliseconds: 140)).then((_) {
      if (mounted && _visible) _bob.repeat(reverse: true);
    });
    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: widget.margin,
        child: IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Semantics(
                button: true,
                label: 'Back to top',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  child: GestureDetector(
                    onTap: _scrollToTop,
                    child: AnimatedScale(
                      scale: _hover ? 1.07 : 1,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hover ? _green : Colors.white,
                          border: Border.all(
                            color: _hover ? _green : const Color(0xFFD7E6DA),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _hover
                                  ? const Color(0x4D106220)
                                  : const Color(0x2610391D),
                              blurRadius: _hover ? 20 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _bobCurve,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, -2.5 * _bobCurve.value),
                              child: child,
                            ),
                            child: CustomPaint(
                              size: const Size(18, 20),
                              painter: _UpArrowPainter(
                                color: _hover ? Colors.white : _green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded "↑" glyph drawn by hand so it keeps the brand look instead of the
/// generic material icon.
class _UpArrowPainter extends CustomPainter {
  const _UpArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    const top = 1.5;
    final bottom = size.height - 1.5;

    // Shaft.
    canvas.drawLine(Offset(cx, bottom), Offset(cx, top + 1), paint);

    // Arrow head.
    final head = Path()
      ..moveTo(cx - size.width * 0.36, top + size.height * 0.34)
      ..lineTo(cx, top)
      ..lineTo(cx + size.width * 0.36, top + size.height * 0.34);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant _UpArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
