import 'package:flutter/material.dart';

/// Design tokens for the Evergreen **website** UI (distinct from the mobile
/// app's theme). Colors, spacing, typography and responsive breakpoints used
/// across all web screens.
class WebTokens {
  WebTokens._();

  // --- Brand / palette (from the Figma landing design) ---
  static const Color green = Color(0xFF106220);
  static const Color greenDark = Color(0xFF0C4A18);
  static const Color greenDeep = Color(0xFF0A3D14);
  static const Color mint = Color(0xFFBFE3C6);
  static const Color mintSoft = Color(0xFFE8F3EA);
  static const Color pageGreen = Color(0xFFDDEEDF); // pale green section bg
  static const Color cream = Color(0xFFF4F7F2);

  static const Color ink = Color(0xFF14201A); // near-black headings
  static const Color body = Color(0xFF4B5A50); // muted body text
  static const Color faint = Color(0xFF8A988E); // captions / eyebrows
  static const Color line = Color(0xFFE2E8E3);
  static const Color white = Color(0xFFFFFFFF);

  static const Color star = Color(0xFFFFB300);

  // --- Layout ---
  /// Max content width for centered sections on large screens.
  static const double maxContentWidth = 1200;

  /// Breakpoints.
  static const double mobileMax = 640;
  static const double tabletMax = 1024;

  static bool isMobile(double w) => w < mobileMax;
  static bool isTablet(double w) => w >= mobileMax && w < tabletMax;
  static bool isDesktop(double w) => w >= tabletMax;

  /// Horizontal page gutter, responsive to width.
  static double gutter(double w) {
    if (w < mobileMax) return 20;
    if (w < tabletMax) return 40;
    return 80;
  }

  // --- Typography (Montserrat, matching the app's font family) ---
  static const String fontFamily = 'Montserrat';

  static TextStyle display(double size, {Color color = ink, double h = 1.1}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: h,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle heading(double size, {Color color = ink}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle bodyText(
    double size, {
    Color color = body,
    FontWeight weight = FontWeight.w500,
    double h = 1.5,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: h,
        fontWeight: weight,
        color: color,
      );

  static TextStyle eyebrow({Color color = faint}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: color,
      );

  // --- Shadows ---
  static List<BoxShadow> cardShadow = const [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
