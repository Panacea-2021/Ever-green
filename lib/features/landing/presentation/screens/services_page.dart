import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../landing_theme.dart';
import '../sections/footer_section.dart';
import '../sections/landing_site_header.dart';

/// Commercial services page — opened from the header Services link.
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: Colors.white,
                child: LandingSiteHeader(
                  activeNav: 'Services',
                  onHome: () => context.go(Routes.home),
                  onServices: () {},
                  onHowItWorks: () => context.go(Routes.home),
                  onAbout: () => context.go(Routes.home),
                  onIndustries: () => context.go(Routes.home),
                  onContact: () => context.push(Routes.contact),
                  onBookRepair: () => context.go(Routes.login),
                  onSignIn: () => context.go(Routes.login),
                ),
              ),
              const SizedBox(height: 18),
              _ServicesHero(onBook: () => context.go(Routes.login)),
              const _CompleteServices(),
              const _EquipmentTypes(),
              const _Industries(),
              const _HowWeWork(),
              const _Performance(),
              _AmcPlans(onBook: () => context.go(Routes.login)),
              const _TrustedOrgs(),
              const _LogoStrip(),
              _ServicesFaq(onContact: () => context.push(Routes.contact)),
              _BottomCta(
                onAssess: () => context.go(Routes.login),
                onContact: () => context.push(Routes.contact),
              ),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesHero extends StatelessWidget {
  const _ServicesHero({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return SizedBox(
      height: isMobile ? 560 : 620,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            LandingAssets.whyKitchen,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xE60B1A12),
                  Color(0x66106220),
                  Color(0x33000000),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 80,
              isMobile ? 40 : 72,
              isMobile ? 20 : 80,
              isMobile ? 32 : 48,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reliable kitchen solutions\nat scale.',
                      style: LandingTypography.heroTitle.copyWith(
                        fontSize: isMobile ? 36 : 64,
                        height: 1.05,
                        letterSpacing: isMobile ? -1 : -2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Maintenance, repairs, installation and AMC for commercial kitchen equipment — so your line stays up, cleanly and without downtime.',
                      style: LandingTypography.heroSubtitle.copyWith(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 28,
                      runSpacing: 12,
                      children: const [
                        _HeroStat(value: '99%', label: 'uptime support'),
                        _HeroStat(value: '500+', label: 'kitchens served'),
                        _HeroStat(value: '24/7', label: 'emergency cover'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _GreenPill(label: 'Book a service', onTap: onBook),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 13,
            color: Color(0xCCFFFFFF),
          ),
        ),
      ],
    );
  }
}

class _CompleteServices extends StatelessWidget {
  const _CompleteServices();

  static const _items = [
    _IconItem(
      icon: Icons.event_repeat_outlined,
      title: 'Preventive Maintenance',
      body: 'Scheduled visits that keep every machine on the line running.',
    ),
    _IconItem(
      icon: Icons.emergency_outlined,
      title: 'Emergency Repair',
      body: 'Same-day response when a range, fridge, or hood goes down.',
    ),
    _IconItem(
      icon: Icons.precision_manufacturing_outlined,
      title: 'Equipment Installation',
      body: 'New kit commissioned and signed off before service starts.',
    ),
    _IconItem(
      icon: Icons.cleaning_services_outlined,
      title: 'Deep Cleaning & Sanitization',
      body: 'Hoods, ducts, and food-contact surfaces cleaned to spec.',
    ),
    _IconItem(
      icon: Icons.upgrade_outlined,
      title: 'Equipment Upgrades',
      body: 'Replace tired machines before they take the line down.',
    ),
    _IconItem(
      icon: Icons.architecture_outlined,
      title: 'Kitchen Consultation',
      body: 'Layout, load, and AMC planning for a new or growing kitchen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 56 : 80,
        isMobile ? 20 : 80,
        isMobile ? 40 : 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPLETE COMMERCIAL KITCHEN SERVICES',
                style: LandingTypography.eyebrow.copyWith(letterSpacing: 1.8),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete commercial kitchen services',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 32 : 44,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'End-to-end support for all types of commercial kitchen equipment and facilities.',
                style: LandingTypography.introBody,
              ),
              const SizedBox(height: 36),
              _ResponsiveGrid(
                minWidth: 280,
                children: _items.map((item) => _ServiceCard(item: item)).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const _CircleIcon(icon: Icons.verified_outlined),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AMC & Compliance',
                            style: LandingTypography.featureCardTitle.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Annual maintenance contracts with inspection, reporting, and safety checks built in.',
                            style: LandingTypography.introBody.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentTypes extends StatelessWidget {
  const _EquipmentTypes();

  static const _items = [
    _IconItem(
      icon: Icons.local_fire_department_outlined,
      title: 'Cooking Equipment',
      body: 'Ranges, ovens, grills, and the pass.',
    ),
    _IconItem(
      icon: Icons.kitchen_outlined,
      title: 'Refrigeration',
      body: 'Walk-ins, reach-ins, and prep fridges.',
    ),
    _IconItem(
      icon: Icons.water_drop_outlined,
      title: 'Dishwashing',
      body: 'Warewashers and the pot wash.',
    ),
    _IconItem(
      icon: Icons.air_outlined,
      title: 'Exhaust & ventilation',
      body: 'Hoods, filters, fans, and makeup air.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      color: const Color(0xFFF7F8F5),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _EquipmentCopy(),
                    const SizedBox(height: 28),
                    ..._items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ServiceCard(item: item),
                        )),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(flex: 5, child: _EquipmentCopy()),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          LandingAssets.techArjun,
                          height: 420,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EquipmentCopy extends StatelessWidget {
  const _EquipmentCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EQUIPMENT WE SERVICE',
          style: LandingTypography.eyebrow.copyWith(letterSpacing: 1.8),
        ),
        const SizedBox(height: 12),
        Text(
          'We service all major kitchen equipment',
          style: LandingTypography.sectionSubtitle.copyWith(fontSize: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'From a single range to a full line — cooking, cold rooms, warewash, and extraction. No manufacturer lock-in.',
          style: LandingTypography.introBody,
        ),
        const SizedBox(height: 24),
        ..._EquipmentTypes._items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                _CircleIcon(icon: item.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: LandingTypography.featureCardTitle),
                      Text(
                        item.body,
                        style: LandingTypography.introBody.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Industries extends StatelessWidget {
  const _Industries();

  static const _items = [
    (LandingAssets.contactHyderabad, 'IT campuses'),
    (LandingAssets.contactBengaluru, 'Corporate cafeterias'),
    (LandingAssets.whyKitchen, 'Hotels & hospitality'),
    (LandingAssets.heroBg, 'Hospitals & healthcare'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INDUSTRIES WE SERVE',
                style: LandingTypography.eyebrow.copyWith(letterSpacing: 1.8),
              ),
              const SizedBox(height: 12),
              Text(
                'One service partner.\nEvery kitchen.',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 32 : 44,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We work with large organisations across food service, healthcare, hospitality, and campus dining.',
                style: LandingTypography.introBody,
              ),
              const SizedBox(height: 32),
              _ResponsiveGrid(
                minWidth: 240,
                children: _items
                    .map(
                      (item) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.asset(item.$1, fit: BoxFit.cover),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: Text(
                                item.$2,
                                style: const TextStyle(
                                  fontFamily: LandingTypography.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowWeWork extends StatelessWidget {
  const _HowWeWork();

  static const _steps = [
    ('1', 'Share your needs', 'Tell us the kitchen, the equipment, and the cover you want.'),
    ('2', 'Get a customised plan', 'We size the AMC, the visit window, and the response time.'),
    ('3', 'We take over operations', 'Engineers arrive, jobs are tracked, and the line stays open.'),
    ('4', '24/7 support', 'A desk that stays on the job until the kitchen is signed off.'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: const Color(0xFFF3F6F1),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABOUT EVERGREEN',
                style: LandingTypography.eyebrow.copyWith(letterSpacing: 1.8),
              ),
              const SizedBox(height: 12),
              Text(
                'Built for reliable operations',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 32 : 44,
                ),
              ),
              const SizedBox(height: 32),
              _ResponsiveGrid(
                minWidth: 220,
                children: _steps
                    .map(
                      (step) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: LandingColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              step.$1,
                              style: const TextStyle(
                                fontFamily: LandingTypography.fontFamily,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(step.$2, style: LandingTypography.featureCardTitle),
                          const SizedBox(height: 6),
                          Text(
                            step.$3,
                            style: LandingTypography.introBody.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Performance extends StatelessWidget {
  const _Performance();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PerformanceCopy(),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        LandingAssets.techMeera,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(child: _PerformanceCopy()),
                    const SizedBox(width: 40),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          LandingAssets.techSara,
                          height: 380,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PerformanceCopy extends StatelessWidget {
  const _PerformanceCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built for performance.\nTrusted by industry leaders.',
          style: LandingTypography.sectionSubtitle.copyWith(fontSize: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'We focus on reliability, safety, and uptime so a kitchen can keep feeding people without a surprise stop.',
          style: LandingTypography.introBody,
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MiniStat(title: 'Certified engineers', body: 'Background-checked before they arrive.'),
            _MiniStat(title: 'Same-day response', body: 'When the line is down, we move.'),
            _MiniStat(title: 'Transparent pricing', body: 'You approve the job before work starts.'),
            _MiniStat(title: 'AMC coverage', body: 'Planned maintenance for larger kitchens.'),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LandingTypography.featureCardTitle),
          const SizedBox(height: 4),
          Text(body, style: LandingTypography.introBody.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _AmcPlans extends StatelessWidget {
  const _AmcPlans({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: const Color(0xFFF7F8F5),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMC PLANS',
                style: LandingTypography.eyebrow.copyWith(letterSpacing: 1.8),
              ),
              const SizedBox(height: 12),
              Text(
                'Flexible AMC planning for your kitchen',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 32 : 40,
                ),
              ),
              const SizedBox(height: 32),
              _ResponsiveGrid(
                minWidth: 260,
                children: [
                  _PlanCard(
                    title: 'Basic Plan',
                    points: const [
                      'Quarterly preventive visits',
                      'Standard response window',
                      'Job notes after every visit',
                    ],
                    onTap: onBook,
                  ),
                  _PlanCard(
                    title: 'Standard Plan',
                    highlight: true,
                    points: const [
                      'Monthly preventive visits',
                      'Priority same-day repair',
                      'Spare parts coordination',
                    ],
                    onTap: onBook,
                  ),
                  _PlanCard(
                    title: 'Premium Plan',
                    points: const [
                      'Dedicated engineer roster',
                      '24/7 emergency cover',
                      'Compliance reporting',
                    ],
                    onTap: onBook,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.points,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final List<String> points;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: highlight ? LandingColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.white : LandingColors.textDark,
            ),
          ),
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: highlight ? Colors.white : LandingColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 14,
                        height: 1.4,
                        color: highlight ? const Color(0xE6FFFFFF) : const Color(0xFF5C6B60),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GreenPill(
            label: 'Request a plan',
            onTap: onTap,
            light: highlight,
          ),
        ],
      ),
    );
  }
}

class _TrustedOrgs extends StatelessWidget {
  const _TrustedOrgs();

  static const _photos = [
    LandingAssets.techMeera,
    LandingAssets.techArjun,
    LandingAssets.techSara,
    LandingAssets.techNikhil,
    LandingAssets.whyKitchen,
    LandingAssets.heroBg,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trusted by leading organizations',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 30 : 40,
                ),
              ),
              const SizedBox(height: 24),
              _ResponsiveGrid(
                minWidth: 180,
                children: _photos
                    .map(
                      (path) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.asset(path, fit: BoxFit.cover),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoStrip extends StatelessWidget {
  const _LogoStrip();

  static const _names = [
    'Infosys',
    'Wipro',
    'TCS',
    'Google',
    'Accenture',
    'HCL',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Trusted by businesses across India.',
                style: LandingTypography.sectionSubtitle.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 28,
                runSpacing: 12,
                children: _names
                    .map(
                      (name) => Text(
                        name,
                        style: const TextStyle(
                          fontFamily: LandingTypography.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B918C),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesFaq extends StatefulWidget {
  const _ServicesFaq({required this.onContact});

  final VoidCallback onContact;

  @override
  State<_ServicesFaq> createState() => _ServicesFaqState();
}

class _ServicesFaqState extends State<_ServicesFaq> {
  int? _open = 0;

  static const _items = [
    (
      'What type of equipment do you service?',
      'Ranges, ovens, walk-ins, reach-ins, hoods, dishwashers, and the smaller machines on the pass — any commercial kitchen line.',
    ),
    (
      'Do you provide AMC for larger kitchens?',
      'Yes. Standard and Premium plans are built for multi-station and multi-site kitchens with monthly visits and reporting.',
    ),
    (
      'How fast can an engineer reach us?',
      'Emergency jobs are same-day in our service cities. AMC customers get a priority window written into the contract.',
    ),
    (
      'Do you work across brands of equipment?',
      'Yes. There is no manufacturer lock-in. We service the machine that is already on your line.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      color: const Color(0xFFF3F6F1),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Everything you need to know',
                style: LandingTypography.sectionSubtitle.copyWith(
                  fontSize: isMobile ? 30 : 40,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_items.length, (i) {
                final open = _open == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _open = open ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _items[i].$1,
                                    style: LandingTypography.faqQuestion,
                                  ),
                                ),
                                Icon(open ? Icons.remove : Icons.add, size: 20),
                              ],
                            ),
                            if (open) ...[
                              const SizedBox(height: 10),
                              Text(_items[i].$2, style: LandingTypography.faqAnswer),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onContact,
                child: const Text('Still have a question? Contact us'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.onAssess, required this.onContact});

  final VoidCallback onAssess;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: const Color(0xFF0E1711),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
        isMobile ? 20 : 80,
        isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Let’s keep your kitchen running.',
                textAlign: TextAlign.center,
                style: LandingTypography.sectionTitleWhite.copyWith(
                  fontSize: isMobile ? 32 : 48,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _GreenPill(label: 'Request a site assessment', onTap: onAssess),
                  _GreenPill(label: 'Contact us', onTap: onContact, outline: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconItem {
  const _IconItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _IconItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleIcon(icon: item.icon),
          const SizedBox(height: 16),
          Text(item.title, style: LandingTypography.featureCardTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(item.body, style: LandingTypography.introBody.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE7F2EA),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: LandingColors.primary),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    required this.minWidth,
  });

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / (minWidth + 16)).floor().clamp(1, 3);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: count == 1 ? 2.2 : 1.15,
          children: children,
        );
      },
    );
  }
}

class _GreenPill extends StatefulWidget {
  const _GreenPill({
    required this.label,
    required this.onTap,
    this.outline = false,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outline;
  final bool light;

  @override
  State<_GreenPill> createState() => _GreenPillState();
}

class _GreenPillState extends State<_GreenPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final outline = widget.outline;
    final light = widget.light;
    final bg = outline
        ? Colors.transparent
        : light
            ? Colors.white
            : (_hover ? const Color(0xFF0C4E19) : LandingColors.primary);
    final fg = outline
        ? Colors.white
        : light
            ? LandingColors.primary
            : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: outline ? Border.all(color: Colors.white54) : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
