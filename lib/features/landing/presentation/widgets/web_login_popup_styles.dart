import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Visual styles for the website sign-in popup (`web_login_popup.dart`).
abstract class WebLoginPopupStyles {
  // Colors
  static const green = Color(0xFF0B5D1E);
  static const accentGreen = Color(0xFF6BD35A);
  static const featureBadge = Color(0xFF138A2E);
  static const brandTint = Color(0xFF04230C);
  static const titleText = Color(0xFF111827);
  static const subtitleText = Color(0xFF8A8F98);
  static const hintText = Color(0xFF9CA3AF);
  static const iconMuted = Color(0xFF6B7280);
  static const fieldBorder = Color(0xFFE5E7EB);
  static const closeButton = Color(0xFFF1F2F4);

  // Layout
  static const wideBreakpoint = 820.0;
  static const maxWideWidth = 960.0;
  static const maxNarrowWidth = 460.0;
  static const maxWideHeight = 620.0;
  static const maxNarrowHeight = 560.0;
  static const cardRadius = 24.0;
  static const fieldRadius = 14.0;
  static const buttonHeight = 56.0;

  static const brandImage = 'assets/images/login_bg.png';
  static const logoImage = 'assets/images/logo.png';

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  static LinearGradient get brandOverlay => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          brandTint.withValues(alpha: 0.92),
          brandTint.withValues(alpha: 0.70),
          brandTint.withValues(alpha: 0.35),
        ],
      );

  // Text
  static const _font = 'Montserrat';

  static const brandName = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const headline = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const tagline = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const featureLabel = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const title = TextStyle(
    fontFamily: _font,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: titleText,
    letterSpacing: -0.5,
  );

  static const subtitle = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: subtitleText,
  );

  static const fieldText = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: titleText,
  );

  static const fieldHint = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: hintText,
  );

  static const link = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static OutlineInputBorder fieldBorderOf(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );

  static InputDecoration fieldDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: fieldHint,
      prefixIcon: Icon(icon, color: titleText, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      border: fieldBorderOf(fieldBorder),
      enabledBorder: fieldBorderOf(fieldBorder),
      focusedBorder: fieldBorderOf(green, 1.6),
      errorBorder: fieldBorderOf(AppColors.error),
      focusedErrorBorder: fieldBorderOf(AppColors.error, 1.6),
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: green.withValues(alpha: 0.6),
        elevation: 0,
        shape: const StadiumBorder(),
      );
}
