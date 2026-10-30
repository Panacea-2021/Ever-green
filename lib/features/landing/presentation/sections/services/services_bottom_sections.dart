import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/routes.dart';
import '../../landing_theme.dart';
import 'services_common.dart';
import 'services_top_sections.dart' show SvcLogo;

class WhyChooseSection extends StatelessWidget {
  const WhyChooseSection({super.key});

  static const _features = [
    (
      Icons.workspace_premium_outlined,
      'Experienced & certified technicians',
      'Skilled professionals with industry expertise.'
    ),
    (
      Icons.support_agent_outlined,
      '24/7 support for critical operations',
      'Round-the-clock help when it matters most.'
    ),
    (
      Icons.timer_outlined,
      'Minimized equipment downtime',
      'Proactive maintenance and quick repairs.'
    ),
    (
      Icons.apartment_outlined,
      'Customized AMC for large facilities',
      'Flexible plans built around your scale.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = SvcLayout.isDesktop(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SvcEyebrow('Why choose Evergreen'),
        const SizedBox(height: 14),
        const SvcHeading(
          title: 'Built for performance.\n',
          highlight: 'Trusted by industry leaders.',
        ),
        const SizedBox(height: 14),
        const SvcBody(
          'We focus on reliability, safety and efficiency to ensure your '
          'kitchen operations run smoothly, every day.',
        ),
        const SizedBox(height: 32),
        SvcGrid(
          columns: svcColumns(context, desktop: 4, tablet: 4, mobile: 2),
          spacing: 18,
          runSpacing: 24,
          children: [
            for (final f in _features)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvcIconBox(f.$1, size: 42, light: true),
                  const SizedBox(height: 12),
                  Text(f.$2,
                      style: svcText(
                          size: 13.5, weight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(f.$3,
                      style: svcText(
                          size: 12, color: SvcColors.body, height: 1.5)),
                ],
              ),
          ],
        ),
      ],
    );

    return SvcSection(
      color: SvcColors.sectionMint,
      child: desktop
          ? Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: SvcImage(
                    SvcAssets.chef,
                    height: 440,
                    radius: 20,
                    alignment: Alignment.topCenter,
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(flex: 7, child: content),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SvcImage(
                  SvcAssets.chef,
                  height: 300,
                  radius: 20,
                  alignment: Alignment.topCenter,
                ),
                const SizedBox(height: 32),
                content,
              ],
            ),
    );
  }
}

class PlansSection extends StatefulWidget {
  const PlansSection({super.key, required this.onKnowMore});

  final VoidCallback onKnowMore;

  @override
  State<PlansSection> createState() => _PlansSectionState();
}

class _PlansSectionState extends State<PlansSection> {
  int? _selectedPlanIndex;

  static const _plans = [
    (
      'Basic Plan',
      ['Routine inspections', 'Basic servicing', 'Priority support'],
      false
    ),
    (
      'Standard Plan',
      [
        'Preventive maintenance',
        'Emergency repair support',
        'Compliance checks',
        'Detailed reports'
      ],
      true,
    ),
    (
      'Premium Plan',
      [
        'All Standard features',
        '24/7 priority support',
        'Dedicated engineer',
        'Equipment upgrades',
        'Customized service plans'
      ],
      false,
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
          eyebrow: 'AMC plans',
          title: 'Flexible AMC plans ',
          highlight: 'for your business.',
          body: 'Choose a plan that fits your operational needs and keeps '
              'your kitchen running without interruptions.',
        ),
        right: SvcGrid(
          columns: svcColumns(context, desktop: 3, tablet: 3, mobile: 1),
          spacing: 18,
          runSpacing: 18,
          children: [
            for (var i = 0; i < _plans.length; i++)
              _PlanCard(
                name: _plans[i].$1,
                features: _plans[i].$2,
                selected: _selectedPlanIndex == i,
                popular: _plans[i].$3,
                onSelect: () => setState(() => _selectedPlanIndex = i),
                onKnowMore: widget.onKnowMore,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.features,
    required this.selected,
    required this.popular,
    required this.onSelect,
    required this.onKnowMore,
  });

  final String name;
  final List<String> features;
  final bool selected;
  final bool popular;
  final VoidCallback onSelect;
  final VoidCallback onKnowMore;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : SvcColors.text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: selected ? SvcColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? SvcColors.primary : SvcColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: SvcColors.primary.withOpacity(0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: svcText(
                            size: 18, weight: FontWeight.w800, color: fg)),
                  ),
                  if (popular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LandingRadius.pill),
                      ),
                      child: Text(
                        'Most Popular',
                        style: svcText(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: SvcColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 17,
                        color: selected
                            ? SvcColors.highlightLight
                            : SvcColors.highlight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: svcText(
                            size: 13,
                            color: selected
                                ? Colors.white.withOpacity(0.9)
                                : SvcColors.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              const SizedBox(height: 12),
              SvcButton(
                label: 'Know more',
                compact: true,
                variant: selected
                    ? SvcButtonVariant.white
                    : SvcButtonVariant.outline,
                hoverColor: SvcColors.highlightLight,
                onTap: onKnowMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaseStudiesSection extends StatelessWidget {
  const CaseStudiesSection({super.key});

  static const _cases = [
    (
      SvcAssets.case1,
      'Major IT Campus – Bengaluru',
      'Reduced equipment downtime with a preventive AMC across multiple cafeterias.'
    ),
    (
      SvcAssets.case2,
      'University Hostel – Hyderabad',
      'Daily support for a high-volume mess kitchen serving thousands of students.'
    ),
    (
      SvcAssets.case3,
      'Hotel Chain – Pan India',
      'Standardised maintenance and reporting across properties nationwide.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SvcSection(
      color: Colors.white,
      vertical: SvcLayout.isMobile(context) ? 32 : 40,
      child: SvcSplit(
        leftFlex: 3,
        rightFlex: 7,
        left: const SvcIntro(
          eyebrow: 'Case studies',
          title: 'Trusted by leading ',
          highlight: 'organizations',
          body: "Here's how our clients benefit from working with Evergreen.",
        ),
        right: SvcGrid(
          columns: svcColumns(context, desktop: 3, tablet: 3, mobile: 1),
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final c in _cases)
              SvcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvcImage(
                      c.$1,
                      height: 150,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$2,
                              style:
                                  svcText(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(c.$3,
                              style: svcText(
                                  size: 12.5,
                                  color: SvcColors.body,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const _clients = [
    ('TCS', Color(0xFF1F3B87)),
    ('Infosys', Color(0xFF007CC3)),
    ('Wipro', Color(0xFF6B3FA0)),
    ('HCL', Color(0xFF0F5FA8)),
    ('Accenture', Color(0xFFA100FF)),
    ('Google', Color(0xFF4285F4)),
    ('amazon', Color(0xFF111111)),
    ('Microsoft', Color(0xFF5E5E5E)),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = SvcLayout.isDesktop(context);

    const intro = SvcIntro(
      eyebrow: 'Clients & testimonials',
      title: 'Trusted by businesses ',
      highlight: 'across India.',
    );

    final quote = SvcCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              size: 30, color: SvcColors.highlight),
          const SizedBox(height: 8),
          Text(
            'Evergreen has been our trusted partner for kitchen maintenance '
            'across our campus. Their response time and professionalism are '
            'excellent.',
            style: svcText(size: 14, height: 1.6),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: SvcColors.mintStrong,
                backgroundImage: AssetImage(SvcAssets.testimonial),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facilities Manager',
                      style: svcText(size: 13, weight: FontWeight.w700)),
                  Text('Leading IT Company',
                      style: svcText(size: 12, color: SvcColors.body)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final logos = SvcGrid(
      columns: 4,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in _clients)
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SvcColors.border),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  c.$1,
                  style:
                      svcText(size: 15, weight: FontWeight.w800, color: c.$2),
                ),
              ),
            ),
          ),
      ],
    );

    return SvcSection(
      color: SvcColors.sectionMint,
      child: desktop
          ? Row(
              children: [
                const Expanded(flex: 3, child: intro),
                const SizedBox(width: 32),
                Expanded(flex: 4, child: quote),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: logos),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                intro,
                const SizedBox(height: 28),
                quote,
                const SizedBox(height: 24),
                logos,
              ],
            ),
    );
  }
}

class ServicesFaqSection extends StatefulWidget {
  const ServicesFaqSection({super.key});

  @override
  State<ServicesFaqSection> createState() => _ServicesFaqSectionState();
}

class _ServicesFaqSectionState extends State<ServicesFaqSection> {
  static const _faqs = [
    (
      'What types of equipment do you service?',
      'We service cooking equipment, refrigeration, dishwashers, food '
          'preparation machines, and ventilation and exhaust systems from all '
          'major brands.',
    ),
    (
      'How quickly can you respond to emergencies?',
      'Our emergency support runs 24/7. Response times depend on your '
          'location and plan, and are agreed upfront in your AMC.',
    ),
    (
      'Do you provide AMC for large facilities?',
      'Yes. We design custom AMC plans for campuses, hostels, hospitals and '
          'hotel chains of any size.',
    ),
    (
      'Do you work with IT companies and hostels?',
      'Absolutely. IT campuses, corporate cafeterias, hostels and '
          'universities are among the organisations we support.',
    ),
  ];

  int? _open;

  @override
  Widget build(BuildContext context) {
    return SvcSection(
      color: Colors.white,
      child: SvcSplit(
        leftFlex: 4,
        rightFlex: 6,
        left: const SvcIntro(
          eyebrow: 'Frequently asked questions',
          title: 'Everything you need to know',
          body: 'Quick answers to common questions about our commercial '
              'kitchen services.',
        ),
        right: Column(
          children: [
            for (var i = 0; i < _faqs.length; i++)
              _FaqTile(
                question: _faqs[i].$1,
                answer: _faqs[i].$2,
                open: _open == i,
                onTap: () => setState(() => _open = _open == i ? null : i),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.open,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: open ? SvcColors.mint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: open ? SvcColors.mintStrong : SvcColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(question,
                            style: svcText(size: 14, weight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Icon(open ? Icons.remove : Icons.add,
                          size: 20, color: SvcColors.primary),
                    ],
                  ),
                  if (open) ...[
                    const SizedBox(height: 10),
                    Text(answer,
                        style: svcText(
                            size: 13, color: SvcColors.body, height: 1.6)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServicesCtaSection extends StatelessWidget {
  const ServicesCtaSection({
    super.key,
    required this.onAssessment,
    required this.onContact,
  });

  final VoidCallback onAssessment;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final desktop = SvcLayout.isDesktop(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SvcEyebrow('Ready to get started', light: true),
        const SizedBox(height: 14),
        const SvcHeading(
            title: "Let's keep your kitchen running.", light: true),
        const SizedBox(height: 12),
        const SvcBody(
          'Get reliable maintenance, repairs and AMC for your commercial '
          'kitchen equipment. Request a free site assessment today.',
          light: true,
        ),
      ],
    );

    final buttons = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SvcButton(
          label: 'Request a site assessment',
          variant: SvcButtonVariant.white,
          onTap: onAssessment,
        ),
        SvcButton(
          label: 'Contact our team',
          variant: SvcButtonVariant.outlineLight,
          onTap: onContact,
        ),
      ],
    );

    return SvcSection(
      decoration: const BoxDecoration(
        color: SvcColors.primaryDeep,
        image: DecorationImage(
          image: AssetImage(SvcAssets.cta),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xE00B3B1E), BlendMode.srcOver),
        ),
      ),
      child: desktop
          ? Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 40),
                buttons,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 24), buttons],
            ),
    );
  }
}

String _footerRoute(String link) => switch (link) {
      'Preventive Maintenance' ||
      'Emergency Repairs' ||
      'Equipment Installation' ||
      'Deep Cleaning' ||
      'AMC & Compliance' ||
      'AMC Plans' ||
      'Case Studies' =>
        Routes.services,
      'IT Campuses' ||
      'Corporate Cafeterias' ||
      'Hostels & Universities' ||
      'Hotels & Resorts' ||
      'Hospitals' =>
        Routes.industries,
      'About Us' => Routes.about,
      'How It Works' => Routes.howItWorks,
      'FAQs' => Routes.home,
      'Privacy Policy' => Routes.privacy,
      _ => throw StateError('No route configured for footer link "$link".'),
    };

class ServicesFooter extends StatelessWidget {
  const ServicesFooter({super.key, required this.onBook});

  final VoidCallback onBook;

  static const _columns = [
    (
      'Services',
      [
        'Preventive Maintenance',
        'Emergency Repairs',
        'Equipment Installation',
        'Deep Cleaning',
        'AMC & Compliance'
      ]
    ),
    (
      'Industries',
      [
        'IT Campuses',
        'Corporate Cafeterias',
        'Hostels & Universities',
        'Hotels & Resorts',
        'Hospitals'
      ]
    ),
    (
      'Company',
      [
        'About Us',
        'How It Works',
        'AMC Plans',
        'Case Studies',
        'FAQs',
        'Privacy Policy'
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = SvcLayout.isDesktop(context);
    final mobile = SvcLayout.isMobile(context);

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SvcLogo(light: true),
        const SizedBox(height: 14),
        Text(
          'Reliable maintenance, repairs and AMC for commercial kitchens '
          'across India.',
          style: svcText(
              size: 13, height: 1.6, color: Colors.white.withOpacity(0.6)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final icon in const [
              LandingAssets.socialInstagram,
              LandingAssets.socialFacebook,
              LandingAssets.socialX,
              LandingAssets.socialLinkedin,
            ])
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    icon,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    Widget linkColumn(String title, List<String> links) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: svcText(
                  size: 12,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white),
            ),
            const SizedBox(height: 14),
            for (final link in links)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go(_footerRoute(link)),
                    child: Text(
                      link,
                      style: svcText(
                        size: 13,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

    final contact = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT',
          style: svcText(
              size: 12,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white),
        ),
        const SizedBox(height: 14),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onBook,
            child: Text(
              'Book a service',
              style: svcText(
                  size: 13,
                  weight: FontWeight.w600,
                  color: SvcColors.highlightLight),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final city in const ['Hyderabad', 'Bengaluru'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go(Routes.contact),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.white.withOpacity(0.65)),
                    const SizedBox(width: 6),
                    Text(city,
                        style: svcText(
                            size: 13, color: Colors.white.withOpacity(0.65))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    final bottomText =
        svcText(size: 12.5, color: Colors.white.withOpacity(0.5));

    return Container(
      width: double.infinity,
      color: SvcColors.footer,
      padding: EdgeInsets.only(top: mobile ? 44 : 60, bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SvcLayout.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SvcLayout.hPad(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: brand),
                      for (final c in _columns)
                        Expanded(flex: 2, child: linkColumn(c.$1, c.$2)),
                      Expanded(flex: 2, child: contact),
                    ],
                  )
                else
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      SizedBox(width: double.infinity, child: brand),
                      for (final c in _columns)
                        SizedBox(width: 170, child: linkColumn(c.$1, c.$2)),
                      SizedBox(width: 170, child: contact),
                    ],
                  ),
                const SizedBox(height: 36),
                Divider(color: Colors.white.withOpacity(0.12), height: 1),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 10,
                  spacing: 24,
                  children: [
                    Text(
                        '© ${DateTime.now().year} Evergreen. All rights reserved.',
                        style: bottomText),
                    Wrap(
                      spacing: 24,
                      children: [
                        InkWell(
                          onTap: () => context.go(Routes.privacy),
                          child: Text('Privacy Policy', style: bottomText),
                        ),
                        InkWell(
                          onTap: () => context.go(Routes.terms),
                          child: Text('Terms of Service', style: bottomText),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
