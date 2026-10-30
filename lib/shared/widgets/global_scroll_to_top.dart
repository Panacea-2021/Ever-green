import 'package:flutter/material.dart';

/// App-wide "back to top" control.
///
/// Wrap the root of the app with this widget. It listens to every
/// [ScrollNotification] that bubbles up from any descendant scrollable, shows
/// the button once the user has scrolled far enough, and scrolls the active
/// scrollable back to the top when tapped. No per-page changes are required.
class GlobalScrollToTop extends StatefulWidget {
  const GlobalScrollToTop({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalScrollToTop> createState() => _GlobalScrollToTopState();
}

class _GlobalScrollToTopState extends State<GlobalScrollToTop>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF106220);
  static const double _threshold = 280;

  final ValueNotifier<bool> _visible = ValueNotifier(false);
  ScrollPosition? _position;
  BuildContext? _scrollableContext;

  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _bobCurve = CurvedAnimation(
    parent: _bob,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _visible.dispose();
    _bob.dispose();
    super.dispose();
  }

  bool _handleNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;
    if (metrics.maxScrollExtent < _threshold) return false;
    if (metrics.viewportDimension < 200) return false;

    // ScrollNotification.metrics is usually an immutable FixedScrollMetrics,
    // so grab the live ScrollPosition from the scrollable's context instead.
    final context = notification.context;
    if (context != null) {
      _scrollableContext = context;
      try {
        _position = Scrollable.of(context).position;
      } catch (_) {
        if (metrics is ScrollPosition) _position = metrics;
      }
    }

    final nowVisible = metrics.pixels > _threshold;
    if (nowVisible != _visible.value) {
      _visible.value = nowVisible;
      if (nowVisible) {
        _bob.repeat(reverse: true);
      } else {
        _bob.stop();
        _bob.value = 0;
      }
    }
    return false;
  }

  void _scrollToTop() {
    ScrollPosition? position = _position;
    final context = _scrollableContext;
    if (context != null) {
      try {
        position = Scrollable.of(context).position;
      } catch (_) {}
    }
    if (position == null) return;
    _bob.animateTo(0.85, duration: const Duration(milliseconds: 140)).then((_) {
      if (_visible.value) _bob.repeat(reverse: true);
    });
    position.animateTo(
      0,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: _visible,
            builder: (context, visible, _) {
              return IgnorePointer(
                ignoring: !visible,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 24),
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: visible ? Offset.zero : const Offset(0, 0.3),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Semantics(
                          button: true,
                          label: 'Back to top',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _scrollToTop,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD7E6DA),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x2610391D),
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
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
                                    child: const CustomPaint(
                                      size: Size(18, 20),
                                      painter: _UpArrowPainter(color: _green),
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
            },
          ),
        ],
      ),
    );
  }
}

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

    canvas.drawLine(Offset(cx, bottom), Offset(cx, top + 1), paint);

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
