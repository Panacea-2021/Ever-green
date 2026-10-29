import 'package:flutter/material.dart';

import '../../landing_theme.dart';

/// Palette for the commercial-kitchen Services page.
class SvcColors {
  SvcColors._();

  static const Color primary = Color(0xFF0F5A2A);
  static const Color primaryDeep = Color(0xFF0B3B1E);
  static const Color footer = Color(0xFF082A15);
  static const Color highlight = Color(0xFF1E9E4A);
  static const Color highlightLight = Color(0xFF6FD897);
  static const Color mint = Color(0xFFEEF6EF);
  static const Color mintStrong = Color(0xFFE0F0E4);
  static const Color text = Color(0xFF0F1A13);
  static const Color body = Color(0xFF5B6B60);
  static const Color border = Color(0xFFE2EBE4);
}

/// Images used on the Services page. Swap these paths for dedicated photos.
class SvcAssets {
  SvcAssets._();

  static const String hero = 'assets/images/get_started_bg.png';

  static const String preventive = 'assets/images/login_bg.png';
  static const String emergency = 'assets/images/home_banner.png';
  static const String installation = 'assets/images/landing/why_kitchen.png';
  static const String cleaning = 'assets/images/landing/tech_meera.png';
  static const String upgrades = 'assets/images/landing/range.png';
  static const String consultation = 'assets/images/landing/review_photo_1.png';
  static const String amc = 'assets/images/landing/tech_arjun.png';

  static const String cooking = 'assets/images/landing/range.png';
  static const String refrigeration = 'assets/images/landing/fridge.png';
  static const String dishwashing = 'assets/images/equip_fridge.png';
  static const String foodPrep = 'assets/images/landing/mixer.png';
  static const String ventilation = 'assets/images/login_bg.png';

  static const String itCampus = 'assets/images/company_header_bg.png';
  static const String cafeteria = 'assets/images/landing/tech_sara.png';
  static const String hostels = 'assets/images/landing/task_steps_bg.png';
  static const String hotels = 'assets/images/landing/hero_bg.png';
  static const String hospitals = 'assets/images/landing/tech_leela.png';
  static const String restaurants = 'assets/images/landing/review_photo_2.png';

  static const String step1 = 'assets/images/landing/tech_nikhil.png';
  static const String step2 = 'assets/images/landing/review_photo_3.png';
  static const String step3 = 'assets/images/get_started_bg.png';
  static const String step4 = 'assets/images/home_banner.png';

  static const String chef = 'assets/images/landing/review_photo_1.png';

  static const String case1 = 'assets/images/company_header_bg.png';
  static const String case2 = 'assets/images/landing/task_steps_bg.png';
  static const String case3 = 'assets/images/landing/hero_bg.png';

  static const String testimonial = 'assets/images/landing/review_photo_4.png';
  static const String cta = 'assets/images/login_bg.png';

  /// Product cut-outs on white backgrounds; shown whole instead of cropped.
  static const Set<String> cutouts = {
    'assets/images/landing/range.png',
    'assets/images/landing/fridge.png',
    'assets/images/landing/mixer.png',
  };

  /// Crop focus per photo so faces and the work being done stay in frame.
  static const Map<String, Alignment> _focus = {
    'assets/images/landing/tech_meera.png': Alignment(0, -0.55),
    'assets/images/landing/tech_arjun.png': Alignment(0, -0.6),
    'assets/images/landing/tech_nikhil.png': Alignment(0, -0.6),
    'assets/images/landing/tech_sara.png': Alignment(0, -0.6),
    'assets/images/landing/tech_leela.png': Alignment(0, -0.6),
    'assets/images/landing/review_photo_1.png': Alignment(0, -0.55),
    'assets/images/landing/review_photo_2.png': Alignment(0, -0.6),
    'assets/images/landing/review_photo_3.png': Alignment(0, -0.6),
    'assets/images/landing/why_kitchen.png': Alignment(0, -0.45),
    'assets/images/get_started_bg.png': Alignment(0, 0.15),
    'assets/images/login_bg.png': Alignment(0, 0.2),
    'assets/images/home_banner.png': Alignment(0.2, -0.2),
  };

  static Alignment focusFor(String asset) => _focus[asset] ?? Alignment.center;
}

class SvcLayout {
  SvcLayout._();

  static const double maxWidth = 1280;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  static double hPad(BuildContext context) => isMobile(context) ? 20 : 40;
}

TextStyle svcText({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = SvcColors.text,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: LandingTypography.fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Full-width band whose content is centred and capped at [SvcLayout.maxWidth].
class SvcSection extends StatelessWidget {
  const SvcSection({
    super.key,
    required this.child,
    this.color,
    this.decoration,
    this.vertical,
  });

  final Widget child;
  final Color? color;
  final Decoration? decoration;
  final double? vertical;

  @override
  Widget build(BuildContext context) {
    final mobile = SvcLayout.isMobile(context);
    return Container(
      width: double.infinity,
      color: decoration == null ? color : null,
      decoration: decoration,
      padding: EdgeInsets.symmetric(vertical: vertical ?? (mobile ? 48 : 72)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SvcLayout.maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SvcLayout.hPad(context)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SvcEyebrow extends StatelessWidget {
  const SvcEyebrow(this.text, {super.key, this.light = false});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.1) : SvcColors.mintStrong,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: svcText(
          size: 10.5,
          weight: FontWeight.w700,
          letterSpacing: 1.4,
          color: light ? SvcColors.highlightLight : SvcColors.primary,
        ),
      ),
    );
  }
}

/// Section title with an optional trailing phrase in the accent green.
class SvcHeading extends StatelessWidget {
  const SvcHeading({
    super.key,
    required this.title,
    this.highlight,
    this.light = false,
    this.size,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? highlight;
  final bool light;
  final double? size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final fontSize = size ?? (SvcLayout.isMobile(context) ? 28 : 38);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title),
          if (highlight != null)
            TextSpan(
              text: highlight,
              style: TextStyle(
                color: light ? SvcColors.highlightLight : SvcColors.highlight,
              ),
            ),
        ],
      ),
      textAlign: textAlign,
      style: svcText(
        size: fontSize,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
        color: light ? Colors.white : SvcColors.text,
      ),
    );
  }
}

class SvcBody extends StatelessWidget {
  const SvcBody(this.text, {super.key, this.light = false, this.size = 14.5});

  final String text;
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: svcText(
        size: size,
        height: 1.6,
        color: light ? Colors.white.withOpacity(0.75) : SvcColors.body,
      ),
    );
  }
}

/// Eyebrow + heading + body block used at the start of most sections.
class SvcIntro extends StatelessWidget {
  const SvcIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    this.highlight,
    this.body,
    this.light = false,
  });

  final String eyebrow;
  final String title;
  final String? highlight;
  final String? body;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvcEyebrow(eyebrow, light: light),
        const SizedBox(height: 14),
        SvcHeading(title: title, highlight: highlight, light: light),
        if (body != null) ...[
          const SizedBox(height: 14),
          SvcBody(body!, light: light),
        ],
      ],
    );
  }
}

enum SvcButtonVariant { filled, outline, white, outlineLight }

class SvcButton extends StatefulWidget {
  const SvcButton({
    super.key,
    required this.label,
    this.variant = SvcButtonVariant.filled,
    this.onTap,
    this.showArrow = true,
    this.compact = false,
    this.hoverColor,
  });

  final String label;
  final SvcButtonVariant variant;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool compact;
  final Color? hoverColor;

  @override
  State<SvcButton> createState() => _SvcButtonState();
}

class _SvcButtonState extends State<SvcButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    Color border = Colors.transparent;

    switch (widget.variant) {
      case SvcButtonVariant.filled:
        bg = _hovered ? SvcColors.primaryDeep : SvcColors.primary;
        fg = Colors.white;
      case SvcButtonVariant.outline:
        bg = _hovered ? widget.hoverColor ?? SvcColors.mint : Colors.white;
        fg = SvcColors.primary;
        border = SvcColors.primary.withOpacity(0.35);
      case SvcButtonVariant.white:
        bg = _hovered ? widget.hoverColor ?? SvcColors.mint : Colors.white;
        fg = SvcColors.primary;
      case SvcButtonVariant.outlineLight:
        bg = _hovered ? Colors.white.withOpacity(0.12) : Colors.transparent;
        fg = Colors.white;
        border = Colors.white.withOpacity(0.6);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 22,
            vertical: widget.compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(LandingRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: svcText(
                  size: widget.compact ? 13 : 14,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (widget.showArrow) ...[
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

class SvcImage extends StatelessWidget {
  const SvcImage(
    this.asset, {
    super.key,
    this.height,
    this.width,
    this.radius = 14,
    this.borderRadius,
    this.alignment,
  });

  final String asset;
  final double? height;
  final double? width;
  final double radius;
  final BorderRadius? borderRadius;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    final cutout = SvcAssets.cutouts.contains(asset);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: cutout ? Colors.white : null,
        padding: cutout ? const EdgeInsets.all(8) : null,
        child: Image.asset(
          asset,
          fit: cutout ? BoxFit.contain : BoxFit.cover,
          alignment: alignment ?? SvcAssets.focusFor(asset),
          errorBuilder: (_, __, ___) => Container(
            color: SvcColors.mintStrong,
            alignment: Alignment.center,
            child: Icon(
              Icons.kitchen_outlined,
              color: SvcColors.primary.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card that lifts slightly on hover.
class SvcCard extends StatefulWidget {
  const SvcCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<SvcCard> createState() => _SvcCardState();
}

class _SvcCardState extends State<SvcCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SvcColors.border),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF0B3B1E).withOpacity(_hovered ? 0.12 : 0.05),
                blurRadius: _hovered ? 28 : 16,
                offset: Offset(0, _hovered ? 12 : 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class SvcArrowCircle extends StatelessWidget {
  const SvcArrowCircle({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: light ? Colors.white : SvcColors.mint,
      ),
      child: const Icon(
        Icons.arrow_forward,
        size: 16,
        color: SvcColors.primary,
      ),
    );
  }
}

class SvcIconBox extends StatelessWidget {
  const SvcIconBox(this.icon, {super.key, this.size = 36, this.light = false});

  final IconData icon;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : SvcColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.5, color: SvcColors.primary),
    );
  }
}

/// Rows of equal-width cells; each row's cells share the tallest cell's height.
class SvcGrid extends StatelessWidget {
  const SvcGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 20,
    this.runSpacing = 20,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) cells.add(SizedBox(width: spacing));
        final index = i + j;
        cells.add(Expanded(
          child: index < children.length
              ? children[index]
              : const SizedBox.shrink(),
        ));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// Intro on the left, content on the right; stacks vertically below desktop.
class SvcSplit extends StatelessWidget {
  const SvcSplit({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 3,
    this.rightFlex = 7,
    this.gap = 48,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!SvcLayout.isDesktop(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(height: 32), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        SizedBox(width: gap),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}

int svcColumns(
  BuildContext context, {
  int desktop = 3,
  int tablet = 2,
  int mobile = 1,
}) {
  if (SvcLayout.isDesktop(context)) return desktop;
  if (SvcLayout.isMobile(context)) return mobile;
  return tablet;
}
