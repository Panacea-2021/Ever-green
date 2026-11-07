import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// EverGreen brand colors, with a web palette and preserved mobile values.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = kIsWeb ? Color(0xFF735A78) : Color(0xFF106220);
  static const Color primaryLight =
      kIsWeb ? Color(0xFF927B97) : Color(0xFF2E7D32);
  static const Color primaryDark =
      kIsWeb ? Color(0xFF51435B) : Color(0xFF0A4015);
  static const Color modulePrimaryDark =
      kIsWeb ? Color(0xFF51435B) : Color(0xFF125420);
  static const Color modulePrimaryDeep =
      kIsWeb ? Color(0xFF3D3544) : Color(0xFF0D5119);
  static const Color modulePrimaryTitle =
      kIsWeb ? Color(0xFF51435B) : Color(0xFF278245);
  static const Color modulePrimaryTitleDark =
      kIsWeb ? Color(0xFF51435B) : Color(0xFF11682E);
  static const Color modulePrimarySoft =
      kIsWeb ? Color(0xFFF0EBF3) : Color(0xFFEBF0EA);
  static const Color moduleAccent =
      kIsWeb ? Color(0xFF5A8F87) : Color(0xFF2E7D32);

  // Gradient colors for buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      kIsWeb ? Color(0xFF735A78) : Color(0xFF106220),
      kIsWeb ? Color(0xFF51435B) : Color(0xFF0D5119),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradient with overlay (for buttons as per Figma)
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      kIsWeb ? Color(0xFF735A78) : Color(0xFF106220),
      kIsWeb ? Color(0xFF735A78) : Color(0xFF106220),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Secondary palette
  static const Color secondary = kIsWeb ? Color(0xFF5A8F87) : Color(0xFF81C784);
  static const Color secondaryLight =
      kIsWeb ? Color(0xFFA8CEC4) : Color(0xFFA5D6A7);
  static const Color secondaryDark =
      kIsWeb ? Color(0xFF40776F) : Color(0xFF66BB6A);

  // Accent colors
  static const Color accent = kIsWeb ? Color(0xFFC08B4B) : Color(0xFF00BFA5);
  static const Color accentLight =
      kIsWeb ? Color(0xFFE7D1AE) : Color(0xFF64FFDA);

  // Background colors
  static const Color backgroundLight =
      kIsWeb ? Color(0xFFF7F6F2) : Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimaryLight =
      kIsWeb ? Color(0xFF30383A) : Color(0xFF212121);
  static const Color textSecondaryLight =
      kIsWeb ? Color(0xFF626B6A) : Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Other colors
  static const Color divider = kIsWeb ? Color(0xFFE9E5DC) : Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color overlay = Color(0x80000000);
}
