import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../landing_theme.dart';
import '../sections/services/services_bottom_sections.dart';

/// Shared marketing legal page (Terms / Privacy) — close control, no site nav.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.heroAsset,
    required this.sections,
    this.desktopHeroHeight = 560,
    this.mobileHeroHeight = 420,
    this.bodyOverlap = 72,
    this.bodyMaxWidth = 980,
    this.bodyRadius = 28,
    this.desktopTitleFontSize = 56,
    this.heroContentBottomInset,
    this.showCloseButton = true,
    this.backgroundColor = const Color(0xFFF6F7F4),
  });

  final String title;
  final String heroAsset;
  final List<(String, List<String>)> sections;
  final double desktopHeroHeight;
  final double mobileHeroHeight;
  final double bodyOverlap;
  final double bodyMaxWidth;
  final double bodyRadius;
  final double desktopTitleFontSize;
  final double? heroContentBottomInset;
  final bool showCloseButton;
  final Color backgroundColor;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LegalHero(
                title: title,
                heroAsset: heroAsset,
                onClose: () => _close(context),
                desktopHeroHeight: desktopHeroHeight,
                mobileHeroHeight: mobileHeroHeight,
                desktopTitleFontSize: desktopTitleFontSize,
                contentBottomInset: heroContentBottomInset,
                showCloseButton: showCloseButton,
              ),
              _LegalBody(
                sections: sections,
                overlap: bodyOverlap,
                maxWidth: bodyMaxWidth,
                radius: bodyRadius,
              ),
              ServicesCtaSection(
                onAssessment: () => context.go(Routes.login),
                onContact: () => context.go(Routes.contact),
              ),
              ServicesFooter(onBook: () => context.go(Routes.login)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalHero extends StatelessWidget {
  const _LegalHero({
    required this.title,
    required this.heroAsset,
    required this.onClose,
    required this.desktopHeroHeight,
    required this.mobileHeroHeight,
    required this.desktopTitleFontSize,
    required this.contentBottomInset,
    required this.showCloseButton,
  });

  final String title;
  final String heroAsset;
  final VoidCallback onClose;
  final double desktopHeroHeight;
  final double mobileHeroHeight;
  final double desktopTitleFontSize;
  final double? contentBottomInset;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final heroHeight = isMobile ? mobileHeroHeight : desktopHeroHeight;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF141414)),
          Image.asset(
            heroAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF141414)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 48,
                0,
                isMobile ? 20 : 48,
                contentBottomInset ?? (isMobile ? 72 : 96),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: isMobile ? 32 : desktopTitleFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                      letterSpacing: isMobile ? -0.6 : -1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Updated 2026',
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showCloseButton)
            Positioned(
              top: isMobile ? 20 : 36,
              right: isMobile ? 16 : 36,
              child: SelectionContainer.disabled(
                child: _CloseButton(onTap: onClose),
              ),
            ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: 22,
            color: Color(0xFF141414),
          ),
        ),
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({
    required this.sections,
    required this.overlap,
    required this.maxWidth,
    required this.radius,
  });

  final List<(String, List<String>)> sections;
  final double overlap;
  final double maxWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Transform.translate(
      offset: Offset(0, isMobile ? -overlap * (48 / 72) : -overlap),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 80,
          0,
          isMobile ? 16 : 80,
          0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isMobile ? 24 : 72,
                isMobile ? 36 : 64,
                isMobile ? 24 : 72,
                isMobile ? 40 : 72,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) SizedBox(height: isMobile ? 32 : 40),
                    Text(
                      sections[i].$1,
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: LandingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var p = 0; p < sections[i].$2.length; p++) ...[
                      if (p > 0) const SizedBox(height: 16),
                      Text(
                        sections[i].$2[p],
                        style: TextStyle(
                          fontFamily: LandingTypography.fontFamily,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w400,
                          height: 1.7,
                          color: const Color(0xFF3A3A3A),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
