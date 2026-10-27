import 'package:flutter/material.dart';

/// Custom menu icon matching Figma design
/// White circular background with shadow and custom 3-line hamburger icon
class CustomMenuIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  /// When true, renders a translucent "glass" circle with white lines so the
  /// icon reads on top of imagery/video. Defaults to the solid-white look.
  final bool light;

  const CustomMenuIcon({
    super.key,
    this.onTap,
    this.size = 42,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: 0.22) : Colors.white,
          shape: BoxShape.circle,
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: 0.35))
              : null,
          boxShadow: light
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(14, 12),
            painter: _MenuIconPainter(light ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}

class _MenuIconPainter extends CustomPainter {
  final Color color;
  _MenuIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Top line (full width)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      paint,
    );

    // Middle line (full width)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Bottom line (half width, right-aligned)
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MenuIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
