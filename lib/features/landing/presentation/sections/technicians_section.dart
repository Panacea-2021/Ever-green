import 'package:flutter/material.dart';

import '../landing_theme.dart';

class TechniciansSection extends StatefulWidget {
  const TechniciansSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  State<TechniciansSection> createState() => _TechniciansSectionState();
}

class _TechniciansSectionState extends State<TechniciansSection> {
  final _cardsController = ScrollController();
  int? _activeCard;
  int _activeArrow = 1;

  static const _cardGap = 16.0;
  static const _technicians = [
    (
      name: 'Meera Iyer',
      specialty: 'Kitchen Appliance Specialist',
      image: 'assets/images/landing/featured_tech_meera.png',
      rating: '4.9',
      reviews: '320+',
      tags: ['Ovens', 'Hobs', 'Cookers'],
      description: 'Expert in heat appliances and full kitchen diagnostics.',
    ),
    (
      name: 'Arjun Patel',
      specialty: 'Refrigeration & Cooling Expert',
      image: 'assets/images/landing/featured_tech_arjun.png',
      rating: '4.8',
      reviews: '280+',
      tags: ['Fridges', 'Freezers', 'Cold Rooms'],
      description: 'Specialist in refrigeration, walk-ins and cooling systems.',
    ),
    (
      name: 'Sara Qureshi',
      specialty: 'Ventilation & Hood Specialist',
      image: 'assets/images/landing/featured_tech_sara.png',
      rating: '4.9',
      reviews: '310+',
      tags: ['Hoods', 'Ventilation', 'Filters'],
      description: 'Expert in hoods, ventilation and air quality systems.',
    ),
    (
      name: 'Nikhil Rao',
      specialty: 'Microwave & Small Appliance Expert',
      image: 'assets/images/landing/featured_tech_nikhil.png',
      rating: '4.7',
      reviews: '260+',
      tags: ['Microwaves', 'Dishwashers', 'Appliances'],
      description:
          'Specialist in microwaves, dishwashers and small kitchen appliances.',
    ),
    (
      name: 'Leela Nair',
      specialty: 'Laundry Appliance Specialist',
      image: 'assets/images/landing/featured_tech_leela.png',
      rating: '4.6',
      reviews: '190+',
      tags: ['Washers', 'Dryers', 'Ice Machines'],
      description: 'Expert in washing machines, dryers and ice machines.',
    ),
    (
      name: 'Vikram Shah',
      specialty: 'Commercial Kitchen Repair Specialist',
      image: 'assets/images/landing/tech_nikhil.png',
      rating: '4.8',
      reviews: '240+',
      tags: ['Kitchen Equipment', 'Repairs', 'Maintenance'],
      description:
          'Specialist in reliable commercial kitchen equipment repairs.',
    ),
  ];

  @override
  void dispose() {
    _cardsController.dispose();
    super.dispose();
  }

  void _moveSelection(int offset, int arrowIndex, double cardExtent) {
    final current = _activeCard ?? 0;
    final next = (current + offset + _technicians.length) % _technicians.length;
    setState(() {
      _activeCard = next;
      _activeArrow = arrowIndex;
    });

    if (_cardsController.hasClients) {
      final position = _cardsController.position;
      final target = next < current && offset > 0
          ? 0.0
          : next > current && offset < 0
              ? position.maxScrollExtent
              : (position.pixels + offset * cardExtent)
                  .clamp(0.0, position.maxScrollExtent);
      _cardsController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 760;
        final horizontalPadding = compact ? 20.0 : 48.0;
        final contentWidth = (width - horizontalPadding * 2)
            .clamp(0.0, LandingSpacing.maxContentWidth);
        final wideHeader = contentWidth >= 1400;
        // Fixed card width so the carousel looks identical on every laptop/desktop
        // instead of stretching/shrinking with the viewport.
        final cardWidth = compact ? 260.0 : 270.0;
        final cardExtent = cardWidth + _cardGap;
        final imageHeight = cardWidth * 0.68;
        final cardHeight = imageHeight + 235;

        return Container(
          width: double.infinity,
          color: const Color(0xFFE3F3E7),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 48 : 72,
            horizontal: horizontalPadding,
          ),
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wideHeader)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _sectionHeading(
                            compact: false,
                            availableWidth: contentWidth,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _controls(cardExtent),
                      ],
                    )
                  else ...[
                    _sectionHeading(
                      compact: compact,
                      availableWidth: contentWidth,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: compact
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: _controls(cardExtent),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      controller: _cardsController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _technicians.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        width: _cardGap,
                      ),
                      itemBuilder: (context, index) {
                        final technician = _technicians[index];
                        return SizedBox(
                          width: cardWidth,
                          child: _TechnicianCard(
                            name: technician.name,
                            specialty: technician.specialty,
                            image: technician.image,
                            imageHeight: imageHeight,
                            rating: technician.rating,
                            reviews: technician.reviews,
                            tags: technician.tags,
                            description: technician.description,
                            selected: _activeCard == index,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeading({
    required bool compact,
    required double availableWidth,
  }) {
    final titleFontSize =
        compact ? (availableWidth / 7.0).clamp(12.0, 36.0) : 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE2F1E2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups, size: 15, color: LandingColors.primary),
              const SizedBox(width: 7),
              Text(
                'OUR EXPERTS',
                style: LandingTypography.eyebrow.copyWith(
                  color: LandingColors.primary,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: LandingTypography.sectionTitle.copyWith(
              fontSize: titleFontSize,
              height: 1.08,
              letterSpacing: compact ? -0.8 : -1.6,
            ),
            children: const [
              TextSpan(text: 'Featured '),
              TextSpan(
                text: 'Technicians',
                style: TextStyle(color: LandingColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Skilled, verified, and trusted professionals to keep your kitchen running smoothly.',
          style: LandingTypography.introBody.copyWith(
            fontSize: compact ? 14 : 15,
          ),
        ),
      ],
    );
  }

  Widget _controls(double cardExtent) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _arrowButton(
          icon: Icons.chevron_left,
          label: 'Previous technician',
          selected: _activeArrow == 0,
          onTap: () => _moveSelection(-1, 0, cardExtent),
        ),
        _arrowButton(
          icon: Icons.chevron_right,
          label: 'Next technician',
          selected: _activeArrow == 1,
          onTap: () => _moveSelection(1, 1, cardExtent),
        ),
        if (widget.onViewAll != null) ...[
          OutlinedButton(
            onPressed: widget.onViewAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: LandingColors.primary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD8E9DB)),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View all technicians'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: selected ? LandingColors.primary : Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: selected ? Colors.white : LandingColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatefulWidget {
  const _TechnicianCard({
    required this.name,
    required this.specialty,
    required this.image,
    required this.imageHeight,
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.description,
    required this.selected,
  });

  final String name;
  final String specialty;
  final String image;
  final double imageHeight;
  final String rating;
  final String reviews;
  final List<String> tags;
  final String description;
  final bool selected;

  static const _detailColor = Color(0xFF1F2D25);

  @override
  State<_TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<_TechnicianCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final technician = widget;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 26),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _hover ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _hover ? -8 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hover
                    ? const Color(0xFFCDE5D3)
                    : (technician.selected
                        ? LandingColors.primary
                        : const Color(0xFFE4EAE4)),
                width: technician.selected ? 2 : 1,
              ),
              boxShadow: _hover
                  ? LandingShadows.cardShadow
                  : LandingShadows.smallCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: technician.imageHeight,
                  width: double.infinity,
                  child: Image.asset(
                    technician.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              technician.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: LandingTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: LandingColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.star,
                              size: 15, color: Color(0xFFFFAC18),),
                          const SizedBox(width: 3),
                          Text(
                            '${technician.rating} ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LandingColors.textPrimary,
                            ),
                          ),
                          Text(
                            '(${technician.reviews})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2D25),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: LandingColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: Text(
                                technician.specialty,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2D25),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        height: 61,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              for (final tag in technician.tags)
                                _TagChip(label: tag),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        height: 54,
                        child: Text(
                          technician.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2D25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One equal-width skill chip. The label scales down slightly rather than
/// wrapping, so a row of chips always stays on a single line.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: _TechnicianCard._detailColor,
        ),
      ),
    );
  }
}
