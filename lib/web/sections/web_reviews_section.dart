import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// "Real kitchens. Real repairs." — a client-reviews band on a green gradient
/// with a center testimonial card and paging dots.
class WebReviewsSection extends StatefulWidget {
  const WebReviewsSection({super.key});

  @override
  State<WebReviewsSection> createState() => _WebReviewsSectionState();
}

class _WebReviewsSectionState extends State<WebReviewsSection> {
  int _index = 0;

  static const _reviews = [
    (
      'Lit again before service',
      'The range wasn\'t igniting. The service engineer arrived in the window and had it working before the meal rush.',
      'Anita Desai',
      'Kitchen lead',
      5
    ),
    (
      'Fridge back in an hour',
      'Walk-in was warming up fast. Diagnosed and fixed same day — no lost stock.',
      'Rahul Verma',
      'Store manager',
      5
    ),
    (
      'Hood cleared and quiet',
      'The extraction hood was rattling. Clean fix, fair price shown upfront.',
      'Sara Qureshi',
      'Head chef',
      4
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);
    final r = _reviews[_index];

    return WebSection(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF138A2A), Color(0xFF0C4A18)],
      ),
      child: Column(
        children: [
          Text(
            'CUSTOMER REVIEWS',
            style: WebTokens.eyebrow(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Text(
            'Real kitchens.\nReal repairs.',
            textAlign: TextAlign.center,
            style: WebTokens.display(mobile ? 30 : 46, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 760),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: WebTokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$1, style: WebTokens.heading(mobile ? 20 : 26)),
                const SizedBox(height: 14),
                Text('“${r.$2}”', style: WebTokens.bodyText(15)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < r.$5 ? Icons.star : Icons.star_border,
                        size: 18,
                        color: WebTokens.star,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      '${r.$5}.0',
                      style: WebTokens.bodyText(13, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: WebTokens.mintSoft,
                      child: Text(
                        r.$3[0],
                        style: const TextStyle(
                          fontFamily: WebTokens.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: WebTokens.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$3,
                          style: WebTokens.bodyText(
                            14,
                            color: WebTokens.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(r.$4, style: WebTokens.bodyText(12.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _reviews.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: i == _index ? 1 : 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
