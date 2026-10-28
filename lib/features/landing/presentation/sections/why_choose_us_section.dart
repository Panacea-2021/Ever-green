import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

class FeatureCardData {
  final String title;
  final String description;
  final String iconPath;

  const FeatureCardData({
    required this.title,
    required this.description,
    required this.iconPath,
  });
}

/// Why Choose Us — same photo and copy, rendered as sharp Flutter text.
class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  static const List<FeatureCardData> _features = [
    FeatureCardData(
      title: 'Verified professionals',
      description:
          'Licensed, background-checked, and experienced technicians.',
      iconPath: LandingAssets.glyphVerified,
    ),
    FeatureCardData(
      title: 'Transparent pricing',
      description:
          'You approve the price before any work starts. No hidden fees.',
      iconPath: LandingAssets.glyphPricing,
    ),
    FeatureCardData(
      title: 'Convenient scheduling',
      description: 'Pick a time window that fits your routine.',
      iconPath: LandingAssets.glyphSchedule,
    ),
    FeatureCardData(
      title: 'Applicable warranty',
      description: 'Repairs covered under service warranty for peace of mind.',
      iconPath: LandingAssets.glyphWarranty,
    ),
    FeatureCardData(
      title: 'Service support',
      description:
          'A dedicated support team from booking to repair completion.',
      iconPath: LandingAssets.glyphSupport,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return ColoredBox(
      color: const Color(0xFFF3FBF5),
      child: isMobile
          ? _MobileLayout(features: _features)
          : _DesktopLayout(features: _features),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.features});

  final List<FeatureCardData> features;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.38,
            child: const Padding(
              padding: EdgeInsets.only(left: 0),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: _PhotoPanel(),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 8, 48, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: _FeatureCard(data: features[i])),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _FeatureCard(data: features[3])),
                      const SizedBox(width: 14),
                      Expanded(child: _FeatureCard(data: features[4])),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.features});

  final List<FeatureCardData> features;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            child: SizedBox(height: 280, child: _PhotoPanel()),
          ),
          const SizedBox(height: 28),
          const _Header(),
          const SizedBox(height: 20),
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _FeatureCard(data: features[i], isMobile: true),
          ],
        ],
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          LandingAssets.whyChooseUs,
          fit: BoxFit.cover,
          alignment: const Alignment(-1, 0),
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
        ),
        const Positioned(
          left: 20,
          bottom: 24,
          child: _ReliableBadge(),
        ),
      ],
    );
  }
}

class _ReliableBadge extends StatelessWidget {
  const _ReliableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE6106220),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Reliable repairs\nfor a happier home',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: _Copy()),
        const SizedBox(width: 12),
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF2BB24A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your kitchen\nOur priority',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Color(0xB3106220),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F6EA),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 12, color: LandingColors.primary),
              const SizedBox(width: 6),
              Text(
                'WHY CHOOSE US',
                style: LandingTypography.eyebrow.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Why Choose Us?',
          style: LandingTypography.sectionTitle.copyWith(
            fontSize: 40,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Everything you need for a smooth and hassle-free kitchen repair experience — all in one place.',
          style: LandingTypography.introBody.copyWith(
            fontSize: 14,
            height: 1.5,
            color: LandingColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.data,
    this.isMobile = false,
  });

  final FeatureCardData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile ? _mobile() : _desktop(),
    );
  }

  Widget _desktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(),
        const SizedBox(height: 16),
        Text(
          data.title,
          style: LandingTypography.featureCardTitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          data.description,
          style: LandingTypography.featureCardBody.copyWith(
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _mobile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: LandingTypography.featureCardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                data.description,
                style: LandingTypography.featureCardBody.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _icon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: LandingColors.bgIconGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: SvgPicture.asset(
          data.iconPath,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            LandingColors.primary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
