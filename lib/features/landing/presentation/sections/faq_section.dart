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
  /// Nothing is open until the visitor chooses a question.
  int? _expandedIndex;
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
    final faqs = _filteredFaqs;

    return ColoredBox(
      color: const Color(0xFFF4F7F5),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 72,
          vertical: isMobile ? 48 : 64,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ASK YOUR DOUBTS HERE',
                  textAlign: TextAlign.center,
                  style: LandingTypography.eyebrow.copyWith(
                    color: LandingColors.primary,
                    letterSpacing: 1.6,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'FAQs',
                  textAlign: TextAlign.center,
                  style: LandingTypography.sectionTitle.copyWith(
                    fontSize: isMobile ? 34 : 44,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: SizedBox(
                    width: 48,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: LandingColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Search a question, then open the one you want.',
                  textAlign: TextAlign.center,
                  style: LandingTypography.introBody.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6B746E),
                  ),
                ),
                const SizedBox(height: 22),
                _SearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _expandedIndex = null;
                  }),
                  onClear: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _expandedIndex = null;
                  }),
                ),
                const SizedBox(height: 14),
                if (faqs.isEmpty)
                  const _EmptySearch()
                else
                  _FaqList(
                    children: [
                      for (var i = 0; i < faqs.length; i++)
                        _FaqRow(
                          data: faqs[i],
                          number: '${_faqs.indexOf(faqs[i]) + 1}',
                          isExpanded: _expandedIndex == _faqs.indexOf(faqs[i]),
                          onTap: () {
                            final originalIndex = _faqs.indexOf(faqs[i]);
                            setState(() {
                              _expandedIndex = _expandedIndex == originalIndex
                                  ? null
                                  : originalIndex;
                            });
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                _Footer(onContactUs: widget.onContactUs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 52,
      padding: const EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? LandingColors.primary : const Color(0xFFD5DED8),
          width: focused ? 1.5 : 1,
        ),
        boxShadow: focused ? LandingShadows.searchShadow : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search,
              size: 18,
              color: LandingColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              decoration: const InputDecoration(
                hintText: 'Search questions',
                hintStyle: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  color: Color(0xFF8B948E),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
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
          if (hasText)
            IconButton(
              onPressed: widget.onClear,
              tooltip: 'Clear search',
              icon: const Icon(Icons.close, size: 18),
              color: const Color(0xFF6B746E),
            ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Text(
        'No questions match that search.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: LandingTypography.fontFamily,
          fontSize: 14,
          color: Color(0xFF6B746E),
        ),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          children[i],
        ],
      ],
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

class _FaqRow extends StatelessWidget {
  const _FaqRow({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? LandingColors.primary : const Color(0xFFE3EAE5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? LandingColors.primary
                            : const Color(0xFFE7F6EC),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        number,
                        style: LandingTypography.faqNumber.copyWith(
                          color:
                              isExpanded ? Colors.white : LandingColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.question,
                        style: LandingTypography.faqQuestion.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 22,
                      color: isExpanded
                          ? LandingColors.primary
                          : const Color(0xFF6B746E),
                    ),
                  ],
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8, right: 28),
                    child: Text(
                      data.answer,
                      style: LandingTypography.faqAnswer.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: const Color(0xFF5C6B60),
                      ),
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
