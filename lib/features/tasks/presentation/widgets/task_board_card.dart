import 'package:flutter/material.dart';

import '../../domain/models/task_item.dart';
import 'task_workflow.dart' show taskImage;

/// Task Board card from the new design: large image, title + priority star,
/// location / status row, Equipment / Company / S.No rows, Created At, and
/// the Report + Assign buttons. Individual tickets show the contact in place
/// of the company and the address in place of the equipment.
class TaskBoardCard extends StatelessWidget {
  const TaskBoardCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onReport,
    this.onAssign,
    this.onToggleStar,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onReport;

  /// Null hides Assign / Reassign and Report takes the full width.
  final VoidCallback? onAssign;

  /// Null makes the star read-only.
  final VoidCallback? onToggleStar;

  static const Color _green = Color(0xFF106220);
  static const Color _darkGreen = Color(0xFF125420);
  static const Color _red = Color(0xFFD32F2F);
  static const String _fallbackImage = 'assets/images/task_img_1.png';

  static String formatDate(DateTime date) {
    final d = date.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = task;
    final isHighPriority =
        t.priority == TaskPriority.high || t.priority == TaskPriority.critical;
    final party = t.isIndividual ? t.contactName : t.companyName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 17),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(color: Color(0xFFE0D9EE), blurRadius: 32, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _image(t),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: -0.51,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _star(isHighPriority),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: _darkGreen, size: 16),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 70),
                                child: Text(
                                  party.isEmpty ? '-' : party,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _darkGreen,
                                    letterSpacing: -0.42,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (t.isIndividual) _pill('Individual', dot: false),
                          _pill(t.lifecycleLabel),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (t.isIndividual) ...[
                        _infoRow('Address', t.address),
                        const SizedBox(height: 4),
                        _infoRow('Contact', t.contactName),
                      ] else ...[
                        _infoRow('Equipment', t.equipment),
                        const SizedBox(height: 4),
                        _infoRow('Company', t.companyName),
                      ],
                      const SizedBox(height: 4),
                      _infoRow('S.No', t.ticketNo),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: 'Created At : ',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                  TextSpan(
                    text: formatDate(t.createdAt),
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            if (t.isOverdue()) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: _red),
                  const SizedBox(width: 5),
                  Text(
                    'Overdue by ${-t.hoursToSla()}h',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _red,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _button(
                    'Report',
                    filled: true,
                    onTap: onReport,
                  ),
                ),
                if (onAssign != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _button(
                      t.hasAssignee ? 'Reassign' : 'Assign',
                      filled: false,
                      onTap: onAssign!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(TaskItem t) {
    final fallback = Image.asset(
      _fallbackImage,
      width: 108,
      height: 135,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.build, size: 40, color: Colors.grey.shade400),
      ),
    );
    final url = t.imageUrl;
    final isPhoto = url.startsWith('http://') || url.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 108,
        height: 135,
        child: isPhoto ? taskImage(url, fallback: fallback) : fallback,
      ),
    );
  }

  Widget _star(bool filled) {
    final icon = Icon(
      filled ? Icons.star : Icons.star_border,
      color: filled ? Colors.amber : Colors.grey,
      size: 24,
    );
    if (onToggleStar == null) {
      return Padding(padding: const EdgeInsets.only(left: 4), child: icon);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleStar,
      child: Padding(padding: const EdgeInsets.only(left: 4), child: icon),
    );
  }

  Widget _pill(String label, {bool dot = true}) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0EA),
        borderRadius: BorderRadius.circular(48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: _darkGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Icon(Icons.description_outlined, color: Colors.black.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: value.isEmpty ? '-' : value,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _button(String label, {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? _green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: _green, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : _green,
          ),
        ),
      ),
    );
  }
}
