import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// Dark footer: brand + social, link columns, and a copyright rule.
class WebFooterSection extends StatelessWidget {
  const WebFooterSection({super.key});

  static const _columns = [
    (
      'SUPPORT',
      ['Contact us', 'Common questions', 'How it works', 'Book a repair']
    ),
    (
      'COMPANY',
      [
        'Why choose us',
        'Service Engineers',
        'Customer reviews',
        'Download the app'
      ]
    ),
    ('KITCHEN', ['Warranty', 'Pricing', 'Visit window', 'Job note']),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return WebSection(
      background: WebTokens.greenDeep,
      verticalPadding: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: WebTokens.mint, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Ever Green',
                      style: WebTokens.heading(24, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  _SocialIcon(Icons.facebook),
                  _SocialIcon(Icons.camera_alt_outlined),
                  _SocialIcon(Icons.alternate_email),
                  _SocialIcon(Icons.play_circle_outline),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 60,
            runSpacing: 32,
            children: [
              // Brand contact block.
              SizedBox(
                width: mobile ? double.infinity : 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footLabel('Feel free to reach us at:'),
                    const SizedBox(height: 8),
                    _footLink('Book a repair', bright: true),
                    const SizedBox(height: 16),
                    _footLabel('Locations:'),
                    const SizedBox(height: 8),
                    _footLink('Hyderabad'),
                    _footLink('Bengaluru'),
                  ],
                ),
              ),
              for (final col in _columns)
                SizedBox(
                  width: mobile ? 140 : 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        col.$1,
                        style: WebTokens.eyebrow(color: WebTokens.mint),
                      ),
                      const SizedBox(height: 14),
                      for (final link in col.$2) _footLink(link),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          Text(
            '© 2026 Evergreen Enterprises. All rights reserved.',
            style: WebTokens.bodyText(
              12.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footLabel(String t) => Text(
        t,
        style: TextStyle(
          fontFamily: WebTokens.fontFamily,
          fontSize: 12.5,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      );

  Widget _footLink(String t, {bool bright = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: TextStyle(
            fontFamily: WebTokens.fontFamily,
            fontSize: 14,
            fontWeight: bright ? FontWeight.w700 : FontWeight.w500,
            color:
                bright ? WebTokens.mint : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      );
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
