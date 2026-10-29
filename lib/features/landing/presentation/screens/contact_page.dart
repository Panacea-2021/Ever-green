import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../landing_theme.dart';
import '../sections/services/services_bottom_sections.dart';

/// Website Contact Us page — Figma node 232:167.
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      body: SelectionArea(
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContactHero(onClose: _close),
              const _ContactCities(),
              ServicesCtaSection(
                onAssessment: () => context.go(Routes.login),
                onContact: () => context.go(Routes.login),
              ),
              ServicesFooter(onBook: () => context.go(Routes.login)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactHero extends StatelessWidget {
  const _ContactHero({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final heroHeight = isMobile ? 240.0 : 280.0;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF141414)),
          Image.asset(
            LandingAssets.contactHero,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF141414)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 48,
                0,
                isMobile ? 20 : 48,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CONTACT US',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: isMobile ? 36 : 56,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                      letterSpacing: isMobile ? -0.6 : -1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hyderabad · Bengaluru',
                    style: TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: isMobile ? 20 : 36,
            right: isMobile ? 16 : 36,
            child: SelectionContainer.disabled(
              child: _CloseButton(onTap: onClose),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: 22,
            color: Color(0xFF141414),
          ),
        ),
      ),
    );
  }
}

class _CityInfo {
  const _CityInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.photo,
    required this.map,
    required this.mapsUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String photo;
  final String map;
  final String mapsUrl;
}

class _ContactCities extends StatelessWidget {
  const _ContactCities();

  static const _cities = [
    _CityInfo(
      name: 'HYDERABAD',
      email: 'hyderabad@evergreen.kitchen',
      phone: '+91 40 4567 2100',
      address:
          '12-2-418, Road No. 12, Banjara Hills, Hyderabad, Telangana 500034',
      photo: LandingAssets.contactHyderabad,
      map: LandingAssets.contactMapHyderabad,
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=Banjara+Hills+Hyderabad',
    ),
    _CityInfo(
      name: 'BENGALURU',
      email: 'bengaluru@evergreen.kitchen',
      phone: '+91 80 4567 2100',
      address: '201, 100 Feet Road, Indiranagar, Bengaluru, Karnataka 560038',
      photo: LandingAssets.contactBengaluru,
      map: LandingAssets.contactMapBengaluru,
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=Indiranagar+Bengaluru',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Transform.translate(
      offset: Offset(0, isMobile ? -24 : -36),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 80,
          0,
          isMobile ? 16 : 80,
          0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 36,
                isMobile ? 24 : 36,
                isMobile ? 20 : 36,
                isMobile ? 28 : 36,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        _CityCard(city: _cities[0]),
                        const SizedBox(height: 28),
                        _CityCard(city: _cities[1]),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _CityCard(city: _cities[0])),
                        const SizedBox(width: 28),
                        Expanded(child: _CityCard(city: _cities[1])),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city});

  final _CityInfo city;

  void _open(String url) {
    // Visual contact actions; links stay on the card.
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              city.photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8EEE9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          city.name,
          style: const TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: LandingColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.mail_outline,
          label: city.email,
          onTap: () => _open('mailto:${city.email}'),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: city.phone,
          onTap: () => _open('tel:${city.phone.replaceAll(' ', '')}'),
        ),
        const SizedBox(height: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _open(city.mapsUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 2.1,
                child: Image.asset(
                  city.map,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF1F3F1),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.map_outlined,
                      color: LandingColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          city.address,
          style: const TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: Color(0xFF5C6B60),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F3EA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: LandingColors.primary),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3A3A3A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
