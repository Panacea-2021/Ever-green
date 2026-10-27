import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart' as repo;
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/user_provider.dart';
import '../../data/users_repository.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key, this.initialTab = 0});

  /// Tab opened first: 0 Clients, 1 POCs, 2 Service Engineers, 3 Managers.
  final int initialTab;

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late int _selectedTab = widget.initialTab.clamp(0, _tabs.length - 1);

  /// User whose active flag / deletion is in flight.
  String? _busyId;

  static const Color _green = Color(0xFF125420);
  static const Color _addGreen = Color(0xFF106220);
  static const Color _footerBg = Color(0xFFEBF0EA);

  final List<String> _tabs = [
    'Clients',
    'POCs',
    'Service Engineers',
    'Managers',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Clients = client admins, POCs = client users, Managers = EverGreen admins.
  bool _inTab(UserRole role) {
    switch (_selectedTab) {
      case 1:
        return role == UserRole.client;
      case 2:
        return role.isTechnicianLevel;
      case 3:
        return role == UserRole.superAdmin || role == UserRole.manager;
      default:
        return role == UserRole.clientAdmin;
    }
  }

  List<AppUser> _filterUsers(List<User> all) {
    final q = _searchQuery.toLowerCase();
    return all.map(AppUser.fromUser).where((u) {
      if (!_inTab(u.role)) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.mobile.toLowerCase().contains(q) ||
          u.companyNames.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final users = _filterUsers(usersAsync.valueOrNull ?? const []);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Faint background
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.78),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 4),
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                  _buildTabs(),
                  const SizedBox(height: 14),
                  _buildResultHeader(users.length),
                  const SizedBox(height: 6),
                  Expanded(
                    child: usersAsync.isLoading && !usersAsync.hasValue
                        ? const Center(
                            child: CircularProgressIndicator(color: _addGreen),
                          )
                        : usersAsync.hasError && !usersAsync.hasValue
                            ? _buildEmptyState(
                                message: usersAsync.error.toString(),
                                onRetry: () =>
                                    ref.invalidate(usersListProvider),
                              )
                            : RefreshIndicator(
                                color: _addGreen,
                                onRefresh: () =>
                                    ref.refresh(usersListProvider.future),
                                child: users.isEmpty
                                    ? LayoutBuilder(
                                        builder: (context, constraints) =>
                                            SingleChildScrollView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: SizedBox(
                                            height: constraints.maxHeight,
                                            child: _buildEmptyState(),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          17,
                                          4,
                                          17,
                                          24,
                                        ),
                                        itemCount: users.length,
                                        itemBuilder: (context, index) =>
                                            _buildUserCard(users[index]),
                                      ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          const Text(
            'Users',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(Routes.addUser),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _addGreen, width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _addGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: _addGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result header (count of users in the selected tab)
  // ---------------------------------------------------------------------------
  Widget _buildResultHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Text(
            _tabs[_selectedTab],
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF11682E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF11682E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        child: TextField(
          controller: _searchController,
          cursorColor: _addGreen,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search Users',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 24,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: _addGreen, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tabs
  // ---------------------------------------------------------------------------
  Widget _buildTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF11682E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF11682E)
                      : const Color(0xFF11682E).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF11682E).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.6),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({String? message, VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message ?? 'No users found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: _addGreen),
              label: const Text('Retry', style: TextStyle(color: _addGreen)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User card (AMCs style)
  // ---------------------------------------------------------------------------
  Widget _buildUserCard(AppUser user) {
    return Container(
      height: 221,
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0D9EE),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Avatar image - left
          Positioned(
            left: 15,
            top: 19,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildAvatar(user),
            ),
          ),

          // Name
          Positioned(
            left: 138,
            right: 44,
            top: 16,
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.51,
              ),
            ),
          ),

          // More options
          Positioned(
            right: 23,
            top: 20,
            child: _busyId == user.id
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _addGreen,
                    ),
                  )
                : _buildMoreMenu(user),
          ),

          // Status badge
          Positioned(
            left: 138,
            top: 44,
            child: Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: user.isActive ? _footerBg : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: user.isActive ? _green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.isActive ? _green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Email row
          Positioned(
            left: 137,
            right: 12,
            top: 79,
            child: _infoRow(
              Icons.email,
              'Email',
              user.email.isEmpty ? '-' : user.email,
            ),
          ),
          // Mobile row
          Positioned(
            left: 137,
            right: 12,
            top: 108,
            child: _infoRow(Icons.phone, 'Mobile', user.mobile),
          ),
          // Company row
          Positioned(
            left: 137,
            right: 12,
            top: 137,
            child: _infoRow(
              Icons.business,
              'Company',
              user.companyNames.isEmpty ? '-' : user.companyNames,
            ),
          ),

          // Footer - Created On
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 52,
              decoration: const BoxDecoration(
                color: _footerBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.42,
                        ),
                        children: [
                          TextSpan(
                            text: 'Created On ',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                          TextSpan(
                            text: ':  ${_formatDate(user.createdAt)}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 14),
        const SizedBox(width: 7),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: ': $value',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AppUser user) {
    Widget fallback() => Image.asset(
          'assets/images/user_avatar.png',
          width: 108,
          height: 135,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 108,
              height: 135,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 48),
            );
          },
        );
    final url = repo.mediaUrl(user.avatarUrl);
    if (url.isEmpty) return fallback();
    return Image.network(
      url,
      width: 108,
      height: 135,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  /// setUserActive rules: admins may toggle anyone (super admins only by a
  /// super admin), client admins only client-side users; never yourself.
  bool _canToggleActive(UserRole viewer, AppUser target, String? meId) {
    if (target.id == meId) return false;
    switch (viewer) {
      case UserRole.superAdmin:
        return true;
      case UserRole.manager:
        return target.role != UserRole.superAdmin;
      case UserRole.clientAdmin:
        return target.role.isClientSide;
      default:
        return false;
    }
  }

  Widget _buildMoreMenu(AppUser user) {
    final viewer = ref.watch(currentUserRoleProvider);
    final meId = ref.watch(currentUserProvider)?.id;
    final canToggle = _canToggleActive(viewer, user, meId);
    final canDelete = canDeleteUsers(viewer) && user.id != meId;

    return PopupMenuButton<String>(
      enabled: canToggle || canDelete,
      padding: EdgeInsets.zero,
      tooltip: 'More options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'toggle') _toggleActive(user);
        if (value == 'delete') _confirmDelete(user);
      },
      itemBuilder: (_) => [
        if (canToggle)
          PopupMenuItem(
            value: 'toggle',
            child: Text(
              user.isActive ? 'Mark Inactive' : 'Mark Active',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        if (canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete user',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.error,
              ),
            ),
          ),
      ],
      child: const Icon(Icons.more_vert, color: Colors.black54, size: 16),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}-${two(d.month)}-${d.year}';
  }

  Future<void> _toggleActive(AppUser user) async {
    setState(() => _busyId = user.id);
    final result = await ref
        .read(usersRepositoryProvider)
        .setUserActive(user.backendId, isActive: !user.isActive);
    if (!mounted) return;
    setState(() => _busyId = null);
    result.fold(
      (failure) => _snack(failure.displayMessage, error: true),
      (message) {
        _snack(message);
        ref.invalidate(usersListProvider);
        ref.invalidate(repo.techniciansProvider);
      },
    );
  }

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete user',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete ${user.name} (${user.mobile})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = user.id);
    final result =
        await ref.read(usersRepositoryProvider).deleteUser(user.backendId);
    if (!mounted) return;
    setState(() => _busyId = null);

    result.fold(
      (failure) => _snack(failure.displayMessage, error: true),
      (message) {
        _snack(message);
        ref.invalidate(usersListProvider);
        ref.invalidate(repo.techniciansProvider);
      },
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : _addGreen,
      ),
    );
  }
}
