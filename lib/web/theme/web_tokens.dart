import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Design tokens for the Evergreen **website** UI (distinct from the mobile
/// app's theme). Colors, spacing, typography and responsive breakpoints used
/// across all web screens.
class WebTokens {
  WebTokens._();

  // --- Website palette; non-web values preserve the mobile app theme ---
  static const Color green = kIsWeb ? Color(0xFF735A78) : Color(0xFF106220);
  static const Color greenDark = kIsWeb ? Color(0xFF51435B) : Color(0xFF0C4A18);
  static const Color greenDeep = kIsWeb ? Color(0xFF3D3544) : Color(0xFF0A3D14);
  static const Color mint = kIsWeb ? Color(0xFFB8D7D0) : Color(0xFFBFE3C6);
  static const Color mintSoft = kIsWeb ? Color(0xFFF0EBF3) : Color(0xFFE8F3EA);
  static const Color pageGreen = kIsWeb ? Color(0xFFF2EFE8) : Color(0xFFDDEEDF);
  static const Color cream = kIsWeb ? Color(0xFFF7F6F2) : Color(0xFFF4F7F2);

  static const Color ink = kIsWeb ? Color(0xFF30383A) : Color(0xFF14201A);
  static const Color body = kIsWeb ? Color(0xFF626B6A) : Color(0xFF4B5A50);
  static const Color faint = kIsWeb ? Color(0xFF87908C) : Color(0xFF8A988E);
  static const Color line = kIsWeb ? Color(0xFFE9E5DC) : Color(0xFFE2E8E3);
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
