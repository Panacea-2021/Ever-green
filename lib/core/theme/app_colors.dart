import 'package:flutter/material.dart';

/// EverGreen brand colors - green-based theme
class AppColors {
  AppColors._();

  // Primary green palette (from Figma design)
  static const Color primary = Color(0xFF106220); // EverGreen Primary
  static const Color primaryLight = Color(0xFF2E7D32); // Light Green
  static const Color primaryDark = Color(0xFF0A4015); // Deep Green

  // Gradient colors for buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF106220),
      Color(0xFF0D5119),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradient with overlay (for buttons as per Figma)
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF106220),
      Color(0xFF106220),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Secondary palette
  static const Color secondary = Color(0xFF81C784); // Light Green
  static const Color secondaryLight = Color(0xFFA5D6A7);
  static const Color secondaryDark = Color(0xFF66BB6A);

  // Accent colors
  static const Color accent = Color(0xFF00BFA5); // Teal accent
  static const Color accentLight = Color(0xFF64FFDA);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Other colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color overlay = Color(0x80000000);
}
