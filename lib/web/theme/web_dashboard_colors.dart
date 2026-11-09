import 'package:flutter/material.dart';

/// Soft, varied palette used by authenticated website modules.
class WebDashboardColors {
  WebDashboardColors._();

  static const Color primary = Color(0xFF735A78);
  static const Color primaryDark = Color(0xFF51435B);
  static const Color primarySoft = Color(0xFFF0EBF3);
  static const Color secondary = Color(0xFF5A8F87);
  static const Color secondarySoft = Color(0xFFEAF3F0);
  static const Color blue = Color(0xFF68819B);
  static const Color blueSoft = Color(0xFFEDF1F5);
  static const Color amber = Color(0xFFB27E3F);
  static const Color amberSoft = Color(0xFFF7F0E4);
  static const Color coral = Color(0xFFB96B62);
  static const Color coralSoft = Color(0xFFF7EBE8);
  static const Color success = Color(0xFF39734F);
  static const Color successSoft = Color(0xFFE8F0E9);
  static const Color sidebarTop = Color(0xFF106220);
  static const Color sidebarBottom = Color(0xFF106220);
  static const Color sideNavBackground = Color(0xFF106220);
  static const Color sideNavForeground = Color(0xFFFFFFFF);
  static const Color sideNavMutedForeground = Color(0xFFDDEEDF);
  static const Color sideNavSelectedBackground = Color(0xFFBFE3C6);
  static const Color sideNavSelectedForeground = Color(0xFF0C4A18);
  static const Color sideNavLogoBackground = Color(0xFF2E7D32);
  static const Color sideNavBadgeBackground = Color(0xFFBFE3C6);
  static const Color accentSoft = primarySoft;
  static const Color accentPale = Color(0xFFD4C8D9);
  static const Color canvas = Color(0xFFEAF0F3);
  static const Color line = Color(0xFFE9E5DC);
  static const Color accentLight = Color(0xFFC7A8C9);
  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F3EA),
      Color(0xFFE8F3EA),
      Color(0xFFE8F3EA),
    ],
    stops: [0, 0.52, 1],
  );
}
