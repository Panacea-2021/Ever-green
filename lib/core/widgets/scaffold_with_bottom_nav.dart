import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../auth/permissions.dart';
import '../router/routes.dart';

/// One tab in the bottom navigation bar.
class BottomNavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const BottomNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// One option in the center "+" chooser.
class QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class ScaffoldWithBottomNav extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
  });

  /// Approximate content height of the bottom app bar (icons + labels +
  /// internal padding), excluding the system safe-area inset.
  static const double kBottomNavHeight = 64;

  /// How far the center-docked FAB pokes above the bar.
  static const double kFabOverhang = 28;

  /// Width kept free in the middle of the bar for the docked FAB.
  static const double _kFabGap = 72;

  static const Color _green = Color(0xFF106220);

  /// Bottom padding a root-tab scroll view should reserve so its last item
  /// clears the bottom nav bar and the docked FAB. Because the shell uses
  /// `extendBody: true`, child screens draw behind the bar, so they must add
  /// this space themselves.
  static double bottomInset(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return kBottomNavHeight + kFabOverhang + safe;
  }

  /// Bottom tabs for [role]: Home and Tasks for everyone; Super Admin and
  /// Manager also get AMCs, Profile and Settings.
  static List<BottomNavTab> tabsFor(UserRole role) {
    final admin = Permissions.hasProfileTab(role);
    return [
      const BottomNavTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        route: Routes.home,
      ),
      if (admin)
        const BottomNavTab(
          icon: Icons.description_outlined,
          activeIcon: Icons.description,
          label: 'AMCs',
          route: Routes.amcs,
        ),
      const BottomNavTab(
        icon: Icons.checklist_outlined,
        activeIcon: Icons.checklist,
        label: 'Tasks',
        route: Routes.tasks,
      ),
      if (admin)
        const BottomNavTab(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          route: Routes.profile,
        ),
      if (admin)
        const BottomNavTab(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: 'Settings',
          route: Routes.settings,
        ),
    ];
  }

  /// Options in the center "+" chooser for [role]. Empty when the role has
  /// no center button.
  static List<QuickAction> quickActionsFor(UserRole role) {
    if (!Permissions.hasCenterAction(role)) return const [];
    return [
      const QuickAction(
        icon: Icons.qr_code_scanner,
        label: 'Scan QR',
        subtitle: 'Scan an equipment QR code',
        color: _green,
        route: Routes.scanner,
      ),
      if (Permissions.canRaiseTasks(role) &&
          Permissions.canAccessRoute(role, Routes.addTask))
        const QuickAction(
          icon: Icons.add_task,
          label: 'Add Task',
          subtitle: 'Create a new service task',
          color: Color(0xFF2196F3),
          route: '${Routes.addTask}/new',
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final hasCenter = Permissions.hasCenterAction(role);
    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton:
          hasCenter ? _buildFloatingActionButton(context, role) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar:
          _buildBottomAppBar(context, tabsFor(role), hasCenter: hasCenter),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, UserRole role) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF106220),
            Color(0xFF0D4D19),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF106220).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'bottom-nav-center-action',
        tooltip: 'Quick actions',
        onPressed: () => _showQuickActions(context, role),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, UserRole role) {
    final actions = quickActionsFor(role);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // Anchor the sheet to the bottom and keep it clear of the system nav
      // bar. Without these the sheet can mis-position under `extendBody: true`.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(sheetContext).viewPadding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C2B20),
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final action in actions) ...[
              _buildQuickActionTile(sheetContext, context, action),
              if (action != actions.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext sheetContext,
    BuildContext shellContext,
    QuickAction action,
  ) {
    return Material(
      color: action.color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(sheetContext);
          shellContext.push(action.route);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C2B20),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: action.color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar(
    BuildContext context,
    List<BottomNavTab> tabs, {
    required bool hasCenter,
  }) {
    // Every tab gets an equal slot and scales down instead of overflowing on
    // narrow phones or large text.
    final items = [
      for (final t in tabs)
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildNavItem(context, t),
            ),
          ),
        ),
    ];
    final Widget row;
    if (hasCenter) {
      // Each side of the docked FAB gets half the bar, so the FAB stays
      // centered whether there are 2 or 3 tabs.
      final split = (items.length + 1) ~/ 2;
      row = Row(
        children: [
          Expanded(child: Row(children: items.sublist(0, split))),
          const SizedBox(width: _kFabGap),
          Expanded(child: Row(children: items.sublist(split))),
        ],
      );
    } else {
      row = Row(children: items);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          // The Scaffold lets the bottom bar be as tall as the screen; without
          // a fixed height the centered tabs would fill it.
          child: SizedBox(height: kBottomNavHeight - 12, child: row),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, BottomNavTab tab) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLocation == tab.route;
    final selectedBgColor = _green.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context.go(tab.route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              color: isSelected ? _green : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                height: 1.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _green : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
