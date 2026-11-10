import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// "FAQs" — a search box and a list of expandable question cards.
class WebFaqSection extends StatefulWidget {
  const WebFaqSection({super.key});

  @override
  State<WebFaqSection> createState() => _WebFaqSectionState();
}

class _WebFaqSectionState extends State<WebFaqSection> {
  int? _open = 0;
  String _query = '';

  static const _faqs = [
    (
      'What equipment do you repair?',
      'Ranges, hoods, fridges and walk-ins, microwaves, ovens, chillers and most commercial kitchen machines.'
    ),
    (
      'How soon can a service engineer arrive?',
      'Same-day visits are available in most areas. You\'ll see the exact arrival window when you book.'
    ),
    (
      'Do I approve the price before any work?',
      'Yes. The visit window and the price land in the app before anyone opens a panel.'
    ),
    (
      'What steps are part of the sign-off?',
      'The service engineer shares work notes and photos; you review, approve and rate the service.'
    ),
    (
      'Do I need to be on-site for the visit?',
      'A contact who can grant access is enough — you can track progress remotely.'
    ),
    (
      'How do I book a repair?',
      'Create a task with the machine and issue, and we assign a certified service engineer.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);
    final filtered = _faqs
        .where((f) => f.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return WebSection(
      background: Colors.white,
      child: Column(
        children: [
          Text('SUPPORT', style: WebTokens.eyebrow()),
          const SizedBox(height: 12),
          Text('FAQs', style: WebTokens.display(mobile ? 30 : 44)),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                // Search.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: WebTokens.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WebTokens.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: WebTokens.faint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: WebTokens.bodyText(14, color: WebTokens.ink),
                          decoration: const InputDecoration(
                            hintText: 'Search questions',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < filtered.length; i++)
                  _FaqCard(
                    faq: filtered[i],
                    expanded: _open == i,
                    onTap: () => setState(() => _open = _open == i ? null : i),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Have any other questions? ',
                      style: WebTokens.bodyText(14),
                    ),
                    Text(
                      'Contact Us',
                      style: WebTokens.bodyText(
                        14,
                        color: WebTokens.green,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });
  final (String, String) faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expanded ? WebTokens.green : WebTokens.line,
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(faq.$1, style: WebTokens.heading(15)),
                  ),
                  Icon(
                    expanded ? Icons.remove : Icons.add,
                    color: WebTokens.green,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(faq.$2, style: WebTokens.bodyText(14)),
              ),
            ),
        ],
      ),
    );
  }
}
