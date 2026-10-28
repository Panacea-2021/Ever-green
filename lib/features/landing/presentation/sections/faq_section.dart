import 'package:flutter/material.dart';

import '../landing_theme.dart';

class FaqData {
  final String question;
  final String answer;

  const FaqData({
    required this.question,
    required this.answer,
  });
}

/// FAQ section matching the provided screenshot.
/// Search stays in the top pill only — never inside a question card.
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
  int? _expandedIndex = 1;
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
    final q = _searchQuery.toLowerCase();
    return _faqs
        .where((faq) =>
            faq.question.toLowerCase().contains(q) ||
            faq.answer.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ColoredBox(
      color: const Color(0xFFEAF8EF),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 80,
          vertical: isMobile ? 56 : 80,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Text(
                  'Ask your Doubts here',
                  style: LandingTypography.eyebrow.copyWith(
                    color: const Color(0xFF7A847C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'FAQs',
                  style: LandingTypography.sectionTitle.copyWith(
                    fontSize: isMobile ? 42 : 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 28),
                _SearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                ..._buildFaqCards(),
                SizedBox(height: isMobile ? 20 : 24),
                _Footer(onContactUs: widget.onContactUs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaqCards() {
    final faqs = _filteredFaqs;
    return List.generate(faqs.length, (index) {
      final originalIndex = _faqs.indexOf(faqs[index]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _FaqCard(
          data: faqs[index],
          number: '${originalIndex + 1}',
          isExpanded: _expandedIndex == originalIndex,
          onTap: () {
            setState(() {
              _expandedIndex =
                  _expandedIndex == originalIndex ? null : originalIndex;
            });
          },
        ),
      );
    });
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8EEE9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color(0xFF9AA39C)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search questions',
                hintStyle: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  color: Color(0xFF9AA39C),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 14,
                color: LandingColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.onContactUs});

  final VoidCallback? onContactUs;

  @override
  Widget build(BuildContext context) {
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
          onTap: onContactUs,
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

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.data,
    required this.number,
    required this.isExpanded,
    required this.onTap,
  });

  final FaqData data;
  final String number;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isExpanded ? 24 : 999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isExpanded ? 24 : 999),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            22,
            isExpanded ? 18 : 16,
            18,
            isExpanded ? 18 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isExpanded ? 24 : 999),
            border: Border.all(
              color: isExpanded ? LandingColors.primary : Colors.transparent,
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      number,
                      style: LandingTypography.faqNumber.copyWith(
                        color: const Color(0xFF9AA39C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.question,
                      style: LandingTypography.faqQuestion.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.close : Icons.add,
                    size: 20,
                    color: isExpanded
                        ? LandingColors.primary
                        : const Color(0xFF6B746E),
                  ),
                ],
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 30, top: 10, right: 8),
                  child: Text(
                    data.answer,
                    style: LandingTypography.faqAnswer.copyWith(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF6B746E),
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
