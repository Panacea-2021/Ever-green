import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// Figma node 352:9410 — “Get your kitchen service in 3 simple steps”.
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
      body: 'Submit or raise a request so we know what needs attention.',
      icon: Icons.assignment_outlined,
    ),
    _StepData(
      number: '2',
      title: 'Technician will come',
      body: 'Our certified technician will be assigned at your location.',
      icon: Icons.person_outline,
    ),
    _StepData(
      number: '3',
      title: 'Get it done after approval',
      body: 'We complete the work in detail once you approve the visit.',
      icon: Icons.phone_iphone_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF002318),
      child: GestureDetector(
        onTap: onSeeHowItWorks,
        child: Image.asset(
          LandingAssets.howItWorks,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const SizedBox(height: 240),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.steps,
    required this.isTablet,
    this.onSeeHowItWorks,
  });

  final List<_StepData> steps;
  final bool isTablet;
  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isTablet ? 5 : 4,
                child: _CopyBlock(
                  isMobile: false,
                  onSeeHowItWorks: onSeeHowItWorks,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 24),
              Expanded(
                flex: isTablet ? 6 : 7,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    LandingAssets.phoneMockup,
                    height: isTablet ? 420 : 520,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
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
        _CopyBlock(
          isMobile: true,
          onSeeHowItWorks: onSeeHowItWorks,
        ),
        const SizedBox(height: 32),
        Image.asset(
          LandingAssets.phoneMockup,
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 36),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          _StepItem(data: steps[i], compact: true),
        ],
      ],
    );
  }
}

class _CopyBlock extends StatelessWidget {
  const _CopyBlock({
    required this.isMobile,
    this.onSeeHowItWorks,
  });

  final bool isMobile;
  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'HOW IT WORKS',
          style: LandingTypography.eyebrowWhite.copyWith(
            fontSize: 11,
            letterSpacing: 2.6,
            color: const Color(0x99FFFFFF),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          'Get your kitchen\nservice in 3 simple\nsteps',
          style: LandingTypography.sectionTitleWhite.copyWith(
            fontSize: isMobile ? 34 : 48,
            height: 1.08,
            letterSpacing: isMobile ? -1.0 : -1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            'From booking to completion, we make kitchen maintenance simple, fast and hassle-free.',
            style: LandingTypography.introBody.copyWith(
              fontSize: 15,
              height: 1.55,
              color: const Color(0xB8FFFFFF),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SeeHowItWorksButton(onTap: onSeeHowItWorks),
      ],
    );
  }
}

class _SeeHowItWorksButton extends StatefulWidget {
  const _SeeHowItWorksButton({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_SeeHowItWorksButton> createState() => _SeeHowItWorksButtonState();
}

class _SeeHowItWorksButtonState extends State<_SeeHowItWorksButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.only(left: 18, right: 8),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF0C4E19) : LandingColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'See how it works',
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
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

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.steps});

  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 40,
            right: 40,
            top: 18,
            height: 2,
            child: CustomPaint(
              painter: _DashLinePainter(),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(child: _StepItem(data: steps[i])),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.data,
    this.compact = false,
  });

  final _StepData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF163C2C),
            shape: BoxShape.circle,
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
                    size: 16,
                    color: const Color(0xCCFFFFFF),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      data.title,
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w600,
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
                  fontSize: 13,
                  height: 1.45,
                  color: const Color(0x99FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
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

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 6.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x6633AD5B)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.05,
        size.width * 0.55,
        size.height * 0.15,
        size.width * 0.72,
        size.height * 0.42,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
