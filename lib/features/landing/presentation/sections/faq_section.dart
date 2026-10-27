import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Data model for a FAQ item.
class FaqData {
  final String question;
  final String answer;

  const FaqData({
    required this.question,
    required this.answer,
  });
}

/// Common Questions/FAQ section with searchable expandable cards.
class FaqSection extends StatefulWidget {
  final VoidCallback? onContactUs;

  const FaqSection({
    super.key,
    this.onContactUs,
  });

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int? _expandedIndex = 1; // Second item expanded by default
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<FaqData> _faqs = [
    FaqData(
      question: 'What equipment do you repair?',
      answer:
          'Ranges, ovens, walk-ins, reach-ins, hoods, microwaves, and the smaller machines on the pass. If it sits on the line and it has stopped, send it through.',
    ),
    FaqData(
      question: 'How soon can a service engineer arrive?',
      answer:
          'Same-day visits are the usual window when the line is down. You pick the time when you book, and the service engineer works inside that window.',
    ),
    FaqData(
      question: 'Do I approve the price before any work?',
      answer:
          'Yes. The price is sent before a panel is opened. Nothing extra lands on the bill after you sign off.',
    ),
    FaqData(
      question: 'What stays covered after sign-off?',
      answer:
          'Covered repairs stay covered. The warranty is written into the job note before the service engineer leaves the kitchen.',
    ),
    FaqData(
      question: 'Do I need to be in the kitchen for the visit?',
      answer:
          'Someone who can open the kitchen and sign the job off needs to be there. Service can keep running around the repair.',
    ),
    FaqData(
      question: 'How do I book a repair?',
      answer:
          'Send the kitchen name and a mobile number. A service engineer takes the range, the fridge, or whatever left the line down.',
    ),
  ];

  List<FaqData> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where((faq) =>
            faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      color: LandingColors.bgMint,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: isMobile ? 60 : 88,
      ),
      child: Stack(
        children: [
          // Decorative icons must be Positioned so this Stack can size
          // itself from the FAQ content. A non-positioned Stack of only
          // Positioned children is unbounded inside a scroll view.
          if (!isMobile)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildDecorativeIcons(),
              ),
            ),

          // Main content
          Center(
            child: SizedBox(
              width: isMobile ? double.infinity : 760,
              child: Column(
                children: [
                  // Eyebrow
                  Text(
                    'Ask your Doubts here',
                    style: LandingTypography.eyebrow,
                  ),

                  SizedBox(height: isMobile ? 16 : 28),

                  // Title
                  Text(
                    'FAQs',
                    style: LandingTypography.sectionTitle.copyWith(
                      fontSize: isMobile ? 40 : 56,
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 28),

                  // Search bar
                  _buildSearchBar(isMobile),

                  SizedBox(height: isMobile ? 20 : 28),

                  // FAQ cards
                  ..._buildFaqCards(isMobile),

                  SizedBox(height: isMobile ? 24 : 28),

                  // Footer
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcons() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 78,
          top: 72,
          child: SvgPicture.asset(
            LandingAssets.iconPot,
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
        Positioned(
          right: 72,
          top: 96,
          child: SvgPicture.asset(
            LandingAssets.iconUtensils,
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
        Positioned(
          left: 64,
          top: 430,
          child: SvgPicture.asset(
            LandingAssets.iconFlame,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
        Positioned(
          right: 56,
          top: 390,
          child: SvgPicture.asset(
            LandingAssets.iconHat,
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
        Positioned(
          left: 96,
          top: 760,
          child: SvgPicture.asset(
            LandingAssets.iconFridge,
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
        Positioned(
          right: 100,
          top: 740,
          child: SvgPicture.asset(
            LandingAssets.iconCup,
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              LandingColors.primary.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: LandingShadows.searchShadow,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            LandingAssets.iconSearch,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              LandingColors.textLight,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search questions',
                hintStyle: LandingTypography.faqNumber.copyWith(
                  color: LandingColors.textLight,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: LandingTypography.faqQuestion.copyWith(
                fontSize: 14,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close,
                size: 18,
                color: LandingColors.textLight,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFaqCards(bool isMobile) {
    final faqs = _filteredFaqs;
    return List.generate(faqs.length, (index) {
      final originalIndex = _faqs.indexOf(faqs[index]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _FaqCard(
          data: faqs[index],
          number: (originalIndex + 1).toString(),
          isExpanded: _expandedIndex == originalIndex,
          onTap: () {
            setState(() {
              if (_expandedIndex == originalIndex) {
                _expandedIndex = null;
              } else {
                _expandedIndex = originalIndex;
              }
            });
          },
        ),
      );
    });
  }

  Widget _buildFooter(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Have any other questions?',
          style: LandingTypography.introBody.copyWith(
            fontSize: 14,
            color: const Color(0xFF7A847C),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: widget.onContactUs,
          child: Text(
            'Contact Us',
            style: LandingTypography.buttonPrimary.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

/// FAQ card with expand/collapse animation.
class _FaqCard extends StatefulWidget {
  final FaqData data;
  final String number;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqCard({
    required this.data,
    required this.number,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard>
    with SingleTickerProviderStateMixin {
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isExpanded
                  ? LandingColors.borderActive
                  : (_isHovered
                      ? LandingColors.primary.withOpacity(0.3)
                      : LandingColors.border),
              width: widget.isExpanded ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Number
                  Text(
                    widget.number,
                    style: LandingTypography.faqNumber,
                  ),

                  const SizedBox(width: 16),

                  // Question
                  Expanded(
                    child: Text(
                      widget.data.question,
                      style: LandingTypography.faqQuestion,
                    ),
                  ),

                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: SvgPicture.asset(
                      widget.isExpanded
                          ? LandingAssets.iconCollapse
                          : LandingAssets.iconExpand,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        widget.isExpanded
                            ? LandingColors.primary
                            : LandingColors.textGray,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),

              // Answer (animated)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 30, top: 10, right: 28),
                  child: Text(
                    widget.data.answer,
                    style: LandingTypography.faqAnswer,
                  ),
                ),
                crossFadeState: widget.isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
