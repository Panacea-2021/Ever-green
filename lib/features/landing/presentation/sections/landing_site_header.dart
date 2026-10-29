import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Floating cream masthead — Figma node 54:17 (1348×68, radius 34).
class LandingSiteHeader extends StatelessWidget {
  const LandingSiteHeader({
    super.key,
    this.onHome,
    this.onServices,
    this.onIndustries,
    this.onAbout,
    this.onHowItWorks,
    this.onContact,
    this.onPrivacy,
    this.onBookRepair,
    this.onSignIn,
    this.onSearch,
    this.activeNav,
  });

  final VoidCallback? onHome;
  final VoidCallback? onServices;
  final VoidCallback? onIndustries;
  final VoidCallback? onAbout;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onContact;
  final VoidCallback? onPrivacy;
  final VoidCallback? onBookRepair;
  final VoidCallback? onSignIn;
  final VoidCallback? onSearch;
  final String? activeNav;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;
    final isMobile = width < 768;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 46,
        isMobile ? 14 : 18,
        isMobile ? 16 : 46,
        0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1348),
          child: isMobile
              ? _MobileBar(
                  onBookRepair: onBookRepair,
                  onSignIn: onSignIn,
                  onHome: onHome,
                  onServices: onServices,
                  onIndustries: onIndustries,
                  onAbout: onAbout,
                  onHowItWorks: onHowItWorks,
                  onContact: onContact,
                  onPrivacy: onPrivacy,
                )
              : _DesktopBar(
                  isCompact: isCompact,
                  onHome: onHome,
                  onServices: onServices,
                  onIndustries: onIndustries,
                  onAbout: onAbout,
                  onHowItWorks: onHowItWorks,
                  onContact: onContact,
                  onPrivacy: onPrivacy,
                  onBookRepair: onBookRepair,
                  onSignIn: onSignIn,
                  onSearch: onSearch,
                  activeNav: activeNav,
                ),
        ),
      ),
    );
  }
}

class _DesktopBar extends StatelessWidget {
  const _DesktopBar({
    required this.isCompact,
    this.onHome,
    this.onServices,
    this.onIndustries,
    this.onAbout,
    this.onHowItWorks,
    this.onContact,
    this.onPrivacy,
    this.onBookRepair,
    this.onSignIn,
    this.onSearch,
    this.activeNav,
  });

  final bool isCompact;
  final VoidCallback? onHome;
  final VoidCallback? onServices;
  final VoidCallback? onIndustries;
  final VoidCallback? onAbout;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onContact;
  final VoidCallback? onPrivacy;
  final VoidCallback? onBookRepair;
  final VoidCallback? onSignIn;
  final VoidCallback? onSearch;
  final String? activeNav;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.only(left: 32, right: 22),
      decoration: BoxDecoration(
        color: const Color(0xF0F5F7F2),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A142117),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const _BrandMark(),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavLink(
                      label: 'Home',
                      onTap: onHome,
                      active: activeNav == null || activeNav == 'Home',
                    ),
                    _NavLink(
                      label: 'Services',
                      onTap: onServices,
                      active: activeNav == 'Services',
                    ),
                    if (!isCompact)
                      _NavLink(label: 'Industries', onTap: onIndustries),
                    _NavLink(label: 'About', onTap: onAbout),
                    _NavLink(label: 'How it works', onTap: onHowItWorks),
                    _NavLink(
                      label: 'Privacy Policy',
                      onTap: onPrivacy,
                      active: activeNav == 'Privacy Policy',
                    ),
                    _NavLink(label: 'Contact', onTap: onContact),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconCircleButton(
                icon: Icons.search,
                onTap: onSearch,
              ),
              const SizedBox(width: 8),
              _HeaderCta(
                label: 'Book a repair',
                filled: true,
                onTap: onBookRepair,
              ),
              const SizedBox(width: 8),
              _HeaderCta(
                label: 'Sign in',
                filled: false,
                onTap: onSignIn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileBar extends StatelessWidget {
  const _MobileBar({
    this.onBookRepair,
    this.onSignIn,
    this.onHome,
    this.onServices,
    this.onIndustries,
    this.onAbout,
    this.onHowItWorks,
    this.onContact,
    this.onPrivacy,
  });

  final VoidCallback? onBookRepair;
  final VoidCallback? onSignIn;
  final VoidCallback? onHome;
  final VoidCallback? onServices;
  final VoidCallback? onIndustries;
  final VoidCallback? onAbout;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onContact;
  final VoidCallback? onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xF0F5F7F2),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A142117),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const _BrandMark(compact: true),
          const Spacer(),
          IconButton(
            onPressed: () => _openMenu(context),
            icon: const Icon(Icons.menu, color: LandingColors.textDark),
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        void go(VoidCallback? action) {
          Navigator.of(sheetContext).pop();
          action?.call();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetLink(label: 'Home', onTap: () => go(onHome)),
                _SheetLink(label: 'Services', onTap: () => go(onServices)),
                _SheetLink(label: 'Industries', onTap: () => go(onIndustries)),
                _SheetLink(label: 'About', onTap: () => go(onAbout)),
                _SheetLink(
                    label: 'How it works', onTap: () => go(onHowItWorks)),
                _SheetLink(label: 'Privacy Policy', onTap: () => go(onPrivacy)),
                _SheetLink(label: 'Contact', onTap: () => go(onContact)),
                const SizedBox(height: 16),
                _HeaderCta(
                  label: 'Book a repair',
                  filled: true,
                  onTap: () => go(onBookRepair),
                ),
                const SizedBox(height: 10),
                _HeaderCta(
                  label: 'Sign in',
                  filled: false,
                  onTap: () => go(onSignIn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetLink extends StatelessWidget {
  const _SheetLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: LandingTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: LandingColors.textDark,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          LandingAssets.markLogo,
          width: compact ? 22 : 26,
          height: compact ? 22 : 26,
          colorFilter: const ColorFilter.mode(
            LandingColors.primary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Evergreen',
          style: TextStyle(
            fontFamily: LandingTypography.fontFamily,
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: LandingColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active || _hover
        ? LandingColors.textDark
        : const Color(0xFF4A534C);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 14,
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatefulWidget {
  const _IconCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_IconCircleButton> createState() => _IconCircleButtonState();
}

class _IconCircleButtonState extends State<_IconCircleButton> {
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFE8EDE6) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, size: 20, color: LandingColors.textDark),
        ),
      ),
    );
  }
}

class _HeaderCta extends StatefulWidget {
  const _HeaderCta({
    required this.label,
    required this.filled,
    this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  State<_HeaderCta> createState() => _HeaderCtaState();
}

class _HeaderCtaState extends State<_HeaderCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    final bg = filled
        ? (_hover ? const Color(0xFF0C4E19) : LandingColors.primary)
        : (_hover ? const Color(0xFFF7F7F7) : Colors.white);
    final fg = filled ? Colors.white : LandingColors.textDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: const Color(0x1A142117)),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
