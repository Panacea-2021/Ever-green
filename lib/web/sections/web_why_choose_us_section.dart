import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// "Why Choose Us?" — a heading with floating feature chips over a soft green
/// panel. Simplified from the Figma scattered layout into a clean grid so it
/// reads well and stays responsive.
class WebWhyChooseUsSection extends StatelessWidget {
  const WebWhyChooseUsSection({super.key});

  static const _features = [
    (
      'Verified professionals',
      'Every service engineer is certified and background-checked.',
      Icons.verified_user_outlined
    ),
    (
      'Transparent pricing',
      'See the price before anyone opens a panel.',
      Icons.receipt_long_outlined
    ),
    (
      'Convenient scheduling',
      'Pick a visit window that works for you.',
      Icons.event_available_outlined
    ),
    (
      'Applicable warranty',
      'Repairs are covered by a service warranty.',
      Icons.shield_outlined
    ),
    (
      'Service support',
      'Help is one tap away before, during and after.',
      Icons.support_agent_outlined
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return WebSection(
      background: WebTokens.pageGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Why Choose Us?',
                style: WebTokens.display(mobile ? 30 : 44),
              ),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: WebTokens.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 36),
          LayoutBuilder(
            builder: (context, c) {
              final cols = mobile ? 1 : (w < WebTokens.tabletMax ? 2 : 3);
              const gap = 16.0;
              final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final f in _features)
                    SizedBox(width: cardW, child: _FeatureCard(f)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.feature);
  final (String, String, IconData) feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: WebTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTokens.mintSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.$3, color: WebTokens.green, size: 24),
          ),
          const SizedBox(height: 16),
          Text(feature.$1, style: WebTokens.heading(17)),
          const SizedBox(height: 8),
          Text(feature.$2, style: WebTokens.bodyText(13.5)),
        ],
      ),
    );
  }
}
