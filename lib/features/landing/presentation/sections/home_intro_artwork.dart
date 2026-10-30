import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// Full-width kitchen intro and five steps. Text is drawn by Flutter so it
/// stays sharp, and the illustrated figure is a real kitchen-repair photo.
class HomeIntroArtwork extends StatelessWidget {
  const HomeIntroArtwork({
    super.key,
    this.stepsKey,
    this.onBookRepair,
    this.onLearnMore,
  });

  final Key? stepsKey;
  final VoidCallback? onBookRepair;
  final VoidCallback? onLearnMore;

  static const _steps = [
    _Step(
      '01',
      'Register yourself',
      'Create your Evergreen account for the kitchen, the branch, or the client you look after.',
      Icons.person_add_alt_1_outlined,
      true,
    ),
    _Step(
      '02',
      'Add equipment',
      'Add your kitchen equipment and basic details so we can understand your setup.',
      Icons.description_outlined,
      false,
    ),
    _Step(
      '03',
      'Request a repair',
      "Tell us what's not working and choose a convenient time.",
      Icons.assignment_outlined,
      false,
    ),
    _Step(
      '04',
      'Technician visit',
      'A verified technician will come to your location and carry out the repair.',
      Icons.handyman_outlined,
      false,
    ),
    _Step(
      '05',
      'Approve & close',
      "Review the work, approve the repair, and you're all set.",
      Icons.check_circle_outline,
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

    return ColoredBox(
      color: const Color(0xFFDCF0E1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Intro(
            isMobile: isMobile,
            onBookRepair: onBookRepair,
            onLearnMore: onLearnMore,
          ),
          SizedBox(key: stepsKey, height: 8),
          _Steps(isMobile: isMobile, steps: _steps),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.isMobile,
    this.onBookRepair,
    this.onLearnMore,
  });

  final bool isMobile;
  final VoidCallback? onBookRepair;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final copy = _IntroCopy(
      isMobile: isMobile,
      onBookRepair: onBookRepair,
      onLearnMore: onLearnMore,
    );
    const photo = _RepairPhoto();

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            copy,
            const SizedBox(height: 28),
            photo,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 48, 80, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: copy),
          const SizedBox(width: 36),
          const SizedBox(width: 520, child: photo),
        ],
      ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({
    required this.isMobile,
    this.onBookRepair,
    this.onLearnMore,
  });

  final bool isMobile;
  final VoidCallback? onBookRepair;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E8D1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+  TRUSTED KITCHEN REPAIR SERVICE',
              style: LandingTypography.eyebrow.copyWith(
                color: LandingColors.primary,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fast kitchen repair —\nwhen you need it most.',
            style: LandingTypography.sectionSubtitle.copyWith(
              fontSize: isMobile ? 34 : 46,
              height: 1.05,
              letterSpacing: -1.2,
              color: const Color(0xFF142117),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Book a trusted technician, get your kitchen fixed, and get back to what matters — all in one place.',
              style: LandingTypography.introBody.copyWith(
                fontSize: 16,
                height: 1.5,
                color: const Color(0xFF3E4A43),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _Point(
                  Icons.bolt_rounded, 'Quick booking', 'In just a few minutes'),
              _Point(
                Icons.verified_user_outlined,
                'Verified technicians',
                'Skilled & background checked',
              ),
              _Point(
                Icons.headset_mic_outlined,
                'Reliable support',
                "We're here to help",
              ),
            ],
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                label: 'Book a repair',
                icon: Icons.calendar_today_outlined,
                filled: true,
                onTap: onBookRepair,
              ),
              _ActionButton(
                label: 'Learn more',
                icon: Icons.play_arrow_rounded,
                filled: false,
                onTap: onLearnMore,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _RatingPill(),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFC8E8D1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: LandingColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF142117),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFF5C6B62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? LandingColors.primary : Colors.white;
    final fg = filled ? Colors.white : const Color(0xFF142117);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: const Color(0xFFD5E0D8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (filled) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(Color(0xFFB7C4BC)),
          SizedBox(width: 4),
          _Dot(Color(0xFF8FA396)),
          SizedBox(width: 4),
          _Dot(Color(0xFFE7B6A8)),
          SizedBox(width: 10),
          Text(
            '4.8/5',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF142117),
            ),
          ),
          SizedBox(width: 6),
          Text(
            '★★★★★',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFE0B323),
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Trusted by 5,000+ homes',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              color: Color(0xFF5C6B62),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RepairPhoto extends StatelessWidget {
  const _RepairPhoto();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: const SizedBox(
        height: 420,
        width: double.infinity,
        child: Image(
          image: AssetImage(LandingAssets.whyKitchen),
          fit: BoxFit.cover,
          alignment: Alignment(-0.2, -0.05),
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _Steps extends StatefulWidget {
  const _Steps({required this.isMobile, required this.steps});

  final bool isMobile;
  final List<_Step> steps;

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    final steps = widget.steps;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 16 : 28, 12, isMobile ? 16 : 28, 40),
      child: Column(
        children: [
          Text(
            '·  HOW IT WORKS',
            textAlign: TextAlign.center,
            style: LandingTypography.eyebrow.copyWith(
              color: LandingColors.primary,
              letterSpacing: 1.6,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'From signup to sign-off in 5 steps',
            textAlign: TextAlign.center,
            style: LandingTypography.sectionSubtitle.copyWith(
              fontSize: isMobile ? 30 : 40,
              height: 1.1,
              letterSpacing: -0.8,
              color: const Color(0xFF142117),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Getting a kitchen back on the line is easier than it looks — five steps from a new account to a signed-off repair.',
              textAlign: TextAlign.center,
              style: LandingTypography.introBody.copyWith(
                fontSize: 15,
                height: 1.5,
                color: const Color(0xFF3E4A43),
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (isMobile)
            for (var i = 0; i < steps.length; i++) ...[
              _StepCard(
                step: steps[i],
                selected: i == _selected,
                onTap: () => setState(() => _selected = i),
              ),
              const SizedBox(height: 16),
            ]
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: SizedBox(
                        width: 18,
                        child: Text(
                          '–',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8FA396),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _StepCard(
                      step: steps[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.selected,
    required this.onTap,
  });

  final _Step step;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = selected;
    final fg = dark ? Colors.white : const Color(0xFF142117);
    final muted = dark ? const Color(0xE6FFFFFF) : const Color(0xFF5C6B62);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 280),
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
              decoration: BoxDecoration(
                color: dark ? LandingColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(step.icon,
                      color: dark ? Colors.white : LandingColors.primary,
                      size: 26),
                  const SizedBox(height: 14),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.body,
                    style: TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: 13.5,
                      height: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dark ? Colors.white : const Color(0xFFF3F7F4),
                      border: dark
                          ? null
                          : Border.all(color: const Color(0xFFD7E3DB)),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: dark
                          ? LandingColors.primary
                          : const Color(0xFF3E4A43),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              left: 16,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : const Color(0xFFF7FBF8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dark ? Colors.white : const Color(0xFFD7E3DB),
                  ),
                ),
                child: Text(
                  step.number,
                  style: TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        dark ? LandingColors.primary : const Color(0xFF142117),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.number, this.title, this.body, this.icon, this.dark);

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final bool dark;
}
