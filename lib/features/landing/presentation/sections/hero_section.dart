import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Hero section with full-bleed background image, header navigation, and CTA buttons.
class HeroSection extends StatelessWidget {
  final VoidCallback? onBookRepair;
  final VoidCallback? onGetEstimate;
  final VoidCallback? onContactUs;
  final VoidCallback? onServices;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onTerms;

  const HeroSection({
    super.key,
    this.onBookRepair,
    this.onGetEstimate,
    this.onContactUs,
    this.onServices,
    this.onPrivacyPolicy,
    this.onTerms,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      height: isMobile ? 700 : 900,
      child: Stack(
        children: [
          // Background image with overlay
          _buildBackground(),

          // Green tint overlay
          Positioned.fill(
            child: Container(
              color: LandingColors.heroOverlay,
            ),
          ),

          // Radial gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0x29244830), // rgba(36,72,48,0.16)
                    Color(0x00244830),
                  ],
                  stops: [0.0, 0.62],
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Column(
              children: [
                // Header
                _buildHeader(context, isMobile, isTablet),

                // Main content
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

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            LandingAssets.heroBg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFD7EAD4),
            ),
          ),
          // Dark overlay for text readability
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 24,
      ),
      child: isMobile
          ? _buildMobileHeader(context)
          : _buildDesktopHeader(context, isTablet),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        _buildLogo(),
        // Menu button
        _GlassButton(
          onTap: () {},
          child: const Icon(
            Icons.menu,
            color: LandingColors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left links
        Row(
          children: [
            _GlassButton(
              onTap: onPrivacyPolicy,
              child: Text(
                'Privacy Policy',
                style: LandingTypography.navLink,
              ),
            ),
            const SizedBox(width: 8),
            _GlassButton(
              onTap: onTerms,
              child: Text(
                'Terms & Conditions',
                style: LandingTypography.navLink,
              ),
            ),
          ],
        ),

        // Center logo (absolute positioned)
        _buildLogo(),

        // Right buttons
        Row(
          children: [
            _PrimaryButton(
              label: 'Book a repair',
              icon: Icons.calendar_today_outlined,
              onTap: onBookRepair,
            ),
            const SizedBox(width: 8),
            _GlassButton(
              onTap: onContactUs,
              child: Text(
                'Contact Us',
                style: LandingTypography.navLink,
              ),
            ),
            const SizedBox(width: 8),
            _GlassButton(
              onTap: onServices,
              child: Text(
                'Services',
                style: LandingTypography.navLink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          LandingAssets.markLogo,
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(
            LandingColors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Evergreen',
          style: LandingTypography.logoText,
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, bool isMobile, bool isTablet) {
    final horizontalPadding = isMobile ? 20.0 : (isTablet ? 60.0 : 208.0);
    final titleFontSize = isMobile ? 40.0 : (isTablet ? 56.0 : 88.0);

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

/// Glass-morphism style button for header navigation.
class _GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _GlassButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(LandingRadius.pill),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Primary white button for header "Book a repair".
class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.9) : Colors.white,
            borderRadius: BorderRadius.circular(LandingRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: LandingColors.textPrimary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: LandingTypography.buttonPrimary,
              ),
            ],
          ),
        ),
      ),
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
