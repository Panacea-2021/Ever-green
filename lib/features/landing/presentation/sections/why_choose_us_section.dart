import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// The "Why Choose Us" banner image, with its small text redrawn as live text
/// so it stays sharp at any size. Positions are in banner image pixels.
class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  // Height increased by 20% total from original: 569 * 1.2 = 683
  static const _bannerSize = Size(1600, 689);
  static const _bodyColor = Color(0xFF2F3B34);
  static const _cardColor = Color(0xFFFEFEFE);

  // Vertical positions scaled by 1.21 from original to match new height
  static const _features = [
    (
      patch: Rect.fromLTRB(846, 334, 996, 456),
      text: Rect.fromLTRB(828, 344, 994, 455),
      title: 'Verified\nprofessionals',
      body: 'Licensed, background-checked, and experienced technicians.',
    ),
    (
      patch: Rect.fromLTRB(1100, 334, 1272, 456),
      text: Rect.fromLTRB(1104, 338, 1266, 451),
      title: 'Transparent\npricing',
      body: 'You approve the price before any work starts. No hidden fees.',
    ),
    (
      patch: Rect.fromLTRB(1380, 334, 1536, 456),
      text: Rect.fromLTRB(1385, 338, 1530, 451),
      title: 'Convenient\nscheduling',
      body: 'Pick a time window that fits your routine.',
    ),
    (
      patch: Rect.fromLTRB(880, 506, 1082, 628),
      text: Rect.fromLTRB(887, 511, 1077, 623),
      title: 'Applicable\nwarranty',
      body: 'Repairs covered under service warranty for peace of mind.',
    ),
    (
      patch: Rect.fromLTRB(1200, 506, 1410, 628),
      text: Rect.fromLTRB(1206, 516, 1404, 623),
      title: 'Service support',
      body: 'A dedicated support team from booking to repair completion.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final imageWidth =
            isMobile ? 1000.0 : constraints.maxWidth.clamp(0.0, 1600.0);
        final banner = SizedBox(
          width: imageWidth,
          child: AspectRatio(
            aspectRatio: _bannerSize.width / _bannerSize.height,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox.fromSize(
                size: _bannerSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        LandingAssets.whyChooseUsBanner,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    ..._chip(),
                    ..._subtitle(),
                    for (final f in _features) ...[
                      _patch(f.patch, _cardColor),
                      _textBox(
                        f.text,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                fontFamily: LandingTypography.fontFamily,
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: LandingColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              f.body,
                              style: const TextStyle(
                                fontFamily: LandingTypography.fontFamily,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: _bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        return isMobile
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: banner,
              )
            : Center(child: banner);
      },
    );
  }

  List<Widget> _chip() {
    return [
      // Vertical positions scaled by 1.21 from original
      _patch(const Rect.fromLTRB(814, 56, 932, 80), const Color(0xFFDFF4E5)),
      _textBox(
        const Rect.fromLTRB(818, 57, 932, 80),
        Text(
          'WHY CHOOSE US',
          style: LandingTypography.eyebrow.copyWith(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: LandingColors.primaryDark,
          ),
        ),
        center: true,
        wrap: false,
      ),
    ];
  }

  List<Widget> _subtitle() {
    return [
      // Vertical positions scaled by 1.21 from original
      _patch(const Rect.fromLTRB(778, 174, 1258, 228), const Color(0xFFF5FBF7)),
      _textBox(
        const Rect.fromLTRB(782, 175, 1256, 226),
        const Text(
          'Everything you need for a smooth and hassle-free kitchen repair\n'
          'experience — all in one place.',
          style: TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 14.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: _bodyColor,
          ),
        ),
        wrap: false,
      ),
    ];
  }

  static Widget _patch(Rect rect, Color color) {
    return Positioned.fromRect(
      rect: rect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  /// Places [child] inside [rect], shrinking it if it would not fit.
  /// Without [wrap], [child] keeps its own line breaks instead of wrapping to
  /// the box width.
  static Widget _textBox(
    Rect rect,
    Widget child, {
    bool center = false,
    bool wrap = true,
  }) {
    final alignment = center ? Alignment.centerLeft : Alignment.topLeft;
    return Positioned.fromRect(
      rect: rect,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: wrap ? SizedBox(width: rect.width, child: child) : child,
      ),
    );
  }
}
