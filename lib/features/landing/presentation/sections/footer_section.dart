import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../landing_theme.dart';

/// Footer section with brand, social icons, link columns, services, cities, and copyright.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = LandingBreakpoints.isMobile(context);
    final isTablet = LandingBreakpoints.isTablet(context);

    return Container(
      width: double.infinity,
      color: LandingColors.black,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? LandingSpacing.pagePaddingMobile : LandingSpacing.sectionXL,
        vertical: LandingSpacing.sectionLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social row - Brand + Social icons
          _buildSocialRow(isMobile),
          const SizedBox(height: 36),

          // Link columns
          if (isMobile)
            _buildMobileLinkColumns(context)
          else if (isTablet)
            _buildTabletLinkColumns(context)
          else
            _buildDesktopLinkColumns(context),
          const SizedBox(height: 36),

          // First divider
          Container(
            height: 1,
            color: LandingColors.divider,
          ),
          const SizedBox(height: 36),

          // Services and Cities
          if (isMobile)
            _buildMobileServicesAndCities()
          else
            _buildDesktopServicesAndCities(),
          const SizedBox(height: 36),

          // Second divider
          Container(
            height: 1,
            color: LandingColors.divider,
          ),
          const SizedBox(height: 36),

          // Copyright
          Text(
            '© 2026 Ever Green. All rights reserved.',
            style: LandingTypography.copyright,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand name
        Text(
          'Ever Green',
          style: LandingTypography.footerBrand,
        ),

        // Social icons
        Row(
          children: [
            _SocialIconButton(
              assetPath: LandingAssets.socialInstagram,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _SocialIconButton(
              assetPath: LandingAssets.socialFacebook,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _SocialIconButton(
              assetPath: LandingAssets.socialX,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _SocialIconButton(
              assetPath: LandingAssets.socialLinkedin,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLinkColumns(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand column
        Expanded(
          child: _buildBrandColumn(),
        ),
        // Support column
        Expanded(
          child: _buildLinkColumn(
            context: context,
            title: 'SUPPORT',
            links: [
              'Contact us',
              'Common questions',
              'How it works',
              'Book a repair',
            ],
          ),
        ),
        // Company column
        Expanded(
          child: _buildLinkColumn(
            title: 'COMPANY',
            links: [
              'Why choose us',
              'Service Engineers',
              'Customer reviews',
              'Download the app',
            ],
          ),
        ),
        // Kitchen column
        Expanded(
          child: _buildLinkColumn(
            title: 'KITCHEN',
            links: [
              'Warranty',
              'Pricing',
              'Visit window',
              'Job note',
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLinkColumns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildBrandColumn()),
            Expanded(
              child: _buildLinkColumn(
                context: context,
                title: 'SUPPORT',
                links: [
                  'Contact us',
                  'Common questions',
                  'How it works',
                  'Book a repair',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLinkColumn(
                title: 'COMPANY',
                links: [
                  'Why choose us',
                  'Service Engineers',
                  'Customer reviews',
                  'Download the app',
                ],
              ),
            ),
            Expanded(
              child: _buildLinkColumn(
                title: 'KITCHEN',
                links: [
                  'Warranty',
                  'Pricing',
                  'Visit window',
                  'Job note',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLinkColumns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandColumn(),
        const SizedBox(height: 32),
        _buildLinkColumn(
          context: context,
          title: 'SUPPORT',
          links: [
            'Contact us',
            'Common questions',
            'How it works',
            'Book a repair',
          ],
        ),
        const SizedBox(height: 32),
        _buildLinkColumn(
          title: 'COMPANY',
          links: [
            'Why choose us',
            'Service Engineers',
            'Customer reviews',
            'Download the app',
          ],
        ),
        const SizedBox(height: 32),
        _buildLinkColumn(
          title: 'KITCHEN',
          links: [
            'Warranty',
            'Pricing',
            'Visit window',
            'Job note',
          ],
        ),
      ],
    );
  }

  Widget _buildBrandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feel free to reach us at:',
          style: LandingTypography.footerCaption,
        ),
        const SizedBox(height: 8),
        _FooterLink(
          text: 'Book a repair',
          isGreen: true,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        Text(
          'Locations:',
          style: LandingTypography.footerCaption,
        ),
        const SizedBox(height: 8),
        _FooterLink(
          text: 'Hyderabad',
          isGreen: true,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _FooterLink(
          text: 'Bengaluru',
          isGreen: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLinkColumn({
    required String title,
    required List<String> links,
    BuildContext? context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: LandingTypography.footerHeading,
        ),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FooterLink(
                text: link,
                onTap: () {
                  if (link == 'Contact us' && context != null) {
                    context.go(Routes.contact);
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget _buildDesktopServicesAndCities() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All Services
        Expanded(
          child: _buildServicesSection(),
        ),
        const SizedBox(width: 80),
        // All Cities
        Expanded(
          child: _buildCitiesSection(),
        ),
      ],
    );
  }

  Widget _buildMobileServicesAndCities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServicesSection(),
        const SizedBox(height: 32),
        _buildCitiesSection(),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL SERVICES',
          style: LandingTypography.footerHeading,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First column of services
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FooterLink(text: 'Same-day visit', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Range repair', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Microwave repair', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Walk-in repair', onTap: () {}),
                ],
              ),
            ),
            // Second column of services
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FooterLink(text: 'Fridge repair', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Hood service', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Oven repair', onTap: () {}),
                  const SizedBox(height: 12),
                  _FooterLink(text: 'Kitchen prep', onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL CITIES',
          style: LandingTypography.footerHeading,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _FooterLink(text: 'Hyderabad', onTap: () {}),
            const SizedBox(width: 40),
            _FooterLink(text: 'Bengaluru', onTap: () {}),
          ],
        ),
      ],
    );
  }
}

/// Social media icon button with circular border.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x33FFFFFF), // rgba(255,255,255,0.2)
            width: 1,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              LandingColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer link with hover effect.
class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.text,
    required this.onTap,
    this.isGreen = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool isGreen;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: widget.isGreen
              ? LandingTypography.footerLinkGreen.copyWith(
                  color: _isHovered
                      ? LandingColors.accentGreen.withOpacity(0.8)
                      : LandingColors.accentGreen,
                )
              : LandingTypography.footerLink.copyWith(
                  color: _isHovered
                      ? LandingColors.white
                      : const Color(0xB8FFFFFF),
                ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
