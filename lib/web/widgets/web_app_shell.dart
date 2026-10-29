import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';

/// A navigation destination in the web side nav.
class WebNavItem {
  const WebNavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// Shared desktop app shell for authenticated web screens: a fixed left side
/// navigation rail + a top bar, with the page [child] in the content area.
/// On narrow widths the side nav collapses to an icon rail.
class WebAppShell extends ConsumerWidget {
  const WebAppShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.child,
  });

  final String activeRoute;
  final String title;
  final Widget child;

  static const _items = [
    WebNavItem('Dashboard', Icons.dashboard_outlined, Routes.webDashboard),
    WebNavItem('Tasks', Icons.checklist_rtl_outlined, Routes.tasks),
    WebNavItem('AMCs', Icons.description_outlined, Routes.amcs),
    WebNavItem('Profile', Icons.person_outline, Routes.profile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.of(context).size.width;
    final collapsed = w < 1100;
    final navWidth = collapsed ? 76.0 : 248.0;
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);

    Future<void> signOut() async {
      await ref.read(authControllerProvider).logout();
      if (context.mounted) context.go(Routes.home);
    }

    return Scaffold(
      backgroundColor: WebTokens.cream,
      body: Row(
        children: [
          _SideNav(
            width: navWidth,
            collapsed: collapsed,
            activeRoute: activeRoute,
            items: _items,
            onSignOut: signOut,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: title,
                  userName: user?.name ?? 'User',
                  roleLabel: role.label,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: child,
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

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.width,
    required this.collapsed,
    required this.activeRoute,
    required this.items,
    required this.onSignOut,
  });

  final double width;
  final bool collapsed;
  final String activeRoute;
  final List<WebNavItem> items;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E501B), Color(0xFF0A3D14)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 22,
              vertical: 24,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.eco, color: WebTokens.green, size: 20),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Evergreen',
                    style: WebTokens.heading(20, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            _NavTile(
              item: item,
              active: activeRoute == item.route,
              collapsed: collapsed,
              onTap: item.route == Routes.login ? onSignOut : null,
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _NavTile(
              item: const WebNavItem(
                'Sign out',
                Icons.logout,
                Routes.login,
              ),
              active: false,
              collapsed: collapsed,
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.collapsed,
    this.onTap,
  });

  final WebNavItem item;
  final bool active;
  final bool collapsed;
  final Future<void> Function()? onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final bg = active
        ? Colors.white.withValues(alpha: 0.16)
        : _hover
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () => context.go(widget.item.route),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 14,
            vertical: 4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 16,
            vertical: 13,
          ),
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
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: active ? Colors.white : Colors.white70,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 14),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontFamily: WebTokens.fontFamily,
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : Colors.white70,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
  });

  final String title;
  final String userName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          Text(title, style: WebTokens.heading(22)),
          const Spacer(),
          // Search pill.
          Container(
            width: 260,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: WebTokens.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: WebTokens.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: WebTokens.faint),
                const SizedBox(width: 8),
                Text('Search…', style: WebTokens.bodyText(13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTokens.cream,
              shape: BoxShape.circle,
              border: Border.all(color: WebTokens.line),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 20,
              color: WebTokens.ink,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: WebTokens.mintSoft,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: WebTokens.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: WebTokens.green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: WebTokens.bodyText(
                      13.5,
                      color: WebTokens.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(roleLabel, style: WebTokens.bodyText(11.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
