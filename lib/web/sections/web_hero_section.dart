import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// Landing hero: top navigation bar + a full-bleed kitchen background with the
/// headline, sub-copy and the two primary call-to-action buttons.
class WebHeroSection extends StatelessWidget {
  const WebHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return SizedBox(
      height: mobile ? 560 : 760,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (pale-green kitchen with range + hood) with a
          // graceful fallback gradient.
          Image.asset(
            'assets/images/web_hero_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFBFD9C2), Color(0xFF8FBE97)],
                ),
              ),
            ),
          ),
          // Dark scrim for text legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D0A3D14),
                  Color(0x330A3D14),
                  Color(0x660A3D14),
                ],
              ),
            ),
          ),
          Column(
            children: [
              const _WebHeader(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: WebTokens.gutter(w),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Fast kitchen repair —\nwhen you need it most.',
                            textAlign: TextAlign.center,
                            style: WebTokens.display(
                              mobile ? 36 : 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Same-day service. Certified service engineers. '
                            '100% satisfaction.',
                            textAlign: TextAlign.center,
                            style: WebTokens.bodyText(
                              mobile ? 15 : 17,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 12,
                            children: [
                              WebButton(
                                label: 'Book a Repair',
                                icon: Icons.build_outlined,
                                onTap: () {},
                              ),
                              WebButton(
                                label: 'Get Estimate',
                                filled: false,
                                light: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebHeader extends StatelessWidget {
  const _WebHeader();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return Padding(
      padding:
          EdgeInsets.fromLTRB(WebTokens.gutter(w), 22, WebTokens.gutter(w), 0),
      child: Row(
        children: [
          // Left: policy links (hidden on mobile).
          if (!mobile)
            const Expanded(
              child: Row(
                children: [
                  _NavLink('Privacy Policy'),
                  SizedBox(width: 20),
                  _NavLink('Terms & Conditions'),
                ],
              ),
            ),
          // Center: brand mark.
          Expanded(
            flex: mobile ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.eco, size: 18, color: WebTokens.green),
                ),
                const SizedBox(width: 10),
                Text(
                  'Evergreen',
                  style: WebTokens.heading(20, color: Colors.white),
                ),
              ],
            ),
          ),
          // Right: actions.
          if (!mobile)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WebButton(
                    label: 'Book a repair',
                    icon: Icons.build_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  const _NavLink('Contact Us'),
                  const SizedBox(width: 16),
                  const _NavLink('Services'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label);
  final String label;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Text(
        widget.label,
        style: TextStyle(
          fontFamily: WebTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: _hover ? 1 : 0.85),
        ),
      ),
    );
  }
}
