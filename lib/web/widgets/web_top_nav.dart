import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/auth/permissions.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../../shared/widgets/app_drawer.dart'
    show drawerCompaniesCountProvider, drawerUsersCountProvider;
import '../theme/web_tokens.dart';
import 'web_side_nav.dart' show WebNavEntry, WebSideNav;

/// Horizontal top navigation bar — same dark-green gradient and item style as
/// the left side nav, but laid out across the top of the page.
/// Primary nav items scroll horizontally; overflow items appear in a "More ▾"
/// dropdown that is styled identically to the original side panel.
class WebTopNav extends ConsumerStatefulWidget {
  const WebTopNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final Future<void> Function() onSignOut;

  static const double height = 68.0;

  @override
  ConsumerState<WebTopNav> createState() => _WebTopNavState();
}

class _WebTopNavState extends ConsumerState<WebTopNav> {
  final _moreKey = GlobalKey();
  bool _moreOpen = false;

  bool _isActive(String route) => widget.activeRoute == route;

  void _tap(String route) {
    setState(() => _moreOpen = false);
    widget.onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(currentUserProvider);
    final usersCount = Permissions.canManageUsers(role)
        ? ref.watch(drawerUsersCountProvider).valueOrNull
        : null;
    final entries = WebSideNav.entriesFor(
      role,
      companiesCount: ref.watch(drawerCompaniesCountProvider),
      usersCount: usersCount,
    );

    // Split: everything except the last few utility items goes in the scroll
    // area; Change Password / Settings / Profile go in the user dropdown.
    final skipInBar = {
      Routes.profile,
      Routes.changePassword,
      Routes.settings,
      Routes.login, // logout sentinel
    };
    final mainEntries =
        entries.where((e) => !skipInBar.contains(e.route)).toList();

    final userName = user?.name ?? role.label;
    final roleLabel = role.label;

    return Container(
      height: WebTopNav.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E501B), WebTokens.greenDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          _TopLogo(onTap: () => _tap(Routes.webDashboard)),

          // Thin separator
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // ── Scrollable nav items ───────────────────────────────────────────
          Expanded(
            child: ScrollConfiguration(
              behavior: _HideScrollbar(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    for (final e in mainEntries)
                      _TopNavTile(
                        entry: e,
                        active: _isActive(e.route),
                        onTap: () => _tap(e.route),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── "More" overflow button ─────────────────────────────────────────
          _MoreButton(
            menuKey: _moreKey,
            isOpen: _moreOpen,
            entries: entries
                .where((e) => skipInBar.contains(e.route) && e.route != Routes.login)
                .toList(),
            activeRoute: widget.activeRoute,
            onTap: _tap,
            onToggle: () {
              setState(() => _moreOpen = !_moreOpen);
              if (!_moreOpen) {
                _showMoreMenu(context, entries
                    .where((e) =>
                        skipInBar.contains(e.route) && e.route != Routes.login,)
                    .toList(),);
              }
            },
          ),

          // Thin separator
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // ── User avatar + logout ───────────────────────────────────────────
          _UserArea(
            userName: userName,
            roleLabel: roleLabel,
            onSignOut: () async {
              setState(() => _moreOpen = false);
              await widget.onSignOut();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, List<WebNavEntry> extraEntries) {
    final renderBox =
        _moreKey.currentContext?.findRenderObject() as RenderBox?;
    final pos = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    late OverlayEntry oe;
    oe = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                oe.remove();
                setState(() => _moreOpen = false);
              },
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: pos.dy + size.height + 6,
            right: MediaQuery.of(context).size.width - pos.dx - size.width,
            child: _MoreDropdown(
              entries: extraEntries,
              activeRoute: widget.activeRoute,
              onTap: (r) {
                oe.remove();
                setState(() => _moreOpen = false);
                _tap(r);
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(oe);
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _TopLogo extends StatelessWidget {
  const _TopLogo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: WebTokens.green, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Evergreen',
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single top nav tile — matches left-menu tile style ───────────────────────

class _TopNavTile extends StatefulWidget {
  const _TopNavTile({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final WebNavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TopNavTile> createState() => _TopNavTileState();
}

class _TopNavTileState extends State<_TopNavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final entry = widget.entry;

    final fg = active ? Colors.white : Colors.white70;
    final bg = active
        ? Colors.white.withValues(alpha: 0.16)
        : _hover
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;

    final iconWidget = entry.svgIcon != null
        ? SvgPicture.asset(
            entry.svgIcon!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          )
        : Icon(entry.icon, size: 17, color: fg);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? const Border(
                    bottom: BorderSide(color: WebTokens.mint, width: 2.5),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 7),
              Text(
                entry.label,
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (entry.badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.badgeColor ?? WebTokens.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.badge!,
                    style: TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: entry.badgeColor != null
                          ? Colors.white
                          : WebTokens.greenDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── "More" overflow button ────────────────────────────────────────────────────

class _MoreButton extends StatefulWidget {
  const _MoreButton({
    required this.menuKey,
    required this.isOpen,
    required this.entries,
    required this.activeRoute,
    required this.onTap,
    required this.onToggle,
  });

  final GlobalKey menuKey;
  final bool isOpen;
  final List<WebNavEntry> entries;
  final String activeRoute;
  final ValueChanged<String> onTap;
  final VoidCallback onToggle;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isOpen || _hover
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: widget.menuKey,
        onTap: widget.onToggle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.more_horiz, size: 18, color: Colors.white70),
              const SizedBox(width: 4),
              const Text(
                'More',
                style: TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                widget.isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 15,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── More dropdown — same card style as original left side panel ──────────────

class _MoreDropdown extends StatelessWidget {
  const _MoreDropdown({
    required this.entries,
    required this.activeRoute,
    required this.onTap,
  });

  final List<WebNavEntry> entries;
  final String activeRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E501B), WebTokens.greenDeep],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: entries
              .map((e) => _DropdownNavTile(
                    entry: e,
                    active: activeRoute == e.route,
                    onTap: () => onTap(e.route),
                  ),)
              .toList(),
        ),
      ),
    );
  }
}

class _DropdownNavTile extends StatefulWidget {
  const _DropdownNavTile({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final WebNavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_DropdownNavTile> createState() => _DropdownNavTileState();
}

class _DropdownNavTileState extends State<_DropdownNavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final entry = widget.entry;
    final fg = active ? Colors.white : Colors.white70;
    final bg = active
        ? Colors.white.withValues(alpha: 0.16)
        : _hover
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;

    final iconWidget = entry.svgIcon != null
        ? SvgPicture.asset(
            entry.svgIcon!,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          )
        : Icon(entry.icon, size: 18, color: fg);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? const Border(
                    left: BorderSide(color: WebTokens.mint, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: active
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.07),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: WebTokens.fontFamily,
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (entry.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.badgeColor ?? WebTokens.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.badge!,
                    style: TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: entry.badgeColor != null
                          ? Colors.white
                          : WebTokens.greenDeep,
                    ),
                  ),
                ),
              if (active)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User area (right side) ────────────────────────────────────────────────────

class _UserArea extends StatefulWidget {
  const _UserArea({
    required this.userName,
    required this.roleLabel,
    required this.onSignOut,
  });

  final String userName;
  final String roleLabel;
  final Future<void> Function() onSignOut;

  @override
  State<_UserArea> createState() => _UserAreaState();
}

class _UserAreaState extends State<_UserArea> {
  bool _hover = false;
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: _key,
        onTap: () => _showMenu(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontFamily: WebTokens.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.roleLabel,
                    style: TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    final pos = rb?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = rb?.size ?? Size.zero;
    final screenW = MediaQuery.of(context).size.width;

    late OverlayEntry oe;
    oe = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => oe.remove(),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: pos.dy + size.height + 6,
            right: screenW - pos.dx - size.width,
            child: _UserDropdown(
              onLogout: () {
                oe.remove();
                widget.onSignOut();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(oe);
  }
}

class _UserDropdown extends StatelessWidget {
  const _UserDropdown({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E501B), WebTokens.greenDeep],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserDropdownItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDropdownItem extends StatefulWidget {
  const _UserDropdownItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_UserDropdownItem> createState() => _UserDropdownItemState();
}

class _UserDropdownItemState extends State<_UserDropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(widget.icon, size: 17, color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hides the horizontal scrollbar ──────────────────────────────────────────

class _HideScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}
