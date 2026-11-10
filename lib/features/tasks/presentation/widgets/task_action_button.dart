import 'package:flutter/material.dart';

import 'task_workflow.dart';

/// A compact pill action button with an icon, press-scale animation and a
/// subtle shadow, used for the role-based task actions.
class TaskActionButton extends StatefulWidget {
  const TaskActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.kind = TaskButtonKind.outline,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final TaskButtonKind kind;

  @override
  State<TaskActionButton> createState() => _TaskActionButtonState();
}

class _TaskActionButtonState extends State<TaskActionButton> {
  static const Color _green = Color(0xFF106220);
  static const Color _greenDark = Color(0xFF125420);
  static const Color _danger = Color(0xFFD32F2F);

  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final isFilled = kind == TaskButtonKind.filled;
    final isDanger = kind == TaskButtonKind.danger;

    final Color fg = isFilled
        ? Colors.white
        : isDanger
            ? _danger
            : _green;

    final Gradient? gradient = isFilled
        ? const LinearGradient(
            colors: [_greenDark, _green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final Border? border = isFilled
        ? null
        : Border.all(
            color: (isDanger ? _danger : _green).withValues(alpha: 0.55),
            width: 1.3,
          );

    final List<BoxShadow> shadow = isFilled
        ? [
            BoxShadow(
              color: _green.withValues(alpha: _pressed ? 0.18 : 0.30),
              blurRadius: _pressed ? 6 : 12,
              offset: Offset(0, _pressed ? 2 : 5),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isFilled ? null : Colors.white,
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
