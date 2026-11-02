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

/// One destination in the web side navigation.
class WebNavEntry {
  const WebNavEntry({
    required this.label,
    required this.route,
    this.svgIcon,
    this.icon,
    this.badge,
    this.badgeColor,
  });

  final String label;
  final String route;
  final String? svgIcon;
  final IconData? icon;
  final String? badge;
  final Color? badgeColor;
}

/// Web side navigation listing every dashboard module the signed-in role can
/// open — the same items, titles, icons and permissions as the mobile drawer.
/// Collapses to an icon rail on narrow windows.
class WebSideNav extends ConsumerWidget {
  const WebSideNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final Future<void> Function() onSignOut;

  static const collapseBelow = 1100.0;
  static const expandedWidth = 264.0;
  static const collapsedWidth = 76.0;

  static double widthFor(double screenWidth) =>
      screenWidth < collapseBelow ? collapsedWidth : expandedWidth;

  static List<WebNavEntry> entriesFor(
    UserRole role, {
    int? companiesCount,
    int? usersCount,
  }) {
    return [
      const WebNavEntry(
        label: 'Dashboard',
        route: Routes.webDashboard,
        svgIcon: 'assets/images/menu_home.svg',
      ),
      if (Permissions.canAccessRoute(role, Routes.amcs))
        WebNavEntry(
          label: "Company's List",
          route: Routes.amcs,
          svgIcon: 'assets/images/menu_company_list.svg',
          badge: companiesCount?.toString(),
        ),
      WebNavEntry(
        label: role.isTechnicianLevel
            ? 'My Tasks'
            : role.isClientSide
                ? 'My Service Tasks'
                : 'Task Board',
        route: Routes.tasks,
        svgIcon: 'assets/images/menu_tasks_list.svg',
      ),
      const WebNavEntry(
        label: 'Search',
        route: Routes.globalSearch,
        svgIcon: 'assets/images/menu_qr_scanner.svg',
      ),
      if (Permissions.canRaiseTasks(role))
        const WebNavEntry(
          label: 'Create Task',
          route: '${Routes.addTask}/new',
          svgIcon: 'assets/images/menu_add.svg',
        ),
      if (Permissions.canCreateIndividualTask(role))
        const WebNavEntry(
          label: 'Create Individual Task',
          route: Routes.createIndividualTask,
          svgIcon: 'assets/images/menu_technicians.svg',
        ),
      if (Permissions.canManageAmcs(role))
        const WebNavEntry(
          label: 'Add Equipment',
          route: '${Routes.addEquipment}/new',
          svgIcon: 'assets/images/menu_add.svg',
        ),
      if (Permissions.canManageUsers(role))
        WebNavEntry(
          label: 'Users List',
          route: Routes.usersList,
          svgIcon: 'assets/images/menu_users.svg',
          badge: usersCount?.toString(),
          badgeColor: const Color(0xFFFF2F00),
        ),
      if (Permissions.canAssignTasks(role))
        const WebNavEntry(
          label: 'Ticket Queue',
          route: Routes.ticketQueue,
          svgIcon: 'assets/images/menu_assign_tasks.svg',
        ),
      if (Permissions.canManageAmcs(role))
        const WebNavEntry(
          label: 'Create Company',
          route: Routes.createAmc,
          svgIcon: 'assets/images/menu_flag.svg',
        ),
      if (Permissions.canViewRenewals(role))
        const WebNavEntry(
          label: 'AMC Renewals',
          route: Routes.amcRenewals,
          svgIcon: 'assets/images/menu_flag.svg',
        ),
      if (Permissions.canManagePmSchedule(role))
        const WebNavEntry(
          label: 'PM Schedule',
          route: Routes.pmSchedule,
          svgIcon: 'assets/images/menu_tasks_list.svg',
        ),
      if (Permissions.canBulkUpload(role)) ...const [
        WebNavEntry(
          label: 'Upload Equipments Excel Data',
          route: Routes.uploadEquipments,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: 'Upload Service Engineers Excel Data',
          route: Routes.uploadTechnicians,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: 'Upload Company Excel Data',
          route: Routes.uploadAmc,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: 'Download QR',
          route: Routes.downloadQr,
          svgIcon: 'assets/images/menu_qr_scanner.svg',
        ),
      ],
      if (Permissions.canViewTechnicianPerformance(role))
        const WebNavEntry(
          label: 'Service Engineer Performance',
          route: Routes.technicianPerformance,
          svgIcon: 'assets/images/menu_technicians.svg',
        ),
      if (Permissions.canViewAuditLog(role))
        const WebNavEntry(
          label: 'Activity History',
          route: Routes.auditLog,
          icon: Icons.history,
        ),
      if (Permissions.hasProfileTab(role))
        const WebNavEntry(
          label: 'Profile',
          route: Routes.profile,
          icon: Icons.person_outline,
        ),
      const WebNavEntry(
        label: 'Change Password',
        route: Routes.changePassword,
        icon: Icons.lock_outline,
      ),
      const WebNavEntry(
        label: 'Settings',
        route: Routes.settings,
        icon: Icons.settings_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final collapsed = screenWidth < collapseBelow;
    final role = ref.watch(currentUserRoleProvider);
    final usersCount = Permissions.canManageUsers(role)
        ? ref.watch(drawerUsersCountProvider).valueOrNull
        : null;
    final entries = entriesFor(
      role,
      companiesCount: ref.watch(drawerCompaniesCountProvider),
      usersCount: usersCount,
    );

    return Container(
      width: widthFor(screenWidth),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E501B), WebTokens.greenDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 22,
              vertical: 24,
            ),
            child: Row(
              mainAxisAlignment:
                  collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                  Flexible(
                    child: Text(
                      'Evergreen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTokens.heading(20, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 0, 8),
              child: Text(
                'MENU',
                style: WebTokens.eyebrow(color: Colors.white54),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final entry in entries)
                  _WebNavTile(
                    entry: entry,
                    active: _isActive(entry.route),
                    collapsed: collapsed,
                    onTap: () => onNavigate(entry.route),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            child: _WebNavTile(
              entry: const WebNavEntry(
                label: 'Logout',
                route: Routes.login,
                icon: Icons.logout,
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

  bool _isActive(String route) => activeRoute == route;
}

class _WebNavTile extends StatefulWidget {
  const _WebNavTile({
    required this.entry,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final WebNavEntry entry;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_WebNavTile> createState() => _WebNavTileState();
}

class _WebNavTileState extends State<_WebNavTile> {
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
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          )
        : Icon(entry.icon, size: 20, color: fg);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 14,
            vertical: 3,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 14,
            vertical: 11,
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
              iconWidget,
              if (!widget.collapsed) ...[
                const SizedBox(width: 14),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
