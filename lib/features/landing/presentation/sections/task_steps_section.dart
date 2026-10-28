import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// How It Works — 3 simple steps. Same photo and copy, sharp Flutter text.
class TaskStepsSection extends StatelessWidget {
  const TaskStepsSection({
    super.key,
    this.onSeeHowItWorks,
  });

  final VoidCallback? onSeeHowItWorks;

  static const _steps = [
    _StepData(
      number: '1',
      title: 'Create a task',
      body: 'Book a service or raise a request take just a minute.',
      icon: Icons.calendar_today_outlined,
    ),
    _StepData(
      number: '2',
      title: 'Technician will come',
      body: 'Our certified technician will be assigned and visit your location.',
      icon: Icons.person_outline,
    ),
    _StepData(
      number: '3',
      title: 'Get it done after approval',
      body: 'We complete the service and share a detailed report.',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    return ColoredBox(
      color: const Color(0xFF002318),
      child: SizedBox(
        height: isMobile ? null : 680,
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage(LandingAssets.howItWorks),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF2001A12),
                      Color(0xCC001A12),
                      Color(0x66001A12),
                      Color(0x00001A12),
                    ],
                    stops: [0, 0.30, 0.52, 0.78],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00001A12),
                      Color(0xE6001A12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : (isTablet ? 40 : 72),
                isMobile ? 48 : 56,
                isMobile ? 20 : (isTablet ? 40 : 72),
                isMobile ? 36 : 36,
              ),
              child: isMobile
                  ? _MobileLayout(
                      steps: _steps,
                      onSeeHowItWorks: onSeeHowItWorks,
                    )
                  : _DesktopLayout(
                      steps: _steps,
                      onSeeHowItWorks: onSeeHowItWorks,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.steps,
    this.onSeeHowItWorks,
  });

  final List<_StepData> steps;
  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CopyBlock(onSeeHowItWorks: onSeeHowItWorks),
        const Spacer(),
        _StepsRow(steps: steps),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.steps,
    this.onSeeHowItWorks,
  });

  final List<_StepData> steps;
  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CopyBlock(isMobile: true, onSeeHowItWorks: onSeeHowItWorks),
        const SizedBox(height: 32),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StepCard(data: steps[i]),
        ],
      ],
    );
  }
}

class _CopyBlock extends StatelessWidget {
  const _CopyBlock({
    this.isMobile = false,
    this.onSeeHowItWorks,
  });

  final bool isMobile;
  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT WORKS',
          style: LandingTypography.eyebrowWhite.copyWith(
            fontSize: 11,
            letterSpacing: 2.8,
            color: const Color(0xB3FFFFFF),
          ),
        ),
        SizedBox(height: isMobile ? 14 : 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text.rich(
            TextSpan(
              style: LandingTypography.sectionTitleWhite.copyWith(
                fontSize: isMobile ? 34 : 52,
                height: 1.08,
                letterSpacing: isMobile ? -1.0 : -1.6,
                fontWeight: FontWeight.w600,
              ),
              children: const [
                TextSpan(text: 'Get your kitchen\nservice in '),
                TextSpan(
                  text: '3 simple\n',
                  style: TextStyle(color: Color(0xFF8FE7B0)),
                ),
                TextSpan(text: 'steps'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'From booking to completion, we make kitchen maintenance easy, fast and hassle-free.',
            style: LandingTypography.introBody.copyWith(
              fontSize: 15,
              height: 1.55,
              color: Color(0xCCFFFFFF),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SeeHowItWorksButton(onTap: onSeeHowItWorks),
      ],
    );
  }
}

class _SeeHowItWorksButton extends StatelessWidget {
  const _SeeHowItWorksButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 6, top: 6, bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'See how it works',
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF142117),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: LandingColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.steps});

  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: Color(0x73FFFFFF),
              ),
            ),
          Expanded(child: _StepCard(data: steps[i])),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xCC0B2A1E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x59FFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              data.number,
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      data.icon,
                      size: 15,
                      color: const Color(0xCCFFFFFF),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          fontFamily: LandingTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  data.body,
                  style: LandingTypography.introBody.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    color: const Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
}
