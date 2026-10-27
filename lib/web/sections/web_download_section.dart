import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// "Download our app for the kitchen" — heading, store badges, a phone mock
/// flanked by two info callouts.
class WebDownloadSection extends StatelessWidget {
  const WebDownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return WebSection(
      background: WebTokens.cream,
      child: Column(
        children: [
          Text(
            'Download our app\nfor the kitchen',
            textAlign: TextAlign.center,
            style: WebTokens.display(mobile ? 30 : 46),
          ),
          const SizedBox(height: 24),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              _StoreBadge(
                top: 'Download on the',
                bottom: 'App Store',
                icon: Icons.apple,
              ),
              _StoreBadge(
                top: 'GET IT ON',
                bottom: 'Google Play',
                icon: Icons.play_arrow,
              ),
            ],
          ),
          const SizedBox(height: 44),
          _Stage(mobile: mobile),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final phone = Container(
      width: 240,
      height: 440,
      decoration: BoxDecoration(
        color: WebTokens.green,
        borderRadius: BorderRadius.circular(32),
        boxShadow: WebTokens.cardShadow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 54),
            const SizedBox(height: 12),
            Text(
              'EVERGREEN',
              style: WebTokens.heading(18, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    const callouts = [
      (
        'Find the machine',
        'Ranges, walk-ins, hoods, and the smaller machines on the pass.',
        Icons.search
      ),
      (
        'Price before the panel',
        'The visit window and the price land in the app before anyone opens a panel.',
        Icons.shield_outlined
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          phone,
          const SizedBox(height: 24),
          for (final c in callouts) ...[
            _Callout(c),
            const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _Callout(callouts[0]),
          ),
        ),
        const SizedBox(width: 36),
        phone,
        const SizedBox(width: 36),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Callout(callouts[1]),
          ),
        ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout(this.data);
  final (String, String, IconData) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: WebTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTokens.mintSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.$3, color: WebTokens.green, size: 22),
          ),
          const SizedBox(height: 14),
          Text(data.$1, style: WebTokens.heading(16)),
          const SizedBox(height: 6),
          Text(data.$2, style: WebTokens.bodyText(13)),
        ],
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({
    required this.top,
    required this.bottom,
    required this.icon,
  });
  final String top;
  final String bottom;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: WebTokens.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                top,
                style: const TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 9,
                  color: Colors.white70,
                ),
              ),
              Text(
                bottom,
                style: const TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
