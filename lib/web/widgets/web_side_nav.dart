import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/auth/permissions.dart';
import '../../core/router/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../../shared/widgets/app_drawer.dart'
    show drawerCompaniesCountProvider, drawerUsersCountProvider;
import '../theme/web_tokens.dart';

/// One destination in the web side navigation.
class WebNavEntry {
  WebNavEntry({
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
    AppLocalizations? l10n,
  }) {
    return [
      WebNavEntry(
        label: l10n?.dashboard ?? 'Dashboard',
        route: Routes.webDashboard,
        svgIcon: 'assets/images/menu_home.svg',
      ),
      if (Permissions.canAccessRoute(role, Routes.amcs))
        WebNavEntry(
          label: l10n?.companyList ?? "Company's List",
          route: Routes.amcs,
          svgIcon: 'assets/images/menu_company_list.svg',
          badge: companiesCount?.toString(),
        ),
      if (Permissions.canAccessEquipmentList(role))
        WebNavEntry(
          label: l10n?.equipmentList ?? 'Equipment List',
          route: Routes.equipmentList,
          icon: Icons.precision_manufacturing_outlined,
        ),
      WebNavEntry(
        label: role.isTechnicianLevel
            ? (l10n?.myTasks ?? 'My Tasks')
            : role.isClientSide
                ? (l10n?.myServiceTasks ?? 'My Service Tasks')
                : (l10n?.taskBoard ?? 'Task Board'),
        route: Routes.tasks,
        svgIcon: 'assets/images/menu_tasks_list.svg',
      ),
      if (Permissions.canAssignTasks(role))
        WebNavEntry(
          label: l10n?.ticketQueue ?? 'Ticket Queue',
          route: Routes.ticketQueue,
          svgIcon: 'assets/images/menu_assign_tasks.svg',
        ),
      // Super Admin gets the personal My Service Tasks view only (My Tasks
      // is intentionally not shown for Super Admin).
      if (role == UserRole.superAdmin) ...[
        WebNavEntry(
          label: l10n?.myServiceTasks ?? 'My Service Tasks',
          route: Routes.myServiceTasks,
          icon: Icons.home_repair_service_outlined,
        ),
      ],
      // EG Manager gets a personal My Tasks view.
      if (role == UserRole.manager)
        WebNavEntry(
          label: l10n?.myTasks ?? 'My Tasks',
          route: Routes.myTasks,
          icon: Icons.task_alt_outlined,
        ),
      WebNavEntry(
        label: l10n?.search ?? 'Search',
        route: Routes.globalSearch,
        svgIcon: 'assets/images/menu_qr_scanner.svg',
      ),
      WebNavEntry(
        label: l10n?.announcements ?? 'Announcements',
        route: Routes.announcements,
        icon: Icons.campaign_outlined,
      ),
      if (Permissions.canRaiseTasks(role))
        WebNavEntry(
          label: l10n?.createTask ?? 'Create Task',
          route: '${Routes.addTask}/new',
          svgIcon: 'assets/images/menu_add.svg',
        ),
      if (Permissions.canCreateIndividualTask(role))
        WebNavEntry(
          label: l10n?.createIndividualTask ?? 'Create Individual Task',
          route: Routes.createIndividualTask,
          svgIcon: 'assets/images/menu_technicians.svg',
        ),
      if (Permissions.canManageAmcs(role))
        WebNavEntry(
          label: l10n?.addEquipment ?? 'Add Equipment',
          route: '${Routes.addEquipment}/new',
          svgIcon: 'assets/images/menu_add.svg',
        ),
      if (Permissions.canManageUsers(role))
        WebNavEntry(
          label: l10n?.usersList ?? 'Users List',
          route: Routes.usersList,
          svgIcon: 'assets/images/menu_users.svg',
          badge: usersCount?.toString(),
          badgeColor: const Color(0xFFFF2F00),
        ),

      if (Permissions.canManageAmcs(role))
        WebNavEntry(
          label: l10n?.createCompany ?? 'Create Company',
          route: Routes.createAmc,
          svgIcon: 'assets/images/menu_flag.svg',
        ),
      if (Permissions.canManageIssueTypes(role))
        WebNavEntry(
          label: l10n?.issueTypes ?? 'Issue Types',
          route: Routes.issueTypes,
          icon: Icons.build_circle_outlined,
        ),
      if (Permissions.canViewRenewals(role))
        WebNavEntry(
          label: l10n?.amcRenewals ?? 'AMC Renewals',
          route: Routes.amcRenewals,
          svgIcon: 'assets/images/menu_flag.svg',
        ),
      if (Permissions.canManagePmSchedule(role))
        WebNavEntry(
          label: l10n?.pmSchedule ?? 'PM Schedule',
          route: Routes.pmSchedule,
          svgIcon: 'assets/images/menu_tasks_list.svg',
        ),
      if (Permissions.canBulkUpload(role)) ...[
        WebNavEntry(
          label: l10n?.uploadEquipments ?? 'Upload Equipments Excel Data',
          route: Routes.uploadEquipments,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: l10n?.uploadTechnicians ?? 'Upload Service Engineers Excel Data',
          route: Routes.uploadTechnicians,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: l10n?.uploadCompanies ?? 'Upload Company Excel Data',
          route: Routes.uploadAmc,
          svgIcon: 'assets/images/menu_cloud_upload.svg',
        ),
        WebNavEntry(
          label: l10n?.downloadQr ?? 'Download QR',
          route: Routes.downloadQr,
          svgIcon: 'assets/images/menu_qr_scanner.svg',
        ),
      ],
      if (Permissions.canViewTechnicianPerformance(role))
        WebNavEntry(
          label: l10n?.technicianPerformance ?? 'Service Engineer Performance',
          route: Routes.technicianPerformance,
          svgIcon: 'assets/images/menu_technicians.svg',
        ),
      if (Permissions.canViewAuditLog(role))
        WebNavEntry(
          label: l10n?.activityHistory ?? 'Activity History',
          route: Routes.auditLog,
          icon: Icons.history,
        ),
      if (Permissions.canViewAnalytics(role))
        WebNavEntry(
          label: l10n?.analytics ?? 'Analytics',
          route: Routes.analytics,
          icon: Icons.bar_chart_outlined,
        ),
      if (Permissions.canViewReports(role))
        WebNavEntry(
          label: l10n?.reports ?? 'Reports & Export',
          route: Routes.reports,
          icon: Icons.assessment_outlined,
        ),
      if (Permissions.canViewReports(role))
        WebNavEntry(
          label: l10n?.enquiries ?? 'Enquiries',
          route: Routes.enquiries,
          icon: Icons.help_outline,
        ),
      if (Permissions.hasProfileTab(role))
        WebNavEntry(
          label: l10n?.profile ?? 'Profile',
          route: Routes.profile,
          icon: Icons.person_outline,
        ),
      WebNavEntry(
        label: l10n?.changePassword ?? 'Change Password',
        route: Routes.changePassword,
        icon: Icons.lock_outline,
      ),
      WebNavEntry(
        label: l10n?.settings ?? 'Settings',
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
    final l10n = AppLocalizations.of(context);
    final entries = entriesFor(
      role,
      companiesCount: ref.watch(drawerCompaniesCountProvider),
      usersCount: usersCount,
      l10n: l10n,
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
      child: CustomScrollView(
        primary: false,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
          ),
          if (!collapsed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 0, 8),
                child: Text(
                  l10n?.menu ?? 'MENU',
                  style: WebTokens.eyebrow(color: Colors.white54),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  return _WebNavTile(
                    entry: entry,
                    active: _isActive(entry.route),
                    collapsed: collapsed,
                    onTap: () => onNavigate(entry.route),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 4),
                child: _WebNavTile(
                  entry: WebNavEntry(
                    label: l10n?.logout ?? 'Logout',
                    route: Routes.login,
                    icon: Icons.logout,
                  ),
                  active: false,
                  collapsed: collapsed,
                  onTap: onSignOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(String route) {
    if (activeRoute == route) return true;
    // Sub-routes (e.g. /tasks/123) keep their parent module highlighted.
    if (activeRoute.startsWith('$route/')) return true;
    // Task details opened from anywhere defaults to the Tasks highlight.
    if (activeRoute.startsWith(Routes.taskDetails) && route == Routes.tasks) {
      return true;
    }
    // Nested/detail pages keep their parent module highlighted.
    final parent = _parentRoute(activeRoute);
    if (parent != null && parent == route) return true;
    return false;
  }

  static String? _parentRoute(String location) {
    if (location == Routes.addUser ||
        location.startsWith('${Routes.addUser}/')) {
      return Routes.usersList;
    }
    if (location == Routes.addTask ||
        location.startsWith('${Routes.addTask}/') ||
        location == Routes.createIndividualTask ||
        location.startsWith('${Routes.createIndividualTask}/') ||
        location == Routes.assignTasks ||
        location.startsWith('${Routes.assignTasks}/')) {
      return Routes.tasks;
    }
    if (location == Routes.createAmc ||
        location.startsWith('${Routes.createAmc}/') ||
        location == Routes.addEquipment ||
        location.startsWith('${Routes.addEquipment}/') ||
        location.startsWith(Routes.equipmentDetails) ||
        location.startsWith(Routes.companyDetails) ||
        location.startsWith(Routes.companyTasks) ||
        location.startsWith(Routes.companyEquipments)) {
      return Routes.amcs;
    }
    if (location.startsWith(Routes.equipmentQr) ||
        location.startsWith(Routes.verifiedEquipments)) {
      return Routes.equipmentList;
    }
    if (location.startsWith(Routes.technicianTasks) ||
        location.startsWith(Routes.techniciansList)) {
      return Routes.techniciansList;
    }
    if (location == Routes.editProfile ||
        location.startsWith('${Routes.editProfile}/') ||
        location == Routes.changePassword ||
        location.startsWith('${Routes.changePassword}/')) {
      return Routes.profile;
    }
    if (location.startsWith(Routes.taskBoard)) {
      return Routes.taskBoard;
    }
    return null;
  }
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
            placeholderBuilder: (_) => Icon(
              entry.icon ?? Icons.circle_outlined,
              size: 20,
              color: fg,
            ),
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
            horizontal: widget.collapsed ? 12 : 8,
            vertical: 3,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 12,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: WebTokens.fontFamily,
                      fontSize: 13.5,
                      height: 1.3,
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
