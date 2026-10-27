import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// "Trusted kitchen repair service" module — Figma node 331:1343.
class TrustedKitchenSection extends StatelessWidget {
  const TrustedKitchenSection({
    super.key,
    this.onBookRepair,
    this.onLearnMore,
  });

  final VoidCallback? onBookRepair;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    return Container(
      width: double.infinity,
      color: const Color(0xFFE5F6EA),
      child: Stack(
        children: [
          const Positioned.fill(
            child: _KitchenWash(asset: LandingAssets.heroBg, opacity: 0.38),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : (isTablet ? 40 : 80),
              isMobile ? 56 : 80,
              isMobile ? 20 : (isTablet ? 40 : 80),
              isMobile ? 48 : 64,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CopyColumn(
                            isMobile: true,
                            onBookRepair: onBookRepair,
                            onLearnMore: onLearnMore,
                          ),
                          const SizedBox(height: 40),
                          const _KitchenScene(height: 320),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 11,
                            child: _CopyColumn(
                              isMobile: false,
                              onBookRepair: onBookRepair,
                              onLearnMore: onLearnMore,
                            ),
                          ),
                          SizedBox(width: isTablet ? 32 : 56),
                          const Expanded(
                            flex: 10,
                            child: _KitchenScene(height: 420),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyColumn extends StatelessWidget {
  const _CopyColumn({
    required this.isMobile,
    this.onBookRepair,
    this.onLearnMore,
  });

  final bool isMobile;
  final VoidCallback? onBookRepair;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✦  TRUSTED KITCHEN REPAIR SERVICE',
          style: LandingTypography.eyebrow.copyWith(
            letterSpacing: 1.8,
          ),
        ),
        SizedBox(height: isMobile ? 20 : 28),
        Text(
          'Fast kitchen repair —\nwhen you need it most.',
          style: LandingTypography.sectionSubtitle.copyWith(
            fontSize: isMobile ? 34 : 48,
            height: 1.08,
            letterSpacing: isMobile ? -1.0 : -1.6,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Book a trusted technician, get your kitchen fixed, and get back to what matters — all in one place.',
            style: LandingTypography.introBody.copyWith(
              fontSize: 15,
              height: 1.55,
              color: const Color(0xFF6B746E),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 28 : 36),
        Wrap(
          spacing: isMobile ? 20 : 32,
          runSpacing: 20,
          children: const [
            _TrustPoint(
              icon: Icons.bolt_outlined,
              title: 'Quick booking',
              subtitle: 'In just a few minutes',
            ),
            _TrustPoint(
              icon: Icons.verified_user_outlined,
              title: 'Verified technicians',
              subtitle: 'Skilled & background checked',
            ),
            _TrustPoint(
              icon: Icons.headset_mic_outlined,
              title: 'Reliable support',
              subtitle: 'We’re here to help',
            ),
          ],
        ),
        SizedBox(height: isMobile ? 28 : 36),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PillButton(
              label: 'Book a repair',
              icon: Icons.calendar_today_outlined,
              trailing: Icons.arrow_forward,
              filled: true,
              onTap: onBookRepair,
            ),
            _PillButton(
              label: 'Learn more',
              icon: Icons.play_arrow_rounded,
              filled: false,
              onTap: onLearnMore,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _RatingRow(),
        ),
      ],
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F2EA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: LandingColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LandingColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: Color(0xFF7A847C),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final bool filled;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (_hover ? const Color(0xFF0C4E19) : LandingColors.primary)
        : (_hover ? const Color(0xFFF7F7F7) : Colors.white);
    final fg = widget.filled ? Colors.white : LandingColors.textDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: widget.filled
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                Icon(widget.trailing, size: 16, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow();

  static const _faces = [
    LandingAssets.techArjun,
    LandingAssets.techMeera,
    LandingAssets.techNikhil,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 28,
            child: Stack(
              children: [
                for (var i = 0; i < _faces.length; i++)
                  Positioned(
                    left: i * 16.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          image: AssetImage(_faces[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '4.8/5',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LandingColors.textDark,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: List.generate(
              5,
              (i) => const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFF5B942),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Trusted by 5,000+ homes',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A847C),
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenWash extends StatelessWidget {
  const _KitchenWash({
    required this.asset,
    required this.opacity,
  });

  final String asset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Container(color: const Color(0xE6E5F6EA)),
      ],
    );
  }
}

/// Technician on a real kitchen job — replaces the placeholder illustration.
class _KitchenScene extends StatelessWidget {
  const _KitchenScene({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              LandingAssets.whyKitchen,
              fit: BoxFit.cover,
              alignment: const Alignment(0.15, 0),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14002218),
                    Color(0x00000000),
                    Color(0x66106220),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 16,
              child: _SceneBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneBadge extends StatelessWidget {
  const _SceneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 14, color: LandingColors.primary),
          SizedBox(width: 6),
          Text(
            'On-site kitchen repair',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LandingColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
