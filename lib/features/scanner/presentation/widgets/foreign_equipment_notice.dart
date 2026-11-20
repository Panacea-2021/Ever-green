import 'package:flutter/material.dart';

import '../../../amcs/data/equipment_provider.dart';

/// Shown instead of equipment details when a client-side user scans or opens
/// equipment of a company they are not linked to.
class ForeignEquipmentNotice extends StatelessWidget {
  final String actionLabel;
  final VoidCallback onAction;

  const ForeignEquipmentNotice({
    super.key,
    required this.actionLabel,
    required this.onAction,
  });

  static const Color _red = Color(0xFFD32F2F);
  static const Color _green = Color(0xFF106220);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block, color: _red, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Access Restricted',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          foreignEquipmentMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
