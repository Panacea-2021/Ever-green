import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart' as repo;
import '../../../../core/models/backend_models.dart' as backend;
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/count_badge.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../data/user_provider.dart';
import '../../data/users_repository.dart';
import '../../../../web/widgets/web_filter_tiles.dart';

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
    'Company Managers',
    'POCs',
    'Service Engineers',
    'Managers',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Company Managers = client admins, POCs = client users, Managers =
  /// EverGreen admins.
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

    if (kIsWeb) return _webBuild(usersAsync, users);
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
  // Web layout
  // ---------------------------------------------------------------------------
  static const Color _webLine = Color(0xFFE2E8E3);
  static const Color _webInk = Color(0xFF14201A);
  static const _webTabMeta = [
    (Icons.business_center_outlined, Color(0xFF106220)),
    (Icons.contact_phone_outlined, Color(0xFF1565C0)),
    (Icons.engineering_outlined, Color(0xFFE08600)),
    (Icons.manage_accounts_outlined, Color(0xFF6A4BC4)),
  ];

  bool _webInTab(UserRole role, int tab) {
    switch (tab) {
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

  int _webTabCount(List<User> all, int tab) {
    final q = _searchQuery.toLowerCase();
    return all.map(AppUser.fromUser).where((u) {
      if (!_webInTab(u.role, tab)) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.mobile.toLowerCase().contains(q) ||
          u.companyNames.toLowerCase().contains(q);
    }).length;
  }

  Widget _webBuild(AsyncValue<List<User>> usersAsync, List<AppUser> users) {
    final all = usersAsync.valueOrNull;
    Widget body;
    if (usersAsync.isLoading && !usersAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator(color: _addGreen));
    } else if (usersAsync.hasError && !usersAsync.hasValue) {
      body = _buildEmptyState(
        message: usersAsync.error.toString(),
        onRetry: () => ref.invalidate(usersListProvider),
      );
    } else {
      body = RefreshIndicator(
        color: _addGreen,
        onRefresh: () => ref.refresh(usersListProvider.future),
        child: LayoutBuilder(
          builder: (context, c) {
            if (users.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: c.maxHeight,
                  child: _buildEmptyState(),
                ),
              );
            }
            const gap = 18.0;
            final inner = c.maxWidth - 48;
            final cols = inner >= 1250
                ? 3
                : inner >= 720
                    ? 2
                    : 1;
            final w = (inner - gap * (cols - 1)) / cols;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final u in users)
                      SizedBox(width: w, child: _webUserCard(u)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F4),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: _webToolbar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: WebFilterTiles(
                options: [
                  for (var i = 0; i < _tabs.length; i++)
                    WebFilterOption(
                      label: _tabs[i],
                      icon: _webTabMeta[i].$1,
                      color: _webTabMeta[i].$2,
                      selected: _selectedTab == i,
                      count: all == null ? null : _webTabCount(all, i),
                      onTap: () => setState(() => _selectedTab = i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildResultHeader(users.length),
            ),
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _webToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _webLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: _addGreen,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: _webInk,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF7FAF8),
                hintText: 'Search Users',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: _addGreen,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: Colors.black45,
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _webLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _addGreen, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.addUser),
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _addGreen,
              elevation: 0,
              minimumSize: const Size(120, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webUserCard(AppUser user) {
    return _WebUserHover(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _webLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 86,
                      height: 104,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: _buildAvatar(user),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _webInk,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 28,
                              child: Center(
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? _footerBg
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: user.isActive ? _green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _webInfoRow(
                          Icons.email_outlined,
                          'Email',
                          user.email.isEmpty ? '-' : user.email,
                        ),
                        const SizedBox(height: 7),
                        _webInfoRow(
                          Icons.phone_outlined,
                          'Mobile',
                          user.mobile,
                        ),
                        const SizedBox(height: 7),
                        _webInfoRow(
                          Icons.business_outlined,
                          'Company',
                          user.companyNames.isEmpty ? '-' : user.companyNames,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F9F5),
                border: Border(top: BorderSide(color: _webLine)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: _addGreen,
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'Created On ',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        TextSpan(
                          text: ':  ${_formatDate(user.createdAt)}',
                          style: const TextStyle(color: _webInk),
                        ),
                      ],
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

  Widget _webInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _addGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: _addGreen),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
                ),
                TextSpan(
                  text: ': $value',
                  style: const TextStyle(color: _webInk),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return CountHeader(label: _tabs[_selectedTab], count: count);
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

  bool _canEditUser(UserRole viewer, AppUser target) {
    if (viewer == UserRole.superAdmin) return true;
    if (viewer != UserRole.manager) return false;
    return target.role.isTechnicianLevel ||
        target.role == UserRole.clientAdmin ||
        target.role == UserRole.client;
  }

  Widget _buildMoreMenu(AppUser user) {
    final viewer = ref.watch(currentUserRoleProvider);
    final meId = ref.watch(currentUserProvider)?.id;
    final canEdit = _canEditUser(viewer, user);
    final canToggle = _canToggleActive(viewer, user, meId);
    final canDelete = canDeleteUsers(viewer) && user.id != meId;

    return PopupMenuButton<String>(
      enabled: canEdit || canToggle || canDelete,
      padding: EdgeInsets.zero,
      tooltip: 'More options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'toggle') _toggleActive(user);
        if (value == 'delete') _confirmDelete(user);
        if (value == 'edit') _editUser(user);
      },
      itemBuilder: (_) => [
        if (canEdit)
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit user', style: TextStyle(fontFamily: 'Montserrat')),
          ),
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

  Future<void> _editUser(AppUser user) async {
    final phone = TextEditingController(text: user.mobile);
    final email = TextEditingController(text: user.email);
    final roleChoices = ref.read(currentUserRoleProvider) == UserRole.superAdmin
        ? UserRole.values
        : const [
            UserRole.technician,
            UserRole.seniorTechnician,
            UserRole.coldRoomTechnician,
            UserRole.clientAdmin,
            UserRole.client,
          ];
    var selectedRole = user.role;
    final selectedCompanies = user.companies.map((c) => c.id).toSet();
    List<backend.Company> companies;
    try {
      companies = await ref.read(repo.companiesProvider.future);
    } catch (e) {
      if (mounted) _snack('Could not load companies: $e', error: true);
      phone.dispose();
      email.dispose();
      return;
    }
    if (!mounted) {
      phone.dispose();
      email.dispose();
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile number'),
                  ),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Access type'),
                    items: [
                      for (final role in roleChoices)
                        DropdownMenuItem(value: role, child: Text(role.label)),
                    ],
                    onChanged: (role) {
                      if (role != null) setDialogState(() => selectedRole = role);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Assign to company / AMC'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 190,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final company in companies)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(company.displayName),
                            value: selectedCompanies.contains(company.id),
                            onChanged: (selected) => setDialogState(() {
                              if (selected == true) {
                                selectedCompanies.add(company.id);
                              } else {
                                selectedCompanies.remove(company.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final updatedPhone = phone.text.trim();
    final updatedEmail = email.text.trim();
    phone.dispose();
    email.dispose();
    if (saved != true || !mounted) return;
    if (updatedPhone.isEmpty) {
      _snack('Mobile number is required', error: true);
      return;
    }
    setState(() => _busyId = user.id);
    final result = await ref.read(usersRepositoryProvider).updateUser(
          user.backendId,
          phone: updatedPhone,
          email: updatedEmail,
          role: selectedRole,
          companyIds: selectedCompanies.toList(),
        );
    if (!mounted) return;
    setState(() => _busyId = null);
    result.fold(
      (failure) => _snack(failure.displayMessage, error: true),
      (message) async {
        _snack(message);
        final signedIn = ref.read(currentUserProvider);
        if (signedIn?.id == user.id) {
          ref.read(authStateProvider.notifier).updateUser(
                signedIn!.copyWith(
                  phone: updatedPhone,
                  email: updatedEmail,
                  role: selectedRole,
                  designation: selectedRole.designation,
                  companies: [
                    for (final company in companies)
                      if (selectedCompanies.contains(company.id))
                        UserCompany(
                          id: company.id,
                          name: company.name,
                          branchName: company.branchName,
                        ),
                  ],
                ),
              );
          if (signedIn!.phone != updatedPhone) {
            _snack('Mobile number updated. Sign in again with the new number.');
            await ref.read(authRepositoryProvider).logout();
            ref.read(authStateProvider.notifier).logout();
            if (mounted) context.go(Routes.login);
            return;
          }
        }
        ref.invalidate(usersListProvider);
        ref.invalidate(repo.techniciansProvider);
        ref.invalidate(repo.companiesProvider);
      },
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

/// Lifts its child slightly while hovered (web cards).
class _WebUserHover extends StatefulWidget {
  const _WebUserHover({required this.child});
  final Widget child;

  @override
  State<_WebUserHover> createState() => _WebUserHoverState();
}

class _WebUserHoverState extends State<_WebUserHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
