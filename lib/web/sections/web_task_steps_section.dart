import 'package:flutter/material.dart';

/// Task-steps band (Figma node 98-140): a dark night-building photo with two
/// app phone mockups floating above, and three steps across the bottom —
/// "Create a task", "Service Engineer will come", "Get it done after approval".
///
/// Rendered from the exact Figma section export so it matches 1:1. The image's
/// natural ratio is 1440×809, so we preserve it with an AspectRatio to avoid
/// cropping the phones or text.
class WebTaskStepsSection extends StatelessWidget {
  const WebTaskStepsSection({super.key});

  static const double _ratio = 1440 / 809;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _ratio,
      child: Image.asset(
        'assets/images/web_tasksteps_full.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFF0E1512),
        ),
      ),
    );
  }
}
