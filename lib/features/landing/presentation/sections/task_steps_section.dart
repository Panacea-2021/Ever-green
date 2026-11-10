import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// "How it works — Kitchen service" section. Laid out on a 1440 × 720 canvas
/// (the 1440 × 809 design with its vertical gaps tightened) and scaled to the
/// available width.
class TaskStepsSection extends StatelessWidget {
  const TaskStepsSection({
    super.key,
    this.onSeeHowItWorks,
  });

  final VoidCallback? onSeeHowItWorks;

  static const _designSize = Size(1440, 720);
  static const _background = Color(0xFF002318);
  static const _mint = Color(0xFFA5F6D1);
  static const _mutedText = Color(0xFFCCD8D1);
  static const _assets = 'assets/images/landing';

  static const _steps = [
    (
      number: '1',
      icon: '$_assets/hiw_calendar_days.svg',
      title: 'Create a task',
      body: 'Book a service or raise a request take just a minute.',
    ),
    (
      number: '2',
      icon: '$_assets/hiw_user_round.svg',
      title: 'Technician will come',
      body: 'Our certified technician will be assigned and visit your location.',
    ),
    (
      number: '3',
      icon: '$_assets/hiw_file_check.svg',
      title: 'Get it done after approval',
      body: 'We complete the service and share a detailed report.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final width =
            isMobile ? 1000.0 : constraints.maxWidth.clamp(0.0, 1600.0);
        final section = SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: _designSize.width / _designSize.height,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox.fromSize(
                size: _designSize,
                child: _canvas(),
              ),
            ),
          ),
        );

        return ColoredBox(
          color: _background,
          child: isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: section,
                )
              : Center(child: section),
        );
      },
    );
  }

  Widget _canvas() {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: ColoredBox(color: _background)),
        Positioned(
          left: 640,
          top: 0,
          width: 800,
          height: 520,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -779.5,
                  top: 0,
                  width: 1944,
                  height: 691.3,
                  child: Image.asset(
                    '$_assets/hiw_photo.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 638,
          top: 0,
          width: 215,
          height: 522,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _background,
                  Color.fromRGBO(0, 35, 24, 0.4),
                  Color.fromRGBO(0, 35, 24, 0),
                ],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          top: 400,
          width: 1440,
          height: 190,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(0, 35, 24, 0),
                  _background,
                  _background,
                ],
                stops: [0, 0.57, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 399.8,
          top: 200,
          width: 385.44,
          height: 311.95,
          // flutter_svg skips SVG filters, so the line's glow is drawn here.
          child: Stack(
            children: [
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: SvgPicture.asset(
                  '$_assets/hiw_glow.svg',
                  width: 385.441,
                  height: 311.949,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF6CFFAE),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SvgPicture.asset(
                '$_assets/hiw_glow.svg',
                width: 385.441,
                height: 311.949,
              ),
            ],
          ),
        ),
        const Positioned(
          left: 375,
          top: 330,
          width: 310,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_background, Color.fromRGBO(0, 35, 24, 0)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 81,
          top: 548,
          width: 1277,
          height: 118,
          child: Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0) const _StepConnection(),
                _StepCard(
                  number: _steps[i].number,
                  icon: _steps[i].icon,
                  title: _steps[i].title,
                  body: _steps[i].body,
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 81,
          top: 50,
          width: 560,
          child: _Introduction(onSeeHowItWorks: onSeeHowItWorks),
        ),
      ],
    );
  }
}

class _Introduction extends StatelessWidget {
  const _Introduction({this.onSeeHowItWorks});

  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    const headlineStyle = TextStyle(
      fontFamily: LandingTypography.fontFamily,
      fontSize: 51,
      height: 1.13,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    const highlight = TextStyle(color: TaskStepsSection._mint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'HOW IT WORKS',
              style: TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: TaskStepsSection._mutedText,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 1,
              color: const Color.fromRGBO(165, 184, 170, 0.53),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text.rich(
          TextSpan(
            style: headlineStyle,
            children: [
              TextSpan(text: 'Get your kitchen\nservice in '),
              TextSpan(text: '3 simple\nsteps', style: highlight),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 485,
          child: Text(
            'From booking to completion, we make kitchen maintenance easy, '
            'fast and hassle-free.',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: TaskStepsSection._mutedText,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: 'See how it works',
          child: Material(
            color: const Color(0xFFF8FBF7),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSeeHowItWorks,
              child: Container(
                height: 49,
                padding: const EdgeInsets.fromLTRB(26, 4, 4, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'See how it works',
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17543F),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Container(
                      width: 41,
                      height: 41,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: TaskStepsSection._mint,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        '${TaskStepsSection._assets}/hiw_arrow_right_button.svg',
                        width: 23,
                        height: 23,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 367,
      height: 118,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(13, 48, 38, 0.72),
        border: Border.all(color: const Color.fromRGBO(121, 157, 135, 0.35)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TaskStepsSection._mint,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: TaskStepsSection._background,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 59,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(40, 74, 59, 0.6),
              border: Border.all(
                color: const Color.fromRGBO(138, 184, 153, 0.15),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SvgPicture.asset(icon, width: 34, height: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 11.5,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5C8BC),
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

class _StepConnection extends StatelessWidget {
  const _StepConnection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 17.5,
            width: 88,
            height: 1,
            child: Image.asset(
              '${TaskStepsSection._assets}/hiw_dotted_connection.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 55, 43, 0.87),
              border: Border.all(color: const Color(0xFFC6DCD0)),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              '${TaskStepsSection._assets}/hiw_arrow_right.svg',
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}
