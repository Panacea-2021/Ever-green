import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../landing_theme.dart';
import 'services_common.dart';

class SvcNavItem {
  const SvcNavItem(this.label, this.onTap, {this.active = false});

  final String label;
  final VoidCallback onTap;
  final bool active;
}

class SvcLogo extends StatelessWidget {
  const SvcLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : SvcColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          LandingAssets.markLogo,
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 8),
        Text(
          'Evergreen',
          style: svcText(
            size: 19,
            weight: FontWeight.w700,
            letterSpacing: -0.4,
            color: color,
          ),
        ),
      ],
    );
  }
}

class ServicesHeader extends StatelessWidget {
  const ServicesHeader({
    super.key,
    required this.items,
    required this.onBook,
    required this.onLogo,
  });

  final List<SvcNavItem> items;
  final VoidCallback onBook;
  final VoidCallback onLogo;

  @override
  Widget build(BuildContext context) {
    final desktop = SvcLayout.isDesktop(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SvcColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SvcLayout.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SvcLayout.hPad(context)),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(onTap: onLogo, child: const SvcLogo()),
                ),
                const Spacer(),
                if (desktop) ...[
                  for (final item in items) _NavLink(item: item),
                  const SizedBox(width: 20),
                  SvcButton(
                      label: 'Book a service', compact: true, onTap: onBook),
                ] else ...[
                  SvcButton(
                    label: 'Book',
                    compact: true,
                    showArrow: false,
                    onTap: onBook,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.menu, color: SvcColors.text),
                    onSelected: (i) => items[i].onTap(),
                    itemBuilder: (_) => [
                      for (var i = 0; i < items.length; i++)
                        PopupMenuItem(
                          value: i,
                          child: Text(
                            items[i].label,
                            style: svcText(
                              weight: items[i].active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: items[i].active
                                  ? SvcColors.primary
                                  : SvcColors.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.item});

  final SvcNavItem item;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.item.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active || _hovered ? SvcColors.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(LandingRadius.pill),
          ),
          child: Text(
            widget.item.label,
            style: svcText(
              size: 13.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? SvcColors.primary : SvcColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class ServicesHero extends StatelessWidget {
  const ServicesHero({super.key, required this.onBook, required this.onAssess});

  final VoidCallback onBook;
  final VoidCallback onAssess;

  @override
  Widget build(BuildContext context) {
    final mobile = SvcLayout.isMobile(context);
    final desktop = SvcLayout.isDesktop(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SvcEyebrow('Commercial kitchen experts'),
        const SizedBox(height: 18),
        SvcHeading(
          title: 'Reliable kitchen solutions for ',
          highlight: 'businesses at scale.',
          size: mobile ? 36 : 54,
        ),
        const SizedBox(height: 18),
        const SvcBody(
          'Maintenance, repairs, installation and AMC for all commercial '
          'kitchen equipment — keeping your operations running safely, '
          'efficiently and without downtime.',
          size: 15.5,
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SvcButton(label: 'Book a service', onTap: onBook),
            SvcButton(
              label: 'Get a site assessment',
              variant: SvcButtonVariant.outline,
              onTap: onAssess,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 22,
          runSpacing: 16,
          children: [
            _HeroFeature(
                Icons.verified_outlined, 'Certified & trained\ntechnicians'),
            _HeroFeature(
                Icons.support_agent_outlined, '24/7 emergency\nsupport'),
            _HeroFeature(Icons.public_outlined, 'Pan-India\nservice coverage'),
            _HeroFeature(
                Icons.handshake_outlined, 'Trusted by leading\norganizations'),
          ],
        ),
      ],
    );

    final visualHeight = desktop ? 540.0 : (mobile ? 380.0 : 460.0);
    final visual = SizedBox(
      height: visualHeight,
      child: Stack(
        children: [
          Positioned.fill(
            right: mobile ? 0 : 70,
            child: const SvcImage(
              SvcAssets.hero,
              radius: 24,
              alignment: Alignment(0, -0.4),
            ),
          ),
          Positioned(
            right: mobile ? 12 : 0,
            top: mobile ? null : visualHeight * 0.14,
            bottom: mobile ? 12 : null,
            child: _HeroStats(compact: mobile),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, SvcColors.mint],
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: mobile ? 32 : 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SvcLayout.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SvcLayout.hPad(context)),
            child: desktop
                ? Row(
                    children: [
                      Expanded(flex: 5, child: text),
                      const SizedBox(width: 48),
                      Expanded(flex: 6, child: visual),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [text, const SizedBox(height: 32), visual],
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: SvcColors.mintStrong,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: SvcColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: svcText(size: 12, weight: FontWeight.w600, height: 1.35),
        ),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('99%', 'Uptime support'),
      ('500+', 'Facilities served'),
      ('24/7', 'Service support'),
    ];
    return Container(
      width: compact ? 140 : 180,
      padding: EdgeInsets.all(compact ? 14 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3B1E).withOpacity(0.14),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
                child: const Divider(height: 1, color: SvcColors.border),
              ),
            Text(
              stats[i].$1,
              style: svcText(
                size: compact ? 22 : 32,
                weight: FontWeight.w800,
                letterSpacing: -0.8,
                color: SvcColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stats[i].$2,
              style: svcText(size: compact ? 11 : 12.5, color: SvcColors.body),
            ),
          ],
        ],
      ),
    );
  }
}

class ServicesGridSection extends StatelessWidget {
  const ServicesGridSection({super.key, required this.onLearnMore});

  final VoidCallback onLearnMore;

  static const _services = [
    (
      SvcAssets.preventive,
      Icons.build_circle_outlined,
      'Preventive Maintenance',
      'Regular inspections and servicing to keep your equipment running at peak performance.',
    ),
    (
      SvcAssets.emergency,
      Icons.flash_on_outlined,
      'Emergency Repairs',
      'Fast response and expert repairs to minimise downtime and keep your kitchen running.',
    ),
    (
      SvcAssets.installation,
      Icons.handyman_outlined,
      'Equipment Installation',
      'Professional installation and configuration for new and upgraded equipment.',
    ),
    (
      SvcAssets.cleaning,
      Icons.cleaning_services_outlined,
      'Deep Cleaning & Sanitization',
      'Professional cleaning of kitchen equipment and exhaust systems to meet hygiene standards.',
    ),
    (
      SvcAssets.upgrades,
      Icons.upgrade_outlined,
      'Equipment Upgrades',
      'Upgrade and retrofit existing equipment for better efficiency, energy savings and performance.',
    ),
    (
      SvcAssets.consultation,
      Icons.support_agent_outlined,
      'Kitchen Consultation',
      'Expert guidance for kitchen layout, equipment planning and operational efficiency.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = SvcLayout.isMobile(context);
    return SvcSection(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SvcIntro(
            eyebrow: 'Our services',
            title: 'Complete commercial kitchen services',
            body: 'End-to-end support for all types of commercial kitchen '
                'equipment and facilities.',
          ),
          const SizedBox(height: 36),
          SvcGrid(
            columns: svcColumns(context, desktop: 3, tablet: 2, mobile: 1),
            children: [
              for (final s in _services)
                _ServiceCard(
                  asset: s.$1,
                  icon: s.$2,
                  title: s.$3,
                  description: s.$4,
                  onTap: onLearnMore,
                ),
            ],
          ),
          const SizedBox(height: 20),
          mobile
              ? IntrinsicHeight(
                  child: _ServiceCard(
                    asset: SvcAssets.amc,
                    icon: Icons.verified_user_outlined,
                    title: 'AMC & Compliance',
                    description: _amcText,
                    onTap: onLearnMore,
                  ),
                )
              : _WideServiceCard(onTap: onLearnMore),
        ],
      ),
    );
  }

  static const _amcText =
      'Comprehensive annual maintenance contracts with safety checks, '
      'compliance inspections and detailed reports.';
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.asset,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String asset;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SvcCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvcImage(
            asset,
            height: 200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvcIconBox(icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: svcText(size: 15.5, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style:
                        svcText(size: 13, height: 1.55, color: SvcColors.body),
                  ),
                  const Spacer(),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: SvcArrowCircle(),
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

class _WideServiceCard extends StatelessWidget {
  const _WideServiceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SvcCard(
      onTap: onTap,
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SvcImage(
              SvcAssets.amc,
              width: 340,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    const SvcIconBox(Icons.verified_user_outlined, size: 44),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AMC & Compliance',
                            style: svcText(size: 18, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ServicesGridSection._amcText,
                            style: svcText(
                              size: 13.5,
                              height: 1.55,
                              color: SvcColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const SvcArrowCircle(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentSection extends StatelessWidget {
  const EquipmentSection({super.key});

  static const _items = [
    (SvcAssets.cooking, 'Cooking Equipment', 'Ranges, ovens, fryers, grills'),
    (SvcAssets.refrigeration, 'Refrigeration', 'Walk-ins, chillers, freezers'),
    (SvcAssets.dishwashing, 'Dishwashing', 'Commercial dishwashers'),
    (SvcAssets.foodPrep, 'Food Preparation', 'Mixers, slicers, grinders'),
    (SvcAssets.ventilation, 'Ventilation Systems', 'Hoods, exhaust, fresh air'),
  ];

  @override
  Widget build(BuildContext context) {
    return SvcSection(
      color: SvcColors.mint,
      child: SvcSplit(
        leftFlex: 3,
        rightFlex: 8,
        left: const SvcIntro(
          eyebrow: 'Equipment we service',
          title: 'We service all major ',
          highlight: 'kitchen equipment.',
          body: 'Our technicians are trained to handle a wide range of '
              'commercial kitchen equipment from leading brands.',
        ),
        right: SvcGrid(
          columns: svcColumns(context, desktop: 5, tablet: 3, mobile: 2),
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final item in _items)
              SvcCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    SvcImage(item.$1, height: 100, radius: 10),
                    const SizedBox(height: 12),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: svcText(size: 13, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      textAlign: TextAlign.center,
                      style:
                          svcText(size: 11, color: SvcColors.body, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class IndustriesSection extends StatelessWidget {
  const IndustriesSection({
    super.key,
    this.lightBackground = false,
  });

  final bool lightBackground;

  static const _items = [
    (SvcAssets.itCampus, 'IT Campuses', 'Large-scale cafeterias & pantries'),
    (
      SvcAssets.cafeteria,
      'Corporate Cafeterias',
      'High-volume daily operations'
    ),
    (
      SvcAssets.hostels,
      'Hostels & Universities',
      'Mess kitchens serving thousands'
    ),
    (SvcAssets.hotels, 'Hotels & Resorts', 'Multi-outlet F&B operations'),
    (SvcAssets.hospitals, 'Hospitals', 'Hygiene-critical kitchens'),
    (
      SvcAssets.restaurants,
      'Restaurants & Cloud Kitchens',
      'Fast-paced commercial setups'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SvcSection(
      color: lightBackground ? Colors.white : SvcColors.primaryDeep,
      vertical: lightBackground ? 96 : null,
      child: SvcSplit(
        leftFlex: 3,
        rightFlex: 7,
        left: SvcIntro(
          eyebrow: 'Industries we serve',
          title: 'One service partner. ',
          highlight: 'Every kitchen.',
          body: 'We work with large organisations across industries to '
              'maintain and support their kitchen operations.',
          light: !lightBackground,
        ),
        right: SvcGrid(
          columns: svcColumns(context, desktop: 3, tablet: 3, mobile: 1),
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final item in _items)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SvcImage(item.$1, radius: 0),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x000B3B1E), Color(0xE60B3B1E)],
                            stops: [0.3, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: svcText(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$3,
                              style: svcText(
                                size: 11.5,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProcessSection extends StatelessWidget {
  const ProcessSection({super.key});

  static const _steps = [
    (
      SvcAssets.step1,
      'Assess your needs',
      'We understand your kitchen setup, equipment and requirements.'
    ),
    (
      SvcAssets.step2,
      'Get a customized plan',
      'We recommend the right service or AMC plan for your needs.'
    ),
    (
      SvcAssets.step3,
      'Service execution',
      'Our certified technicians deliver quality service on time.'
    ),
    (
      SvcAssets.step4,
      'Ongoing support',
      'Regular maintenance, reports and 24/7 support.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SvcSection(
      color: Colors.white,
      child: SvcSplit(
        leftFlex: 3,
        rightFlex: 7,
        left: const SvcIntro(
          eyebrow: 'How it works',
          title: 'A simple process ',
          highlight: 'for reliable operations.',
          body: 'From assessment to ongoing support, we make kitchen '
              'maintenance simple and hassle-free.',
        ),
        right: SvcGrid(
          columns: svcColumns(context, desktop: 4, tablet: 4, mobile: 2),
          spacing: 18,
          runSpacing: 28,
          children: [
            for (var i = 0; i < _steps.length; i++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: SvcColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: svcText(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: i < _steps.length - 1
                            ? Container(
                                height: 1.5, color: SvcColors.mintStrong)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SvcImage(_steps[i].$1, height: 150, radius: 12),
                  const SizedBox(height: 14),
                  Text(
                    _steps[i].$2,
                    style: svcText(size: 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _steps[i].$3,
                    style:
                        svcText(size: 12.5, color: SvcColors.body, height: 1.5),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
