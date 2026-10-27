import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Data model for a technician card.
class TechnicianData {
  final String name;
  final String specialty;
  final String experience;
  final String rating;
  final String imagePath;

  const TechnicianData({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.imagePath,
  });
}

/// Featured Technicians section with horizontally scrolling cards.
class TechniciansSection extends StatelessWidget {
  final VoidCallback? onViewAll;

  const TechniciansSection({
    super.key,
    this.onViewAll,
  });

  static const List<TechnicianData> _technicians = [
    TechnicianData(
      name: 'Meera Iyer',
      specialty: 'Ranges and ovens, from a dead burner to a full line down.',
      experience: '9 years',
      rating: '4.9',
      imagePath: LandingAssets.techMeera,
    ),
    TechnicianData(
      name: 'Arjun Patel',
      specialty: 'Refrigeration for walk-ins, reach-ins, and prep fridges.',
      experience: '7 years',
      rating: '4.8',
      imagePath: LandingAssets.techArjun,
    ),
    TechnicianData(
      name: 'Sara Qureshi',
      specialty: 'Hoods and ventilation, filters, fans, and makeup air.',
      experience: '6 years',
      rating: '4.9',
      imagePath: LandingAssets.techSara,
    ),
    TechnicianData(
      name: 'Nikhil Rao',
      specialty: 'Microwaves, combi ovens, and the small machines on the pass.',
      experience: '11 years',
      rating: '4.7',
      imagePath: LandingAssets.techNikhil,
    ),
    TechnicianData(
      name: 'Leela Nair',
      specialty: 'Warewashers and the machines that keep the dish pit moving.',
      experience: '5 years',
      rating: '4.8',
      imagePath: LandingAssets.techLeela,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3FBF5),
      child: GestureDetector(
        onTap: onViewAll,
        child: Image.asset(
          LandingAssets.featuredTechnicians,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const SizedBox(height: 240),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Service Engineers',
              style: LandingTypography.sectionTitle.copyWith(
                fontSize: isMobile ? 32 : 56,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scroll the people who take the range, the fridge, and the hood.',
              style: LandingTypography.introBody.copyWith(
                color: LandingColors.textSecondary,
              ),
            ),
          ],
        ),

        // View all button (desktop only)
        if (!isMobile)
          Positioned(
            top: 6,
            right: 0,
            child: _ViewAllButton(onTap: onViewAll),
          ),
      ],
    );
  }

  Widget _buildCardsRow(bool isMobile) {
    return SizedBox(
      height: isMobile ? 380 : 463,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _technicians.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return _TechnicianCard(
            data: _technicians[index],
            isMobile: isMobile,
          );
        },
      ),
    );
  }
}

/// View All button.
class _ViewAllButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _ViewAllButton({this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: LandingColors.primaryDark.withOpacity(0.15),
            ),
          ),
          child: Text(
            'View all',
            style: LandingTypography.buttonPrimary.copyWith(
              color: LandingColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Technician card with photo, name, specialty, and badges.
class _TechnicianCard extends StatefulWidget {
  final TechnicianData data;
  final bool isMobile;

  const _TechnicianCard({
    required this.data,
    required this.isMobile,
  });

  @override
  State<_TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<_TechnicianCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isMobile ? 240.0 : 300.0;
    final cardHeight = widget.isMobile ? 380.0 : 463.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardWidth,
        height: cardHeight,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              Image.asset(
                widget.data.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: LandingColors.primary.withOpacity(0.3),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),

              // Gradient shade
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.88),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),

              // Details overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    widget.isMobile ? 16 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        widget.data.name,
                        style: LandingTypography.techName.copyWith(
                          fontSize: widget.isMobile ? 22 : 26,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Specialty
                      Text(
                        widget.data.specialty,
                        style: LandingTypography.techDescription.copyWith(
                          fontSize: widget.isMobile ? 12 : 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Badges
                      Row(
                        children: [
                          _Badge(label: widget.data.experience),
                          const SizedBox(width: 8),
                          _RatingBadge(rating: widget.data.rating),
                        ],
                      ),
                    ],
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

/// Experience badge.
class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: LandingTypography.techBadge,
      ),
    );
  }
}

/// Rating badge with star icon.
class _RatingBadge extends StatelessWidget {
  final String rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            LandingAssets.stars,
            width: 11,
            height: 11,
            colorFilter: const ColorFilter.mode(
              Colors.amber,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: LandingTypography.techBadge,
          ),
        ],
      ),
    );
  }
}
