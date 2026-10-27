import 'package:flutter/material.dart';

/// Color palette extracted from the Evergreen landing page Figma design.
class LandingColors {
  LandingColors._();

  // Primary greens
  static const Color primary = Color(0xFF106220);
  static const Color primaryDark = Color(0xFF142117);
  static const Color primaryLight = Color(0xFF3DAE62);
  static const Color accentGreen = Color(0xFF04AD2F);
  static const Color stepGreen = Color(0xFF12A83C);

  // Backgrounds
  static const Color bgMain = Color(0xFFF3F6F1);
  static const Color bgMint = Color(0xFFE5F6EA);
  static const Color bgLight = Color(0xFFF4FAF6);
  static const Color bgCream = Color(0xFFF6F7F4);
  static const Color bgIconGreen = Color(0xFFE7F6EC);
  static const Color heroOverlay = Color(0x4D7EAE8C); // rgba(126,174,140,0.3)

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C6B60);
  static const Color textMuted = Color(0xFF8B918C);
  static const Color textLight = Color(0xFF9AA39C);
  static const Color textDark = Color(0xFF141414);
  static const Color textGray = Color(0xFF8F9893);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);
  static const Color border = Color(0xFFECECEC);
  static const Color borderActive = Color(0xFF3DAE62);
  static const Color divider = Color(0x26FFFFFF); // rgba(255,255,255,0.15)

  // Reviews gradient
  static const Color reviewGradientStart = Color(0xFF127A38);
  static const Color reviewGradientMid1 = Color(0xFF24964C);
  static const Color reviewGradientMid2 = Color(0xFF5FBF82);
  static const Color reviewGradientMid3 = Color(0xFFC6EAD2);
  static const Color reviewGradientEnd = Color(0xFFF6F4EE);

  // Card shadows
  static const Color shadowGreen = Color(0x24173B21); // rgba(23,59,33,0.14)
  static const Color shadowDark = Color(0x2E0D2917); // rgba(13,41,23,0.18)

  // Decorative orbs
  static const Color orbAccent = Color(0x8033AD5B); // rgba(51,173,91,0.5)
}

/// Typography styles matching the Figma design (Montserrat font family).
class LandingTypography {
  LandingTypography._();

  static const String fontFamily = 'Montserrat';

  // Hero section
  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 88,
    fontWeight: FontWeight.w500,
    height: 1.02,
    letterSpacing: -3.08,
    color: LandingColors.white,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xE6FFFFFF), // rgba(255,255,255,0.9)
  );

  // Section headers
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -1.9,
    color: LandingColors.textDark,
  );

  static const TextStyle sectionTitleWhite = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.06,
    color: LandingColors.white,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 54,
    fontWeight: FontWeight.w700,
    height: 1.02,
    letterSpacing: -1.9,
    color: LandingColors.textDark,
  );

  // Eyebrow text
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
    color: LandingColors.primaryDark,
  );

  static const TextStyle eyebrowWhite = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.4,
    color: Color(0xCCFFFFFF), // rgba(255,255,255,0.8)
  );

  // Card titles
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    height: 1.22,
    color: LandingColors.white,
  );

  static const TextStyle cardTitleDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: LandingColors.white,
  );

  static const TextStyle featureCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.84,
    fontWeight: FontWeight.w700,
    height: 1.22,
    color: LandingColors.textPrimary,
  );

  // Card body text
  static const TextStyle cardBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.71,
    color: Color(0xD9FFFFFF), // rgba(255,255,255,0.85)
  );

  static const TextStyle featureCardBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.44,
    fontWeight: FontWeight.w500,
    height: 1.23,
    color: LandingColors.textSecondary,
  );

  // Step labels
  static const TextStyle stepLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.54,
    color: Color(0xCCFFFFFF), // rgba(255,255,255,0.8)
  );

  static const TextStyle stepLabelInactive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.54,
    color: LandingColors.textGray,
  );

  static const TextStyle stepNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.34,
    color: LandingColors.stepGreen,
  );

  // Button text
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: LandingColors.textPrimary,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: LandingColors.white,
  );

  // Navigation
  static const TextStyle navLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: LandingColors.white,
  );

  static const TextStyle logoText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.5,
    color: LandingColors.white,
  );

  // Technician cards
  static const TextStyle techName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: LandingColors.white,
  );

  static const TextStyle techDescription = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: Color(0xE0FFFFFF), // opacity 0.88
  );

  static const TextStyle techBadge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: LandingColors.white,
  );

  // Reviews
  static const TextStyle reviewHeadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.19,
    color: LandingColors.textPrimary,
  );

  static const TextStyle reviewQuote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF2C2C2C),
  );

  static const TextStyle reviewerName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: LandingColors.textPrimary,
  );

  static const TextStyle reviewerRole = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6D746F),
  );

  // FAQ
  static const TextStyle faqQuestion = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LandingColors.textPrimary,
  );

  static const TextStyle faqAnswer = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF5E6860),
  );

  static const TextStyle faqNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LandingColors.textLight,
  );

  // Footer
  static const TextStyle footerBrand = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: LandingColors.white,
  );

  static const TextStyle footerHeading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: LandingColors.white,
  );

  static const TextStyle footerLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xB8FFFFFF), // rgba(255,255,255,0.72)
  );

  static const TextStyle footerLinkGreen = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LandingColors.accentGreen,
  );

  static const TextStyle footerCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0x8CFFFFFF), // rgba(255,255,255,0.55)
  );

  static const TextStyle copyright = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0x8CFFFFFF), // rgba(255,255,255,0.55)
  );

  // App download section
  static const TextStyle appTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.02,
    color: LandingColors.textDark,
  );

  static const TextStyle appFeatureTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: LandingColors.textPrimary,
  );

  static const TextStyle appFeatureBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF5C6560),
  );

  static const TextStyle storeLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 8,
    fontWeight: FontWeight.w500,
    color: Color(0xCCFFFFFF), // opacity 0.8
  );

  static const TextStyle storeName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LandingColors.white,
  );

  // Task steps section
  static const TextStyle taskStepTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.12,
    color: LandingColors.white,
  );

  // Intro text
  static const TextStyle introBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: LandingColors.textMuted,
  );

  // Why choose us
  static const TextStyle whyTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: LandingColors.textPrimary,
  );
}

/// Common spacing values used across the landing page.
class LandingSpacing {
  LandingSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double section = 40;
  static const double sectionLarge = 64;
  static const double sectionXL = 80;
  static const double sectionXXL = 112;

  // Page padding
  static const double pagePaddingHorizontal = 140;
  static const double pagePaddingMobile = 20;

  // Content max width
  static const double maxContentWidth = 1440;
  static const double maxTextWidth = 1024;
}

/// Border radius values used in the landing page.
class LandingRadius {
  LandingRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
  static const double card = 28;
  static const double button = 33554400; // Large value for pill shape
}

/// Shadow presets for landing page components.
class LandingShadows {
  LandingShadows._();

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: LandingColors.shadowGreen,
      blurRadius: 31.68,
      offset: Offset(0, 15.84),
    ),
  ];

  static const List<BoxShadow> reviewCardShadow = [
    BoxShadow(
      color: LandingColors.shadowDark,
      blurRadius: 48,
      offset: Offset(0, 22),
    ),
  ];

  static const List<BoxShadow> smallCardShadow = [
    BoxShadow(
      color: LandingColors.shadowDark,
      blurRadius: 36,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> appCardShadow = [
    BoxShadow(
      color: Color(0x290C2816), // rgba(12,40,22,0.16)
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> phoneShadow = [
    BoxShadow(
      color: Color(0x52082812), // rgba(8,40,18,0.32)
      blurRadius: 50,
      offset: Offset(0, 24),
    ),
  ];

  static const List<BoxShadow> searchShadow = [
    BoxShadow(
      color: Color(0x0A103C1C), // rgba(16,60,28,0.04)
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Asset paths for landing page images and icons.
class LandingAssets {
  LandingAssets._();

  static const String _basePath = 'assets/images/landing';

  // Hero and backgrounds
  static const String heroBg = '$_basePath/hero_bg.png';
  static const String heroVideo = 'assets/videos/landing_hero.mp4';
  static const String termsHero = '$_basePath/terms_hero.png';
  static const String privacyHero = '$_basePath/privacy_hero.png';
  static const String contactHero = '$_basePath/contact_hero.png';
  static const String contactHyderabad = '$_basePath/contact_hyderabad.png';
  static const String contactBengaluru = '$_basePath/contact_bengaluru.png';
  static const String contactMapHyderabad = '$_basePath/contact_map_hyderabad.png';
  static const String contactMapBengaluru = '$_basePath/contact_map_bengaluru.png';
  static const String taskStepsBg = '$_basePath/task_steps_bg.png';
  static const String phoneMockup = '$_basePath/phone_mockup.png';
  static const String whyKitchen = '$_basePath/why_kitchen.png';

  // Technician photos
  static const String techMeera = '$_basePath/tech_meera.png';
  static const String techArjun = '$_basePath/tech_arjun.png';
  static const String techSara = '$_basePath/tech_sara.png';
  static const String techNikhil = '$_basePath/tech_nikhil.png';
  static const String techLeela = '$_basePath/tech_leela.png';

  // Review photos
  static const String reviewPhoto1 = '$_basePath/review_photo_1.png';
  static const String reviewPhoto2 = '$_basePath/review_photo_2.png';
  static const String reviewPhoto3 = '$_basePath/review_photo_3.png';
  static const String reviewPhoto4 = '$_basePath/review_photo_4.png';
  static const String reviewPhoto5 = '$_basePath/review_photo_5.png';

  // App section images
  static const String appLogoMark = '$_basePath/app_logo_mark.png';
  static const String mixer = '$_basePath/mixer.png';
  static const String range = '$_basePath/range.png';
  static const String fridge = '$_basePath/fridge.png';

  // Icons - Steps
  static const String iconRegister = '$_basePath/icon_register.svg';
  static const String iconEquipment = '$_basePath/icon_equipment.svg';
  static const String iconRepairs = '$_basePath/icon_repairs.svg';
  static const String iconTechnician = '$_basePath/icon_technician.svg';
  static const String iconApprove = '$_basePath/icon_approve.svg';

  // Icons - Why Choose Us
  static const String glyphVerified = '$_basePath/glyph_verified.svg';
  static const String glyphPricing = '$_basePath/glyph_pricing.svg';
  static const String glyphSchedule = '$_basePath/glyph_schedule.svg';
  static const String glyphSupport = '$_basePath/glyph_support.svg';
  static const String glyphWarranty = '$_basePath/glyph_warranty.svg';

  // Icons - FAQ
  static const String iconExpand = '$_basePath/icon_expand.svg';
  static const String iconCollapse = '$_basePath/icon_collapse.svg';
  static const String iconPot = '$_basePath/icon_pot.svg';
  static const String iconUtensils = '$_basePath/icon_utensils.svg';
  static const String iconFlame = '$_basePath/icon_flame.svg';
  static const String iconHat = '$_basePath/icon_hat.svg';
  static const String iconFridge = '$_basePath/icon_fridge.svg';
  static const String iconCup = '$_basePath/icon_cup.svg';

  // Icons - General
  static const String markLogo = '$_basePath/mark_logo.svg';
  static const String dot = '$_basePath/dot.svg';
  static const String stars = '$_basePath/stars.svg';
  static const String star = '$_basePath/star.svg';
  static const String iconCalendar = '$_basePath/icon_calendar.svg';
  static const String iconSearch = '$_basePath/icon_search.svg';
  static const String iconSearchApp = '$_basePath/icon_search_app.svg';
  static const String iconShield = '$_basePath/icon_shield.svg';
  static const String iconShieldApp = '$_basePath/icon_shield_app.svg';
  static const String iconMagnifier = '$_basePath/icon_magnifier.svg';

  // Decorative
  static const String orbLeaf = '$_basePath/orb_leaf.svg';
  static const String orbDeep = '$_basePath/orb_deep.svg';
  static const String orbMint = '$_basePath/orb_mint.svg';
  static const String orbSmall = '$_basePath/orb_small.svg';
  static const String edgeCircle1 = '$_basePath/edge_circle_1.svg';
  static const String edgeCircle2 = '$_basePath/edge_circle_2.svg';

  // Store badges
  static const String iconApple = '$_basePath/icon_apple.svg';
  static const String iconPlay = '$_basePath/icon_play.svg';
  static const String ellipse = '$_basePath/ellipse.svg';

  // Social icons
  static const String socialInstagram = '$_basePath/social_instagram.svg';
  static const String socialFacebook = '$_basePath/social_facebook.svg';
  static const String socialX = '$_basePath/social_x.svg';
  static const String socialLinkedin = '$_basePath/social_linkedin.svg';
}

/// Responsive breakpoints for landing page.
class LandingBreakpoints {
  LandingBreakpoints._();

  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= wide;
}
