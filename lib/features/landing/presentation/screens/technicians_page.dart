import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../landing_theme.dart';
import '../sections/landing_site_header.dart';
import '../sections/services/services_bottom_sections.dart';

/// Public "Meet our technicians" page, opened from the landing page's
/// "View all technicians" button.
class TechniciansPage extends StatelessWidget {
  const TechniciansPage({super.key});

  static const List<_Technician> _technicians = [
    _Technician(
      name: 'Meera Iyer',
      specialty: 'Kitchen Appliance Specialist',
      image: LandingAssets.techMeera,
      rating: '4.9',
      reviews: '320',
      experience: '8 years',
      location: 'Hyderabad',
      tags: ['Ovens', 'Hobs', 'Cookers'],
      description:
          'Heat-appliance expert for range and oven calibration, burner '
          'servicing and complete kitchen safety diagnostics.',
    ),
    _Technician(
      name: 'Arjun Patel',
      specialty: 'Refrigeration & Cooling Expert',
      image: LandingAssets.techArjun,
      rating: '4.8',
      reviews: '280',
      experience: '9 years',
      location: 'Bengaluru',
      tags: ['Fridges', 'Freezers', 'Cold Rooms'],
      description:
          'Keeps walk-ins, chillers and display fridges at temperature with '
          'gas charging, compressor checks and leak repair.',
    ),
    _Technician(
      name: 'Sara Qureshi',
      specialty: 'Ventilation & Hood Specialist',
      image: LandingAssets.techSara,
      rating: '4.9',
      reviews: '310',
      experience: '7 years',
      location: 'Hyderabad',
      tags: ['Hoods', 'Ducting', 'Filters'],
      description:
          'Hood, ducting and exhaust specialist focused on airflow, filter '
          'servicing and kitchen air-quality compliance.',
    ),
    _Technician(
      name: 'Nikhil Rao',
      specialty: 'Microwave & Small Appliance Expert',
      image: LandingAssets.techNikhil,
      rating: '4.7',
      reviews: '260',
      experience: '6 years',
      location: 'Bengaluru',
      tags: ['Microwaves', 'Dishwashers', 'Mixers'],
      description:
          'Handles microwaves, dishwashers and small kitchen appliances, '
          'from board-level fixes to planned replacements.',
    ),
    _Technician(
      name: 'Leela Nair',
      specialty: 'Laundry & Ice Machine Specialist',
      image: LandingAssets.techLeela,
      rating: '4.6',
      reviews: '190',
      experience: '5 years',
      location: 'Hyderabad',
      tags: ['Washers', 'Dryers', 'Ice Machines'],
      description:
          'Washing machines, dryers and ice machines kept running with '
          'preventive servicing and fast breakdown support.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;

    void bookRepair() => showWebsiteLoginDialog(context);

    return Scaffold(
      backgroundColor: LandingColors.bgMain,
      body: Column(
        children: [
          LandingSiteHeader(
            onHome: () => context.go(Routes.home),
            onServices: () => context.go(Routes.services),
            onIndustries: () => context.go(Routes.industries),
            onAbout: () => context.go(Routes.about),
            onHowItWorks: () => context.go(Routes.howItWorks),
            onContact: () => context.go(Routes.contact),
            onPrivacy: () => context.go(Routes.privacy),
            onBookRepair: bookRepair,
            onSignIn: bookRepair,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _PageIntro(compact: compact),
                  _TrustStrip(compact: compact),
                  _TechnicianGrid(
                    technicians: _technicians,
                    onBook: bookRepair,
                  ),
                  const _AssuranceNote(),
                  ServicesCtaSection(
                    onAssessment: bookRepair,
                    onContact: bookRepair,
                  ),
                  ServicesFooter(onBook: bookRepair),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page intro
// ---------------------------------------------------------------------------

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, compact ? 40 : 64, 20, compact ? 24 : 32),
      child: Column(
        children: [
          const Text(
            'OUR SERVICE EXPERTS',
            textAlign: TextAlign.center,
            style: LandingTypography.eyebrow,
          ),
          const SizedBox(height: 14),
          Text(
            'Meet our technicians',
            textAlign: TextAlign.center,
            style: LandingTypography.sectionTitle.copyWith(
              fontSize: compact ? 36 : 52,
              letterSpacing: compact ? -1.2 : -1.9,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Skilled, background-verified specialists ready to keep your '
              'commercial kitchen equipment running — from routine servicing '
              'to emergency breakdowns.',
              textAlign: TextAlign.center,
              style: LandingTypography.introBody.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trust strip
// ---------------------------------------------------------------------------

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.compact});

  final bool compact;

  static const _stats = [
    (Icons.verified_user_outlined, '100%', 'Background verified'),
    (Icons.star_rounded, '4.8/5', 'Average rating'),
    (Icons.handyman_outlined, '1,200+', 'Repairs completed'),
    (Icons.schedule, 'Same day', 'Response time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 28,
              vertical: compact ? 18 : 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EAE4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120D2917),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              spacing: compact ? 20 : 32,
              runSpacing: 18,
              children: [
                for (final stat in _stats)
                  _StatItem(
                    icon: stat.$1,
                    value: stat.$2,
                    label: stat.$3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: LandingColors.bgIconGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: LandingColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: LandingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: LandingColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

class _TechnicianGrid extends StatelessWidget {
  const _TechnicianGrid({required this.technicians, required this.onBook});

  final List<_Technician> technicians;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1000 ? 3 : (width >= 660 ? 2 : 1);
              const gap = 24.0;
              final cardWidth = ((width - gap * (columns - 1)) / columns)
                  .clamp(0.0, 420.0)
                  .toDouble();

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final technician in technicians)
                    SizedBox(
                      width: cardWidth,
                      child: _TechnicianCard(
                        technician: technician,
                        onBook: onBook,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatefulWidget {
  const _TechnicianCard({required this.technician, required this.onBook});

  final _Technician technician;
  final VoidCallback onBook;

  @override
  State<_TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<_TechnicianCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final technician = widget.technician;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hover ? const Color(0xFFCDE5D3) : const Color(0xFFE4EAE4),
          ),
          boxShadow: _hover
              ? LandingShadows.cardShadow
              : LandingShadows.smallCardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portrait photo. The source shots are 3:4; the frame is a shorter
            // near-square that anchors to the top so faces stay fully visible.
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.asset(
                    technician.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: LandingColors.bgMint,
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 64,
                          color: LandingColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: _VerifiedBadge(),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _RatingBadge(
                    rating: technician.rating,
                    reviews: technician.reviews,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.6,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        size: 15,
                        color: LandingColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          technician.specialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: LandingTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: technician.tags.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            technician.tags[i],
                            style: const TextStyle(
                              fontFamily: LandingTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2D25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: Text(
                      technician.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEDF1ED),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${technician.experience} exp · ${technician.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: LandingTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BookButton(onTap: widget.onBook),
                    ],
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

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LandingColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 13, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Verified',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.reviews});

  final String rating;
  final String reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0D2917),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFAC18)),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LandingColors.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($reviews)',
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: LandingColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LandingColors.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Book',
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lower content
// ---------------------------------------------------------------------------

class _AssuranceNote extends StatelessWidget {
  const _AssuranceNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 17,
            color: LandingColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Every engineer is background verified, insured and trained on '
              'commercial kitchen equipment.',
              textAlign: TextAlign.center,
              style: LandingTypography.introBody.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Technician {
  const _Technician({
    required this.name,
    required this.specialty,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.location,
    required this.tags,
    required this.description,
  });

  final String name;
  final String specialty;
  final String image;
  final String rating;
  final String reviews;
  final String experience;
  final String location;
  final List<String> tags;
  final String description;
}
