import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Data model for a feature card.
class FeatureCardData {
  final String title;
  final String description;
  final String iconPath;
  final Offset position; // Relative position for desktop layout

  const FeatureCardData({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.position,
  });
}

/// "Why Choose Us" section with kitchen image, floating cards, and decorative orbs.
class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  static const List<FeatureCardData> _features = [
    FeatureCardData(
      title: 'Verified professionals',
      description: 'Licensed engineers, checked before they arrive.',
      iconPath: LandingAssets.glyphVerified,
      position: Offset(619, 281),
    ),
    FeatureCardData(
      title: 'Transparent pricing',
      description: 'You approve the price before any work starts.',
      iconPath: LandingAssets.glyphPricing,
      position: Offset(837, 145),
    ),
    FeatureCardData(
      title: 'Convenient Scheduling',
      description: 'Pick a visit window that fits the service.',
      iconPath: LandingAssets.glyphSchedule,
      position: Offset(1090, 232),
    ),
    FeatureCardData(
      title: 'Service support',
      description: 'A desk that stays on the job until it is done.',
      iconPath: LandingAssets.glyphSupport,
      position: Offset(1120, 482),
    ),
    FeatureCardData(
      title: 'Applicable warranty',
      description: 'Covered repairs stay covered after sign-off.',
      iconPath: LandingAssets.glyphWarranty,
      position: Offset(855, 497),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LandingColors.bgLight,
      child: Image.asset(
        LandingAssets.whyChooseUs,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => const SizedBox(height: 240),
      ),
    );
  }

  Widget _buildDesktopLayout(double screenWidth, bool isTablet) {
    final scale = screenWidth / 1440;

    return Stack(
      children: [
        // Kitchen image on left
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 547 * scale,
          child: Image.asset(
            LandingAssets.whyKitchen,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: LandingColors.primary.withOpacity(0.2),
            ),
          ),
        ),

        // Green accent bar on right
        Positioned(
          right: 0,
          top: -33,
          child: Transform.rotate(
            angle: 0.0,
            child: Container(
              width: 254,
              height: 894,
              color: LandingColors.orbAccent,
            ),
          ),
        ),

        // Decorative orbs
        _buildOrbs(scale),

        // Title
        Positioned(
          left: 0,
          right: 0,
          top: 48,
          child: Center(
            child: Text(
              'Why Choose Us?',
              style: LandingTypography.whyTitle,
            ),
          ),
        ),

        // Feature cards
        ..._buildPositionedCards(scale),
      ],
    );
  }

  Widget _buildOrbs(double scale) {
    return Stack(
      children: [
        // Orb leaf (large)
        Positioned(
          left: 1080 * scale,
          top: 28,
          child: SvgPicture.asset(
            LandingAssets.orbLeaf,
            width: 112,
            height: 112,
          ),
        ),

        // Orb deep (medium)
        Positioned(
          left: 1204 * scale,
          top: 266,
          child: SvgPicture.asset(
            LandingAssets.orbDeep,
            width: 72,
            height: 72,
          ),
        ),

        // Orb mint (medium)
        Positioned(
          left: 1268 * scale,
          top: 610,
          child: SvgPicture.asset(
            LandingAssets.orbMint,
            width: 80,
            height: 80,
          ),
        ),

        // Orb small
        Positioned(
          left: 760 * scale,
          top: 300,
          child: SvgPicture.asset(
            LandingAssets.orbSmall,
            width: 44,
            height: 44,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPositionedCards(double scale) {
    return _features.map((feature) {
      return Positioned(
        left: feature.position.dx * scale,
        top: feature.position.dy,
        child: _FeatureCard(
          data: feature,
          width: 184.8,
          height: 207.68,
        ),
      );
    }).toList();
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kitchen image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              LandingAssets.whyKitchen,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 250,
                color: LandingColors.primary.withOpacity(0.2),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Why Choose Us?',
            style: LandingTypography.whyTitle.copyWith(
              fontSize: 36,
            ),
          ),

          const SizedBox(height: 24),

          // Feature cards in grid
          _buildMobileCards(),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _features.map((feature) {
        return _FeatureCard(
          data: feature,
          width: double.infinity,
          height: null,
          isMobile: true,
        );
      }).toList(),
    );
  }
}

/// Feature card with icon, title, and description.
class _FeatureCard extends StatefulWidget {
  final FeatureCardData data;
  final double? width;
  final double? height;
  final bool isMobile;

  const _FeatureCard({
    required this.data,
    this.width,
    this.height,
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
        height: widget.isMobile ? null : widget.height,
        padding: EdgeInsets.all(widget.isMobile ? 20 : 17.6),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.16),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? LandingColors.shadowGreen.withOpacity(0.2)
                  : LandingColors.shadowGreen,
              blurRadius: _isHovered ? 40 : 31.68,
              offset: Offset(0, _isHovered ? 20 : 15.84),
            ),
          ],
        ),
        child: widget.isMobile
            ? _buildMobileContent()
            : _buildDesktopContent(),
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon
        Container(
          width: 49.28,
          height: 49.28,
          decoration: BoxDecoration(
            color: LandingColors.bgIconGreen,
            borderRadius: BorderRadius.circular(24.64),
          ),
          child: Center(
            child: SvgPicture.asset(
              widget.data.iconPath,
              width: 24.64,
              height: 24.64,
              colorFilter: const ColorFilter.mode(
                LandingColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),

        // Text content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data.title,
              style: LandingTypography.featureCardTitle,
            ),
            const SizedBox(height: 5.28),
            Text(
              widget.data.description,
              style: LandingTypography.featureCardBody,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LandingColors.bgIconGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: SvgPicture.asset(
              widget.data.iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                LandingColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.title,
                style: LandingTypography.featureCardTitle.copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.data.description,
                style: LandingTypography.featureCardBody.copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
