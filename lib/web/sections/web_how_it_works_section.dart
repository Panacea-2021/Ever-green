import 'package:flutter/material.dart';

import '../theme/web_tokens.dart';
import '../widgets/web_section.dart';

/// "From signup to sign-off in 5 steps" (Figma node 81-97).
///
/// A two-column header (eyebrow left, big heading + sub-copy right) over a row
/// of five tall, flat, square-cornered step cards. The first card is the
/// active one (green, with icon + title + description); the rest are collapsed
/// (white, with only the step label at the top and a faint centered icon).
class WebHowItWorksSection extends StatelessWidget {
  const WebHowItWorksSection({super.key});

  static const _steps = <_Step>[
    _Step(
      '01. REGISTER',
      'Register yourself',
      'Create your Evergreen account for the kitchen, the branch, or the client you look after.',
      Icons.person_add_alt_1_outlined,
    ),
    _Step(
      '02. EQUIPMENT',
      'Add your equipment',
      'List the ranges, fridges and hoods we will be looking after.',
      Icons.kitchen_outlined,
    ),
    _Step(
      '03. REPAIRS',
      'Create a repair task',
      'Tell us the machine and the issue in under a minute.',
      Icons.assignment_add,
    ),
    _Step(
      '04. SERVICE ENGINEER',
      'A service engineer arrives',
      'A certified service engineer is matched and arrives in the window.',
      Icons.build_outlined,
    ),
    _Step(
      '05. APPROVE',
      'Approve & sign off',
      'Review the work, approve it, and rate the service.',
      Icons.verified_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = WebTokens.isMobile(w);

    return WebSection(
      background: WebTokens.pageGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two-column header: eyebrow left, heading + sub right.
          if (mobile)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(),
                SizedBox(height: 16),
                _Heading(mobile: true),
              ],
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _Eyebrow(),
                  ),
                ),
                Expanded(flex: 2, child: _Heading(mobile: false)),
              ],
            ),
          const SizedBox(height: 44),
          // Step cards.
          LayoutBuilder(
            builder: (context, c) {
              final cols = mobile ? 1 : (w < WebTokens.tabletMax ? 2 : 5);
              const gap = 16.0;
              final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    SizedBox(
                      width: cardW,
                      child: _StepCard(step: _steps[i], active: i == 0),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step(this.label, this.title, this.body, this.icon);
  final String label;
  final String title;
  final String body;
  final IconData icon;
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: WebTokens.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text('HOW IT WORKS', style: WebTokens.eyebrow(color: WebTokens.ink)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From signup to\nsign-off in 5 steps',
          style: WebTokens.display(mobile ? 32 : 52),
        ),
        const SizedBox(height: 16),
        Text(
          'Getting a kitchen back on the line is easier than it looks '
          '— five steps from a new account to a signed-off repair.',
          style: WebTokens.bodyText(15),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.active});
  final _Step step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final labelColor = active ? Colors.white70 : WebTokens.faint;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: active ? WebTokens.green : Colors.white,
        // Squared corners, flat (no shadow) — matches the Figma.
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label, top.
          Text(
            step.label,
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: labelColor,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 40),
            Icon(step.icon, color: Colors.white, size: 34),
            const Spacer(),
            Text(step.title, style: WebTokens.heading(22, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              step.body,
              style: WebTokens.bodyText(
                14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ] else ...[
            const Spacer(),
            Center(
              child: Icon(
                step.icon,
                color: WebTokens.faint.withValues(alpha: 0.5),
                size: 30,
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}
