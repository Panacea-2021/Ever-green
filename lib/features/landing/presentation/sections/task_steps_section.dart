import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// "Get your kitchen service in 3 simple steps" — compact band matching the
/// reference layout: copy and phones side by side, three step cards below.
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

  static const _bg = Color(0xFF042117);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

    return ColoredBox(
      color: _bg,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 640,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.28,
                child: Image(
                  image: AssetImage(LandingAssets.heroBg),
                  fit: BoxFit.cover,
                  alignment: Alignment(0.15, 0),
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF042117),
                    Color(0xF2042117),
                    Color(0x73042117),
                  ],
                  stops: [0, 0.34, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 56,
              isMobile ? 36 : 36,
              isMobile ? 20 : 48,
              isMobile ? 28 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
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
            ),
          ),
        ],
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
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: _CopyBlock(onSeeHowItWorks: onSeeHowItWorks),
            ),
            const SizedBox(width: 28),
            const Expanded(
              flex: 5,
              child: _PhoneCluster(height: 372),
            ),
          ],
        ),
        const SizedBox(height: 32),
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
        const SizedBox(height: 28),
        const _PhoneCluster(height: 300),
        const SizedBox(height: 22),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
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
    final titleSize = isMobile ? 32.0 : 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(),
        SizedBox(height: isMobile ? 14 : 16),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: titleSize,
              height: 1.05,
              letterSpacing: isMobile ? -0.8 : -1.15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Get your kitchen\nservice in '),
              TextSpan(
                text: '3 simple\nsteps',
                style: TextStyle(color: Color(0xFF9BE7B5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            'From booking to completion, we make kitchen maintenance easy, fast and hassle-free.',
            style: LandingTypography.introBody.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: const Color(0xD6FFFFFF),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _SeeHowItWorksButton(onTap: onSeeHowItWorks),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'HOW IT WORKS',
          style: LandingTypography.eyebrowWhite.copyWith(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: const Color(0xE6FFFFFF),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 1,
          color: const Color(0x73FFFFFF),
        ),
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
          padding: const EdgeInsets.only(left: 16, right: 5, top: 5, bottom: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'See how it works',
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF142117),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8F5D4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 15,
                  color: Color(0xFF143026),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneCluster extends StatelessWidget {
  const _PhoneCluster({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final homeW = ((h - 28) / 2.02).clamp(132.0, 176.0);
          final serviceW = ((h - 10) / 2.02).clamp(140.0, 186.0);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: CustomPaint(painter: _SwooshPainter())),
              Positioned(
                left: homeW * 0.15,
                right: 8,
                bottom: 0,
                child: const _Pedestal(),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _ServicePhone(width: serviceW),
              ),
              Positioned(
                left: 0,
                top: 20,
                child: _HomePhone(width: homeW),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pedestal extends StatelessWidget {
  const _Pedestal();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFC5CCC6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  const _SwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.02, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.98,
        size.width * 0.62,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.24,
        size.width * 0.96,
        size.height * 0.18,
      );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = const Color(0x559BE7B5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCB8F0CC),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomePhone extends StatelessWidget {
  const _HomePhone({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      width: width,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 18),
          _PhoneStatusBar(),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _EvergreenBar(),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Commercial\nKitchen Care\nMade Simple',
              style: TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 15,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF163024),
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Book, Track and Manage\nyour Service',
              style: TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 8.5,
                height: 1.3,
                color: Color(0xFF7A867E),
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: Image(
                  image: AssetImage(LandingAssets.heroBg),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _BookServiceButton(),
          ),
          SizedBox(height: 8),
          _PhoneNav(),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ServicePhone extends StatelessWidget {
  const _ServicePhone({required this.width});

  final double width;

  static const _events = [
    ('Request Received', '10:15 AM'),
    ('Technician Assigned', '10:25 AM'),
    ('On the Way', '10:30 AM'),
    ('Service in Progress', '11:00 AM'),
    ('Completed', '11:45 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      width: width,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 18, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhoneStatusBar(),
            SizedBox(height: 10),
            Text(
              'Your Service',
              style: TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF163024),
              ),
            ),
            SizedBox(height: 8),
            _Timeline(events: _events),
            Spacer(),
            _TechnicianCard(),
          ],
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 2.02,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(width * 0.16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.13),
        child: ColoredBox(
          color: const Color(0xFFF7F8F6),
          child: Stack(
            children: [
              child,
              const Align(
                alignment: Alignment(0, -0.98),
                child: _Notch(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Color(0xFF163024),
            ),
          ),
          Spacer(),
          Icon(Icons.signal_cellular_alt, size: 9, color: Color(0xFF163024)),
          SizedBox(width: 2),
          Icon(Icons.wifi, size: 9, color: Color(0xFF163024)),
          SizedBox(width: 2),
          Icon(Icons.battery_full, size: 10, color: Color(0xFF163024)),
        ],
      ),
    );
  }
}

class _EvergreenBar extends StatelessWidget {
  const _EvergreenBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Mark(),
        SizedBox(width: 6),
        Text(
          'Evergreen',
          style: TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF163024),
          ),
        ),
        Spacer(),
        Icon(Icons.notifications_none, size: 14, color: Color(0xFF163024)),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: LandingColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.home_rounded, size: 11, color: Colors.white),
    );
  }
}

class _BookServiceButton extends StatelessWidget {
  const _BookServiceButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LandingColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Book a Service  →',
        style: TextStyle(
          fontFamily: LandingTypography.fontFamily,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PhoneNav extends StatelessWidget {
  const _PhoneNav();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
        _NavItem(icon: Icons.grid_view_rounded, label: 'Services'),
        _NavItem(icon: Icons.calendar_today_outlined, label: 'Bookings'),
        _NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? LandingColors.primary : const Color(0xFF9AA39C);
    return Column(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: 6.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<(String, String)> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            title: events[i].$1,
            time: events[i].$2,
            showLine: i < events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.time,
    required this.showLine,
  });

  final String title;
  final String time;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF12A83C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            ),
            if (showLine)
              Container(
                width: 1.4,
                height: 14,
                color: const Color(0xFFB7E0C4),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF163024),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 7,
                    color: Color(0xFF8B948E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(LandingAssets.techArjun),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Technician',
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF163024),
                      ),
                    ),
                    Text(
                      'is on the way',
                      style: TextStyle(
                        fontFamily: LandingTypography.fontFamily,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF12A83C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _RoutePainter(),
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.location_on,
                  size: 14,
                  color: Color(0xFF12A83C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(4, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.1,
        size.width * 0.72,
        size.height * 0.55,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF12A83C),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.steps});

  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.only(top: 22, left: 6, right: 6),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: Color(0x8CFFFFFF),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE60C3224),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x40FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x73FFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              data.number,
              style: const TextStyle(
                fontFamily: LandingTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(data.icon, size: 13, color: const Color(0xE6FFFFFF)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          fontFamily: LandingTypography.fontFamily,
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: const TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xE6FFFFFF),
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
