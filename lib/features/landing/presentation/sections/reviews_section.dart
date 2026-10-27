import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Data model for a review.
class ReviewData {
  final String headline;
  final String highlightWord;
  final String quote;
  final String reviewerName;
  final String reviewerRole;
  final String rating;
  final String photoPath;

  const ReviewData({
    required this.headline,
    required this.highlightWord,
    required this.quote,
    required this.reviewerName,
    required this.reviewerRole,
    required this.rating,
    required this.photoPath,
  });
}

/// Client Reviews section with gradient background and carousel.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  int _currentIndex = 0;
  late PageController _pageController;

  static const List<ReviewData> _reviews = [
    ReviewData(
      headline: 'Lit again before',
      highlightWord: 'before',
      quote:
          '"The range was lit again before service. They sent the price before they opened a panel."',
      reviewerName: 'Anita Desai',
      reviewerRole: 'Kitchen lead',
      rating: '5.0',
      photoPath: LandingAssets.reviewPhoto3,
    ),
    ReviewData(
      headline: 'Fixed in hours',
      highlightWord: 'hours',
      quote:
          '"Our walk-in went down during the lunch rush. The service engineer arrived within 2 hours and had it running before dinner service."',
      reviewerName: 'Rajesh Kumar',
      reviewerRole: 'Restaurant Owner',
      rating: '5.0',
      photoPath: LandingAssets.reviewPhoto2,
    ),
    ReviewData(
      headline: 'Transparent pricing',
      highlightWord: 'Transparent',
      quote:
          '"No hidden charges, no surprises. They quoted the exact price and stuck to it. Refreshing honesty."',
      reviewerName: 'Priya Sharma',
      reviewerRole: 'Cafe Manager',
      rating: '4.9',
      photoPath: LandingAssets.reviewPhoto4,
    ),
    ReviewData(
      headline: 'Professional service',
      highlightWord: 'Professional',
      quote:
          '"The service engineer was courteous, explained everything clearly, and cleaned up after the repair. True professionals."',
      reviewerName: 'Mohammed Ali',
      reviewerRole: 'Hotel F&B Director',
      rating: '5.0',
      photoPath: LandingAssets.reviewPhoto5,
    ),
    ReviewData(
      headline: 'Reliable partner',
      highlightWord: 'Reliable',
      quote:
          '"We\'ve been using Evergreen for all our kitchens across the city. Consistent quality every single time."',
      reviewerName: 'Sneha Reddy',
      reviewerRole: 'Operations Head',
      rating: '4.8',
      photoPath: LandingAssets.reviewPhoto1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 72,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LandingColors.reviewGradientStart,
            LandingColors.reviewGradientMid1,
            LandingColors.reviewGradientMid2,
            LandingColors.reviewGradientMid3,
            LandingColors.reviewGradientEnd,
          ],
          stops: [0.0, 0.22, 0.48, 0.74, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Eyebrow
          Text(
            'CUSTOMER REVIEWS',
            style: LandingTypography.eyebrowWhite,
          ),

          SizedBox(height: isMobile ? 16 : 28),

          // Title
          Text(
            'Real kitchens.\nReal repairs.',
            textAlign: TextAlign.center,
            style: LandingTypography.sectionTitleWhite.copyWith(
              fontSize: isMobile ? 40 : 64,
            ),
          ),

          SizedBox(height: isMobile ? 32 : 48),

          // Review carousel
          SizedBox(
            height: isMobile ? 480 : 400,
            child: _buildCarousel(isMobile),
          ),

          SizedBox(height: isMobile ? 24 : 32),

          // Pagination dots
          _buildPaginationDots(),
        ],
      ),
    );
  }

  Widget _buildCarousel(bool isMobile) {
    if (isMobile) {
      return PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _MobileReviewCard(data: _reviews[index]),
          );
        },
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Far left card (small)
        _SideCard(
          imagePath: _reviews[(_currentIndex - 2 + _reviews.length) % _reviews.length].photoPath,
          width: 78,
          height: 204,
        ),

        const SizedBox(width: 22),

        // Left card (medium)
        _SideCard(
          imagePath: _reviews[(_currentIndex - 1 + _reviews.length) % _reviews.length].photoPath,
          width: 112,
          height: 292,
        ),

        const SizedBox(width: 22),

        // Center card (main)
        _MainReviewCard(data: _reviews[_currentIndex]),

        const SizedBox(width: 22),

        // Right card (medium)
        _SideCard(
          imagePath: _reviews[(_currentIndex + 1) % _reviews.length].photoPath,
          width: 112,
          height: 292,
        ),

        const SizedBox(width: 22),

        // Far right card (small)
        _SideCard(
          imagePath: _reviews[(_currentIndex + 2) % _reviews.length].photoPath,
          width: 78,
          height: 204,
        ),
      ],
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_reviews.length, (index) {
        final isActive = index == _currentIndex;
        return GestureDetector(
          onTap: () => _goToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? LandingColors.primary
                  : LandingColors.primary.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}

/// Side preview card showing just the photo.
class _SideCard extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const _SideCard({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: LandingShadows.smallCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: LandingColors.primary.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

/// Main review card with quote, rating, and photo.
class _MainReviewCard extends StatelessWidget {
  final ReviewData data;

  const _MainReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 780,
      height: 360,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: LandingShadows.reviewCardShadow,
      ),
      child: Row(
        children: [
          // Left content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Headline and quote
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeadline(),
                      const SizedBox(height: 24),
                      Text(
                        data.quote,
                        style: LandingTypography.reviewQuote,
                      ),
                    ],
                  ),

                  // Footer with rating and meta
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRating(),
                      const SizedBox(height: 12),
                      _buildMeta(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right photo
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              data.photoPath,
              width: 336,
              height: 332,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 336,
                height: 332,
                color: LandingColors.primary.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    // Split headline to highlight specific word
    final parts = data.headline.split(data.highlightWord);
    
    return RichText(
      text: TextSpan(
        style: LandingTypography.reviewHeadline,
        children: [
          if (parts.isNotEmpty && parts[0].isNotEmpty)
            TextSpan(text: parts[0]),
          TextSpan(
            text: data.highlightWord,
            style: LandingTypography.reviewHeadline.copyWith(
              color: LandingColors.accentGreen,
            ),
          ),
          if (parts.length > 1 && parts[1].isNotEmpty)
            TextSpan(text: '\n${parts[1].trim()}'),
          if (parts.length <= 1 || parts[1].isEmpty)
            const TextSpan(text: '\nservice'),
        ],
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        // 5 stars
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SvgPicture.asset(
              LandingAssets.star,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.amber,
                BlendMode.srcIn,
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          data.rating,
          style: LandingTypography.reviewerName.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        _MetaBadge(
          label: data.reviewerName,
          isName: true,
        ),
        const SizedBox(width: 8),
        _MetaBadge(
          label: data.reviewerRole,
          isName: false,
        ),
      ],
    );
  }
}

/// Mobile review card (vertical layout).
class _MobileReviewCard extends StatelessWidget {
  final ReviewData data;

  const _MobileReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LandingShadows.reviewCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              data.photoPath,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: LandingColors.primary.withOpacity(0.2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Headline
          Text(
            '${data.headline}\nservice',
            style: LandingTypography.reviewHeadline.copyWith(
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 12),

          // Quote
          Text(
            data.quote,
            style: LandingTypography.reviewQuote.copyWith(
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Rating
          Row(
            children: [
              ...List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SvgPicture.asset(
                    LandingAssets.star,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Colors.amber,
                      BlendMode.srcIn,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                data.rating,
                style: LandingTypography.reviewerName.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Meta
          Row(
            children: [
              _MetaBadge(
                label: data.reviewerName,
                isName: true,
                isMobile: true,
              ),
              const SizedBox(width: 8),
              _MetaBadge(
                label: data.reviewerRole,
                isName: false,
                isMobile: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Meta badge (name or role).
class _MetaBadge extends StatelessWidget {
  final String label;
  final bool isName;
  final bool isMobile;

  const _MetaBadge({
    required this.label,
    required this.isName,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: isName
            ? LandingTypography.reviewerName.copyWith(
                fontSize: isMobile ? 11 : 12,
              )
            : LandingTypography.reviewerRole.copyWith(
                fontSize: isMobile ? 11 : 12,
              ),
      ),
    );
  }
}
