import 'package:flutter/material.dart';

import '../landing_theme.dart';
import 'landing_hero_video.dart';
import 'landing_site_header.dart';

/// Hero section with full-bleed background image, header navigation, and CTA buttons.
class HeroSection extends StatelessWidget {
  final VoidCallback? onBookRepair;
  final VoidCallback? onGetEstimate;
  final VoidCallback? onContactUs;
  final VoidCallback? onServices;
  final VoidCallback? onIndustries;
  final VoidCallback? onAbout;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onHome;
  final VoidCallback? onSignIn;
  final VoidCallback? onSearch;

  const HeroSection({
    super.key,
    this.onBookRepair,
    this.onGetEstimate,
    this.onContactUs,
    this.onServices,
    this.onIndustries,
    this.onAbout,
    this.onHowItWorks,
    this.onHome,
    this.onSignIn,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return SizedBox(
      width: double.infinity,
      height: isMobile ? 525 : 675,
      child: Stack(
        children: [
          const Positioned.fill(child: LandingHeroVideo()),

          // Soft green wash so the clip still reads as Evergreen.
          Positioned.fill(
            child: Container(
              color: const Color(0x337EAE8C),
            ),
          ),

          // Readability gradient for the headline and header.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x14000000),
                    Color(0x73000000),
                  ],
                  stops: [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Column(
              children: [
                LandingSiteHeader(
                  onHome: onHome,
                  onServices: onServices,
                  onIndustries: onIndustries,
                  onAbout: onAbout,
                  onHowItWorks: onHowItWorks,
                  onContact: onContactUs,
                  onBookRepair: onBookRepair,
                  onSignIn: onSignIn ?? onBookRepair,
                  onSearch: onSearch,
                ),
                Expanded(
                  child: _buildHeroContent(context, isMobile, isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isMobile, bool isTablet) {
    final horizontalPadding = isMobile ? 20.0 : (isTablet ? 60.0 : 160.0);
    final titleFontSize = isMobile ? 34.0 : (isTablet ? 48.0 : 64.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main headline
          Text(
            'Fast kitchen repair — when you need it most.',
            textAlign: TextAlign.center,
            style: LandingTypography.heroTitle.copyWith(
              fontSize: titleFontSize,
              letterSpacing: isMobile ? -1.5 : -3.08,
              height: 1.02,
            ),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Subtitle
          Text(
            'Same-day service. Certified service engineers.\n100% satisfaction guarantee.',
            textAlign: TextAlign.center,
            style: LandingTypography.heroSubtitle.copyWith(
              fontSize: isMobile ? 14 : 16,
            ),
          ),

          SizedBox(height: isMobile ? 32 : 48),

          // CTA buttons
          _buildCtaButtons(isMobile),
        ],
      ),
    );
  }

  Widget _buildCtaButtons(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _HeroButton(
            label: 'Book a Repair',
            isPrimary: true,
            onTap: onBookRepair,
          ),
          const SizedBox(height: 12),
          _HeroButton(
            label: 'Get Estimate',
            isPrimary: false,
            onTap: onGetEstimate,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HeroButton(
          label: 'Book a Repair',
          isPrimary: true,
          onTap: onBookRepair,
        ),
        const SizedBox(width: 12),
        _HeroButton(
          label: 'Get Estimate',
          isPrimary: false,
          onTap: onGetEstimate,
        ),
      ],
    );
  }
}

/// Hero CTA button (Book a Repair / Get Estimate).
class _HeroButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _HeroButton({
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? Colors.white.withOpacity(0.9) : Colors.white)
                : (_isHovered
                    ? Colors.black.withOpacity(0.25)
                    : Colors.black.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(LandingRadius.pill),
          ),
          child: Text(
            widget.label,
            style: widget.isPrimary
                ? LandingTypography.buttonPrimary
                : LandingTypography.buttonSecondary,
          ),
        ),
      ),
    );
  }
}
