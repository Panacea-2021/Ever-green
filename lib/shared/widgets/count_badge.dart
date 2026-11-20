import 'package:flutter/material.dart';

const _green = Color(0xFF11682E);

/// Small rounded count pill. [onDark] for use on a filled green chip.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.onDark = false});

  final int count;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.25)
            : _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white : _green,
        ),
      ),
    );
  }
}

/// "Label  [count]" heading above a filtered list (Users, Companies, Tasks).
class CountHeader extends StatelessWidget {
  const CountHeader({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
