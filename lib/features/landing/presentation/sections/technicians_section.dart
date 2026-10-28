import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

class TechnicianData {
  final String name;
  final String role;
  final String specialty;
  final String experience;
  final String rating;
  final String reviews;
  final List<String> tags;
  final int photoIndex;

  const TechnicianData({
    required this.name,
    required this.role,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.photoIndex,
  });
}

/// Featured Technicians — same photos and copy, sharp Flutter text.
class TechniciansSection extends StatelessWidget {
  const TechniciansSection({
    super.key,
    this.onViewAll,
  });

  final VoidCallback? onViewAll;

  static const List<TechnicianData> _technicians = [
    TechnicianData(
      name: 'Meera Iyer',
      role: 'Kitchen Appliance Specialist',
      specialty: 'Expert in heat appliances and full kitchen diagnostics.',
      experience: '9+ years',
      rating: '4.9',
      reviews: '320+',
      tags: ['Ovens', 'Hobs', 'Cookers'],
      photoIndex: 0,
    ),
    TechnicianData(
      name: 'Arjun Patel',
      role: 'Refrigeration & Cooling Expert',
      specialty: 'Specialist in refrigeration, walk-ins and cooling systems.',
      experience: '7+ years',
      rating: '4.8',
      reviews: '280+',
      tags: ['Fridges', 'Freezers', 'Cold Rooms'],
      photoIndex: 1,
    ),
    TechnicianData(
      name: 'Sara Qureshi',
      role: 'Ventilation & Hood Specialist',
      specialty: 'Expert in hoods, ventilation and air quality systems.',
      experience: '6+ years',
      rating: '4.9',
      reviews: '310+',
      tags: ['Hoods', 'Ventilation', 'Filters'],
      photoIndex: 2,
    ),
    TechnicianData(
      name: 'Nikhil Rao',
      role: 'Microwave & Small Appliance Expert',
      specialty:
          'Specialist in microwaves, dishwashers and small kitchen appliances.',
      experience: '11+ years',
      rating: '4.7',
      reviews: '260+',
      tags: ['Microwaves', 'Dishwashers', 'Appliances'],
      photoIndex: 3,
    ),
    TechnicianData(
      name: 'Leela Nair',
      role: 'Laundry Appliance Specialist',
      specialty: 'Expert in washing machines, dryers and ice machines.',
      experience: '5+ years',
      rating: '4.6',
      reviews: '190+',
      tags: ['Washers', 'Dryers', 'Ice Machines'],
      photoIndex: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return ColoredBox(
      color: const Color(0xFFF3FBF5),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 20 : 48,
          isMobile ? 48 : 56,
          isMobile ? 20 : 48,
          isMobile ? 48 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(isMobile: isMobile, onViewAll: onViewAll),
            SizedBox(height: isMobile ? 24 : 28),
            SizedBox(
              height: isMobile ? 390 : 410,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _technicians.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _TechnicianCard(data: _technicians[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isMobile,
    this.onViewAll,
  });

  final bool isMobile;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F6EA),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'OUR EXPERTS',
            style: LandingTypography.eyebrow.copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Featured Technicians',
          style: LandingTypography.sectionTitle.copyWith(
            fontSize: isMobile ? 32 : 44,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Skilled, verified, and trusted professionals to keep your kitchen running smoothly.',
          style: LandingTypography.introBody.copyWith(
            color: LandingColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onViewAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all technicians',
                style: LandingTypography.buttonPrimary.copyWith(
                  color: LandingColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: LandingColors.primaryDark,
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        actions,
      ],
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.data});

  final TechnicianData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 148,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PersonPhoto(index: data.photoIndex),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: _VerifiedChip(),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _ExperienceChip(
                      label: '${data.experience} Experience',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.name,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LandingColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.role,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: LandingColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                LandingAssets.star,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFF5B400),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${data.rating}  (${data.reviews})',
                style: const TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LandingColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: data.tags.map(_TagChip.new).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            data.specialty,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF6B746E),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonPhoto extends StatelessWidget {
  const _PersonPhoto({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const srcW = 1024.0;
        const srcH = 346.0;
        const cropW = 178.0;
        const cropH = 108.0;
        const originY = 126.0;
        final originX = 26.0 + index * 198.0;
        final scaleW = constraints.maxWidth / cropW;
        final scaleH = constraints.maxHeight / cropH;
        final scale = scaleW > scaleH ? scaleW : scaleH;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: srcW * scale,
            maxWidth: srcW * scale,
            minHeight: srcH * scale,
            maxHeight: srcH * scale,
            child: Transform.translate(
              offset: Offset(-originX * scale, -originY * scale),
              child: Image.asset(
                LandingAssets.featuredTechnicians,
                width: srcW * scale,
                height: srcH * scale,
                fit: BoxFit.fill,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LandingColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceChip extends StatelessWidget {
  const _ExperienceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xE6000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work_outline, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(0xFFF3F6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: LandingTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4A524C),
        ),
      ),
    );
  }
}
