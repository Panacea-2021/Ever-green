import 'package:flutter/material.dart';

import '../landing_theme.dart';

class StepCardData {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const StepCardData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// "From signup to sign-off in 5 steps" — Figma node 331:1343.
class HowItWorksSection extends StatefulWidget {
  const HowItWorksSection({super.key});

  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection> {
  int _activeIndex = 0;

  static const List<StepCardData> _steps = [
    StepCardData(
      number: '01',
      title: 'Register yourself',
      description:
          'Create your Evergreen account for the kitchen, the branch, or the client you look after.',
      icon: Icons.person_add_alt_1_outlined,
    ),
    StepCardData(
      number: '02',
      title: 'Add equipment',
      description:
          'Log the range, the fridge, and every other machine that has to stay on the line.',
      icon: Icons.description_outlined,
    ),
    StepCardData(
      number: '03',
      title: 'Request a repair',
      description:
          'Raise a job the moment something leaves the line down, with the fault in plain words.',
      icon: Icons.assignment_outlined,
    ),
    StepCardData(
      number: '04',
      title: 'Technician visit',
      description:
          'A certified technician comes to your kitchen and puts that machine back to work.',
      icon: Icons.handyman_outlined,
    ),
    StepCardData(
      number: '05',
      title: 'Approve & close',
      description:
          'Review the finished job and sign it off before the service engineer leaves.',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFFE5F6EA),
      child: Stack(
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.32,
              child: Image(
                image: AssetImage(LandingAssets.heroBg),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const Positioned.fill(
            child: ColoredBox(color: Color(0xE6E5F6EA)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 64,
              isMobile ? 48 : 72,
              isMobile ? 20 : 64,
              isMobile ? 56 : 88,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 36 : 48),
                    isMobile ? _buildMobileCards() : _buildDesktopCards(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        Text(
          '·  HOW IT WORKS',
          style: LandingTypography.eyebrow.copyWith(
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          'From signup to\nsign-off in 5 steps',
          textAlign: TextAlign.center,
          style: LandingTypography.sectionSubtitle.copyWith(
            fontSize: isMobile ? 34 : 48,
            height: 1.08,
            letterSpacing: isMobile ? -1.0 : -1.6,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Getting a kitchen back on the line is easier than it looks — five steps from a new account to a signed-off repair.',
            textAlign: TextAlign.center,
            style: LandingTypography.introBody.copyWith(
              fontSize: 15,
              height: 1.55,
              color: const Color(0xFF6B746E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < _steps.length - 1 ? 14 : 0,
            ),
            child: SizedBox(
              height: 360,
              child: _StepCard(
                data: _steps[index],
                isActive: index == _activeIndex,
                fillHeight: true,
                onTap: () => setState(() => _activeIndex = index),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: List.generate(_steps.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _steps.length - 1 ? 12 : 0,
          ),
          child: _StepCard(
            data: _steps[index],
            isActive: index == _activeIndex,
            fillHeight: false,
            onTap: () => setState(() => _activeIndex = index),
          ),
        );
      }),
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({
    required this.data,
    required this.isActive,
    required this.onTap,
    this.fillHeight = false,
  });

  final StepCardData data;
  final bool isActive;
  final VoidCallback onTap;
  final bool fillHeight;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final bg = active ? LandingColors.primary : Colors.white;
    final titleColor = active ? Colors.white : LandingColors.textDark;
    final bodyColor = active ? const Color(0xE6FFFFFF) : const Color(0xFF6B746E);
    final numberColor = active ? const Color(0xB3FFFFFF) : const Color(0xFF9AA39C);
    final iconColor = active ? Colors.white : LandingColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: widget.fillHeight ? double.infinity : null,
          transform: Matrix4.identity()
            ..translate(0.0, _hover && !active ? -4.0 : 0.0),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!active)
                BoxShadow(
                  color: const Color(0x14000000),
                  blurRadius: _hover ? 22 : 14,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.number,
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: numberColor,
                ),
              ),
              const SizedBox(height: 18),
              Icon(widget.data.icon, size: 28, color: iconColor),
              const SizedBox(height: 22),
              Text(
                widget.data.title,
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.data.description,
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: bodyColor,
                ),
              ),
              if (widget.fillHeight) const Spacer() else const SizedBox(height: 28),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? Colors.white : const Color(0xFFF3F6F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: LandingColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
