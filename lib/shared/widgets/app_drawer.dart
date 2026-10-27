import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../providers/auth_state_provider.dart';

/// Number of companies visible to the signed-in user (drawer badge).
final drawerCompaniesCountProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(companiesProvider).valueOrNull?.length;
});

/// Number of users the signed-in user manages (drawer badge). Admins read the
/// global `getUserStats` total; a Client Admin counts their companies' users.
final drawerUsersCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  final role = ref.watch(currentUserRoleProvider);
  try {
    if (role == UserRole.superAdmin || role == UserRole.manager) {
      return (await ref.watch(userStatsProvider.future)).total;
    }
    if (role == UserRole.clientAdmin) {
      return (await ref.watch(evergreenRepositoryProvider).getUsers()).length;
    }
  } catch (_) {
    // Badge is informational; hide it when the count can't be loaded.
  }
  return null;
});

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final size = MediaQuery.of(context).size;
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final companiesCount = ref.watch(drawerCompaniesCountProvider);
    final usersCount = Permissions.canManageUsers(role)
        ? ref.watch(drawerUsersCountProvider).valueOrNull
        : null;

    return Drawer(
      backgroundColor: Colors.white,
      width: size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Stack(
        children: [
          // Background image with opacity
          Positioned(
            left: -93,
            top: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/background.png',
                width: 440,
                height: 955,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with user profile and close button
                _buildHeader(context, user?.name ?? role.label, role.label),

                const SizedBox(height: 8),

                // Menu Label
                const Padding(
                  padding: EdgeInsets.only(left: 23, top: 8, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF545454),
                      ),
                    ),
                  ),
                ),

                // Menu Items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuItem(
                          context,
                          svgIcon: 'assets/images/menu_home.svg',
                          title: 'Home',
                          isSelected: location == Routes.home,
                          onTap: () {
                            Navigator.pop(context);
                            context.go(Routes.home);
                          },
                        ),
                        if (Permissions.canAccessRoute(role, Routes.amcs))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_company_list.svg',
                            title: "Company's List",
                            badge: companiesCount?.toString(),
                            isSelected: location == Routes.amcs,
                            onTap: () {
                              Navigator.pop(context);
                              context.go(Routes.amcs);
                            },
                          ),
                        _buildMenuItem(
                          context,
                          svgIcon: 'assets/images/menu_tasks_list.svg',
                          title: role.isTechnicianLevel
                              ? 'My Tasks'
                              : role.isClientSide
                                  ? 'My Service Tasks'
                                  : 'Task Board',
                          isSelected: location == Routes.tasks,
                          onTap: () {
                            Navigator.pop(context);
                            context.go(Routes.tasks);
                          },
                        ),
                        _buildMenuItem(
                          context,
                          svgIcon: 'assets/images/menu_qr_scanner.svg',
                          title: 'Search',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(Routes.globalSearch);
                          },
                        ),
                        if (Permissions.canRaiseTasks(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_add.svg',
                            title: 'Create Task',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('${Routes.addTask}/new');
                            },
                          ),
                        if (Permissions.canCreateIndividualTask(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_technicians.svg',
                            title: 'Create Individual Task',
                            isSelected: location == Routes.createIndividualTask,
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.createIndividualTask);
                            },
                          ),
                        if (Permissions.canManageAmcs(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_add.svg',
                            title: 'Add Equipment',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('${Routes.addEquipment}/new');
                            },
                          ),
                        if (Permissions.canManageUsers(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_users.svg',
                            title: 'Users List',
                            badge: usersCount?.toString(),
                            badgeColor: const Color(0xFFFF2F00),
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.usersList);
                            },
                          ),
                        if (Permissions.canAssignTasks(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_assign_tasks.svg',
                            title: 'Ticket Queue',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.ticketQueue);
                            },
                          ),
                        if (Permissions.canManageAmcs(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_flag.svg',
                            title: 'Create Company',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.createAmc);
                            },
                          ),
                        if (Permissions.canViewRenewals(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_flag.svg',
                            title: 'AMC Renewals',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.amcRenewals);
                            },
                          ),
                        if (Permissions.canManagePmSchedule(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_tasks_list.svg',
                            title: 'PM Schedule',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.pmSchedule);
                            },
                          ),
                        if (Permissions.canBulkUpload(role)) ...[
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_cloud_upload.svg',
                            title: 'Upload Equipments Excel Data',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.uploadEquipments);
                            },
                          ),
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_cloud_upload.svg',
                            title: 'Upload Service Engineers Excel Data',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.uploadTechnicians);
                            },
                          ),
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_cloud_upload.svg',
                            title: 'Upload Company Excel Data',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.uploadAmc);
                            },
                          ),
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_qr_scanner.svg',
                            title: 'Download QR',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.downloadQr);
                            },
                          ),
                        ],
                        if (Permissions.canViewTechnicianPerformance(role))
                          _buildMenuItem(
                            context,
                            svgIcon: 'assets/images/menu_technicians.svg',
                            title: 'Service Engineer Performance',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.technicianPerformance);
                            },
                          ),
                        if (Permissions.canViewAuditLog(role))
                          _buildMenuItem(
                            context,
                            icon: Icons.history,
                            title: 'Activity History',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.auditLog);
                            },
                          ),
                        if (Permissions.showChangePasswordInDrawer(role))
                          _buildMenuItem(
                            context,
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.changePassword);
                            },
                          ),
                        if (Permissions.showChangePasswordInDrawer(role))
                          _buildMenuItem(
                            context,
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            isSelected: location == Routes.settings,
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.settings);
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Logout Button
                _buildLogoutButton(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String roleLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 14, 0),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/avatar_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF2196F3),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0EA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF125420),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Close Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/menu_close.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Colors.black54,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pass either [svgIcon] (an asset path) or [icon].
  Widget _buildMenuItem(
    BuildContext context, {
    String? svgIcon,
    IconData? icon,
    required String title,
    String? badge,
    Color? badgeColor,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    assert(svgIcon != null || icon != null);
    final iconColor =
        isSelected ? const Color(0xFF125420) : const Color(0xFF1F1F1F);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? const Color(0xFFEBF0EA) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                if (svgIcon != null)
                  SvgPicture.asset(
                    svgIcon,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                else
                  Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF125420)
                          : const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                // Badge
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFFFF2F00),
                      borderRadius: BorderRadius.circular(31),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontFamily: 'Averta',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Branded logout confirmation dialog — icon badge, centered copy, and two
  /// stacked full-width buttons.
  Future<bool?> _showLogoutDialog(BuildContext context) {
    const red = Color(0xFFE52020);
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDECEC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7D5D5),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.logout_rounded, color: red, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Log out?',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C2B20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You'll need to sign in again to\naccess your account.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(height: 24),
              // Logout (primary, destructive)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Yes, Log out',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Cancel (neutral)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F4F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(31, 16, 31, 24),
      child: GestureDetector(
        onTap: () async {
          final shouldLogout = await _showLogoutDialog(context);
          if (shouldLogout == true && context.mounted) {
            // Perform logout via the controller so the persisted token is
            // cleared (session only ends on explicit logout).
            await ref.read(authControllerProvider).logout();
            if (context.mounted) {
              context.go(Routes.login);
            }
          }
        },
        child: Container(
          width: double.infinity,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFFF3D8D8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/menu_logout.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFE52020),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'LOGOUT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE52020),
                  letterSpacing: -0.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
