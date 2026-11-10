import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/users/data/user_provider.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// Featured Technicians — pulls the real technician list from the shared
/// [techniciansProvider] and renders dark photo cards with name + rating.
class WebFeaturedTechniciansSection extends ConsumerWidget {
  const WebFeaturedTechniciansSection({super.key});

  // Light specialty labels + ratings to decorate the cards (display only).
  static const _specialties = [
    'Ranges & hoods',
    'Fridges & walk-ins',
    'Microwaves & ovens',
    'Chillers & freezers',
    'General kitchen',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);
    final techs = ref.watch(techniciansProvider).take(5).toList();

    return WebSection(
      background: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Service Engineers',
                      style: WebTokens.display(mobile ? 30 : 44),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Meet the people who take the range, the fridge, '
                      'and the hood.',
                      style: WebTokens.bodyText(15),
                    ),
                  ],
                ),
              ),
              if (!mobile)
                WebButton(label: 'View all', filled: false, onTap: () {}),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 420,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: techs.isEmpty ? _specialties.length : techs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, i) {
                final name = techs.isEmpty ? 'Service Engineer' : techs[i].name;
                final spec = _specialties[i % _specialties.length];
                final rating = (4.6 + (i % 4) * 0.1).toStringAsFixed(1);
                return _TechCard(name: name, specialty: spec, rating: rating);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatefulWidget {
  const _TechCard({
    required this.name,
    required this.specialty,
    required this.rating,
  });
  final String name;
  final String specialty;
  final String rating;

  @override
  State<_TechCard> createState() => _TechCardState();
}

class _TechCardState extends State<_TechCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 290,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C3B25), Color(0xFF0E2416)],
          ),
          boxShadow: _hover ? WebTokens.cardShadow : WebTokens.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder (brand avatar block).
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: WebTokens.green.withValues(alpha: 0.35),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: WebTokens.heading(18, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.specialty,
                    style: WebTokens.bodyText(
                      13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: WebTokens.star),
                      const SizedBox(width: 6),
                      Text(
                        widget.rating,
                        style: WebTokens.bodyText(
                          13,
                          color: Colors.white,
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
      ),
    );
  }
}
