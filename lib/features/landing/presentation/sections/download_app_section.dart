import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Download Our App section with phone mockup, feature cards, and store badges.
class DownloadAppSection extends StatelessWidget {
  final VoidCallback? onAppStore;
  final VoidCallback? onGooglePlay;

  const DownloadAppSection({
    super.key,
    this.onAppStore,
    this.onGooglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      color: LandingColors.bgCream,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 60 : 88,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isMobile)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildDecorativeCircles(),
              ),
            ),

          // Main content
          Column(
            children: [
              // Title
              Text(
                'Download our app\nfor the kitchen',
                textAlign: TextAlign.center,
                style: LandingTypography.appTitle.copyWith(
                  fontSize: isMobile ? 36 : 64,
                ),
              ),

              SizedBox(height: isMobile ? 24 : 28),

              // Store badges
              _buildStoreBadges(isMobile),

              SizedBox(height: isMobile ? 32 : 28),

              // Stage with phone and feature cards
              _buildStage(isMobile, isTablet, screenWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top-left circle
        Positioned(
          left: -70,
          top: -80,
          child: SvgPicture.asset(
            LandingAssets.edgeCircle1,
            width: 240,
            height: 240,
          ),
        ),

        // Bottom-right circle
        Positioned(
          right: -80,
          bottom: -60,
          child: SvgPicture.asset(
            LandingAssets.edgeCircle2,
            width: 260,
            height: 260,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreBadges(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StoreBadge(
          icon: LandingAssets.iconApple,
          label: 'Download on the',
          storeName: 'App Store',
          onTap: onAppStore,
        ),
        const SizedBox(width: 12),
        _StoreBadge(
          icon: LandingAssets.iconPlay,
          label: 'GET IT ON',
          storeName: 'Google Play',
          onTap: onGooglePlay,
        ),
      ],
    );
  }

  Widget _buildStage(bool isMobile, bool isTablet, double screenWidth) {
    if (isMobile) {
      return _buildMobileStage();
    }

    final scale = (screenWidth / 1440).clamp(0.7, 1.0);

    return SizedBox(
      height: 636 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left feature card - Find the machine
          Positioned(
            left: 48 * scale,
            top: 58 * scale,
            child: _FeatureCard(
              icon: LandingAssets.iconMagnifier,
              title: 'Find the machine',
              description:
                  'Ranges, walk-ins, hoods, and the smaller machines on the pass.',
              width: 320 * scale,
            ),
          ),

          // Right feature card - Price before the panel
          Positioned(
            right: 0,
            top: -64 * scale,
            child: _FeatureCard(
              icon: LandingAssets.iconShieldApp,
              title: 'Price before the panel',
              description:
                  'The visit window and the price land in the app before anyone opens a panel.',
              width: 300 * scale,
            ),
          ),

          // Center phone
          Center(
            child: _PhoneMockup(scale: scale),
          ),

          // Kitchen equipment images
          Positioned(
            left: -53 * scale,
            top: 259 * scale,
            child: Image.asset(
              LandingAssets.mixer,
              width: 340 * scale,
              height: 320 * scale,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                width: 340 * scale,
                height: 320 * scale,
              ),
            ),
          ),

          Positioned(
            right: 126 * scale,
            bottom: 0,
            child: Image.asset(
              LandingAssets.range,
              width: 246 * scale,
              height: 266 * scale,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                width: 246 * scale,
                height: 266 * scale,
              ),
            ),
          ),

          Positioned(
            right: -64 * scale,
            bottom: 0,
            child: Image.asset(
              LandingAssets.fridge,
              width: 247 * scale,
              height: 309 * scale,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                width: 247 * scale,
                height: 309 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStage() {
    return Column(
      children: [
        // Feature cards
        _FeatureCard(
          icon: LandingAssets.iconMagnifier,
          title: 'Find the machine',
          description:
              'Ranges, walk-ins, hoods, and the smaller machines on the pass.',
          width: double.infinity,
          isMobile: true,
        ),

        const SizedBox(height: 16),

        _FeatureCard(
          icon: LandingAssets.iconShieldApp,
          title: 'Price before the panel',
          description:
              'The visit window and the price land in the app before anyone opens a panel.',
          width: double.infinity,
          isMobile: true,
        ),

        const SizedBox(height: 32),

        // Phone mockup
        _PhoneMockup(scale: 0.8),

        const SizedBox(height: 24),

        // Kitchen equipment row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              LandingAssets.mixer,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 100),
            ),
            Image.asset(
              LandingAssets.range,
              width: 80,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 80),
            ),
            Image.asset(
              LandingAssets.fridge,
              width: 80,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 80),
            ),
          ],
        ),
      ],
    );
  }
}

/// App store badge button.
class _StoreBadge extends StatefulWidget {
  final String icon;
  final String label;
  final String storeName;
  final VoidCallback? onTap;

  const _StoreBadge({
    required this.icon,
    required this.label,
    required this.storeName,
    this.onTap,
  });

  @override
  State<_StoreBadge> createState() => _StoreBadgeState();
}

class _StoreBadgeState extends State<_StoreBadge> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF222222) : LandingColors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                widget.icon,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: LandingTypography.storeLabel,
                  ),
                  Text(
                    widget.storeName,
                    style: LandingTypography.storeName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feature card with icon, title, and description.
class _FeatureCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final double width;
  final bool isMobile;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.width,
    this.isMobile = false,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.isMobile ? null : widget.width,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: LandingShadows.appCardShadow,
        ),
        child: Column(
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LandingColors.bgIconGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.icon,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    LandingColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: LandingTypography.appFeatureTitle,
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: LandingTypography.appFeatureBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone mockup with Evergreen branding.
class _PhoneMockup extends StatelessWidget {
  final double scale;

  const _PhoneMockup({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320 * scale,
      height: 620 * scale,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(44 * scale),
        boxShadow: LandingShadows.phoneShadow,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: LandingColors.primary,
          borderRadius: BorderRadius.circular(34 * scale),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            Image.asset(
              LandingAssets.appLogoMark,
              width: 148 * scale,
              height: 98 * scale,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 148 * scale,
                height: 98 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.eco,
                  size: 48 * scale,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 12 * scale),

            // Wordmark
            Text(
              'EVER GREEN',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
