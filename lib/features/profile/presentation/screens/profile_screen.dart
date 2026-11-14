import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/custom_menu_icon.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/my_companies_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);

    if (kIsWeb) return _webBuild(context, ref, user, role);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
            return;
          }
          context.go(Routes.home);
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: const AppDrawer(),
        body: Stack(
          children: [
            // Same decorative background as the Home page.
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/home_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: ScaffoldWithBottomNav.bottomInset(context),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Header row: menu (drawer) on the left, centered title.
                    if (!kIsWeb)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => CustomMenuIcon(
                                onTap: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'My Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C2B20),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            // Balance the 42px menu icon so the title stays centered.
                            const SizedBox(width: 42),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildAvatar(user),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRoleBadge(role),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMenuCard(context, role),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEditProfileButton(context),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLogoutButton(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
  Widget _webBuild(
    BuildContext context,
    WidgetRef ref,
    User? user,
    UserRole role,
  ) {
    final identity = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            height: 116,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3F15), Color(0xFF1A801A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -30,
                  top: -40,
                  child: _webBubble(130, 0.10),
                ),
                Positioned(
                  left: -24,
                  bottom: -50,
                  child: _webBubble(110, 0.07),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 26),
            child: Column(
              children: [
                _buildAvatar(user),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'User',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2B20),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRoleBadge(role),
                const SizedBox(height: 24),
                _buildEditProfileButton(context),
                const SizedBox(height: 12),
                _buildLogoutButton(context, ref),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const padding = EdgeInsets.fromLTRB(28, 24, 28, 28);
          if (constraints.maxWidth < 760) {
            return SingleChildScrollView(
              primary: false,
              padding: padding,
              child: Column(
                children: [
                  identity,
                  const SizedBox(height: 24),
                  _webMenuGrid(context, role, 1),
                ],
              ),
            );
          }

          return SizedBox.expand(
            child: Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: identity),
                  const SizedBox(width: 28),
                  Expanded(
                    child: SizedBox.expand(
                      child: SingleChildScrollView(
                        primary: false,
                        padding: const EdgeInsets.only(bottom: 28),
                        child: _webMenuGrid(
                          context,
                          role,
                          constraints.maxWidth >= 1000 ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _webBubble(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  Widget _webMenuGrid(BuildContext context, UserRole role, int columns) {
    final items = <(_MenuEntry, Color)>[
      (
        _MenuEntry(
          icon: Icons.business_outlined,
          label: 'Company Profile',
          onTap: () => _showCompanySheet(context),
        ),
        const Color(0xFF106220),
      ),
      (
        _MenuEntry(
          icon: Icons.assignment_outlined,
          label: role.isClientSide ? 'My Service History' : 'My Tasks History',
          onTap: () => context.push(Routes.taskBoard),
        ),
        const Color(0xFF2563EB),
      ),
      if (Permissions.canViewAuditLog(role))
        (
          _MenuEntry(
            icon: Icons.history,
            label: 'Activity History',
            onTap: () => context.push(Routes.auditLog),
          ),
          const Color(0xFF7C3AED),
        ),
      if (Permissions.canManageUsers(role))
        (
          _MenuEntry(
            icon: Icons.groups_outlined,
            label: 'Manage Employees',
            onTap: () => context.push(Routes.usersList),
          ),
          const Color(0xFF0D9488),
        ),
      (
        _MenuEntry(
          icon: Icons.settings_outlined,
          label: 'Account Settings',
          onTap: () => context.push(Routes.settings),
        ),
        const Color(0xFFD97706),
      ),
    ];

    const gap = 18.0;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (entry, color) in items)
              SizedBox(
                width: w,
                child: _WebMenuTile(entry: entry, color: color),
              ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar
  // ---------------------------------------------------------------------------
  Widget _buildAvatar(User? user) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF2F7F3),
        ),
        child: Center(
          child: mediaUrl(user?.profilePictureUrl).isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    mediaUrl(user!.profilePictureUrl),
                    width: 102,
                    height: 102,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(user),
                  ),
                )
              : _initials(user),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.shield_outlined;
      case UserRole.manager:
        return Icons.badge_outlined;
      case UserRole.seniorTechnician:
        return Icons.engineering_outlined;
      case UserRole.technician:
      case UserRole.coldRoomTechnician:
        return Icons.build_outlined;
      case UserRole.clientAdmin:
        return Icons.apartment_outlined;
      case UserRole.client:
        return Icons.person_outline;
    }
  }

  // ---------------------------------------------------------------------------
  // Menu — every row navigates or opens a sheet.
  // ---------------------------------------------------------------------------
  Widget _buildMenuCard(BuildContext context, UserRole role) {
    final items = <_MenuEntry>[
      _MenuEntry(
        icon: Icons.business_outlined,
        label: 'Company Profile',
        onTap: () => _showCompanySheet(context),
      ),
      _MenuEntry(
        icon: Icons.assignment_outlined,
        label: role.isClientSide ? 'My Service History' : 'My Tasks History',
        onTap: () => context.push(Routes.taskBoard),
      ),
      if (Permissions.canViewAuditLog(role))
        _MenuEntry(
          icon: Icons.history,
          label: 'Activity History',
          onTap: () => context.push(Routes.auditLog),
        ),
      if (Permissions.canManageUsers(role))
        _MenuEntry(
          icon: Icons.groups_outlined,
          label: 'Manage Employees',
          onTap: () => context.push(Routes.usersList),
        ),
      _MenuEntry(
        icon: Icons.settings_outlined,
        label: 'Account Settings',
        onTap: () => context.push(Routes.settings),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 22 : 20),
        border: kIsWeb ? Border.all(color: const Color(0xFFE3ECE5)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kIsWeb ? 22 : 16,
        vertical: kIsWeb ? 10 : 6,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 54),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Company profile sheet — the companies linked to this account, read fresh
  // from `auth/me`.
  // ---------------------------------------------------------------------------
  void _showCompanySheet(BuildContext context) {
    if (kIsWeb) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
          ),
          child: const _CompanyProfileSheet(showCloseButton: true),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CompanyProfileSheet(),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.editProfile),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1A801A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dctx, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await ref.read(authControllerProvider).logout();
          if (context.mounted) {
            context.go(kIsWeb ? Routes.home : Routes.login);
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(27),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFE52020), size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE52020),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(User? user) {
    return Text(
      _getInitials(user?.name ?? 'User'),
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}

class _CompanyProfileSheet extends ConsumerWidget {
  const _CompanyProfileSheet({this.showCloseButton = false});

  final bool showCloseButton;

  static const Color _ink = Color(0xFF1C2B20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCompaniesProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!showCloseButton)
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
            SizedBox(height: showCloseButton ? 8 : 16),
            if (showCloseButton)
              Row(
                children: [
                  Expanded(child: _sheetTitle('Company Profile')),
                  IconButton(
                    key: const ValueKey('company-profile-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              )
            else
              _sheetTitle('Company Profile'),
            const SizedBox(height: 14),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => _message(
                  Icons.cloud_off_outlined,
                  "Couldn't load company details",
                  '$e',
                  onRetry: () => ref.invalidate(myCompaniesProvider),
                ),
                data: (companies) => companies.isEmpty
                    ? _message(
                        Icons.business_outlined,
                        'No company linked',
                        'Your account is not linked to a company record yet.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: companies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _companyCard(companies[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyCard(Company c) {
    String orDash(String? v) =>
        (v == null || v.trim().isEmpty) ? '—' : v.trim();
    final rows = <(IconData, String, String)>[
      (Icons.account_tree_outlined, 'Branch', orDash(c.branchName)),
      (Icons.place_outlined, 'Location', orDash(c.location)),
      (Icons.receipt_long_outlined, 'GST Number', orDash(c.gstNumber)),
      (Icons.email_outlined, 'Email', orDash(c.email)),
      (Icons.handshake_outlined, 'Service', orDash(c.serviceLabel)),
      if (c.serviceType == CompanyServiceType.amc)
        (
          Icons.event_outlined,
          'AMC Period',
          '${_date(c.startDate)} – ${_date(c.endDate)}',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  orDash(c.name),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              _statusChip(c.isActive),
            ],
          ),
          const SizedBox(height: 10),
          for (final (icon, label, value) in rows)
            _detailRow(icon, label, value),
        ],
      ),
    );
  }

  Widget _statusChip(bool active) {
    final color = active ? AppColors.primary : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF808080)),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Color(0xFF808080),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _date(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')} ${_months[l.month - 1]} ${l.year}';
  }
}

class _WebMenuTile extends StatefulWidget {
  const _WebMenuTile({required this.entry, required this.color});

  final _MenuEntry entry;
  final Color color;

  @override
  State<_WebMenuTile> createState() => _WebMenuTileState();
}

class _WebMenuTileState extends State<_WebMenuTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.entry.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover
                  ? color.withValues(alpha: 0.45)
                  : const Color(0xFFE3ECE5),
            ),
            boxShadow: [
              BoxShadow(
                color: (_hover ? color : Colors.black)
                    .withValues(alpha: _hover ? 0.14 : 0.05),
                blurRadius: _hover ? 28 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withValues(alpha: 0.18),
                                color.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                          child:
                              Icon(widget.entry.icon, size: 26, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.entry.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C2B20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _hover ? color : color.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: _hover ? Colors.white : color,
                          ),
                        ),
                      ],
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
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
