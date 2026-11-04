import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../../features/announcements/data/announcement_provider.dart';
import '../theme/web_tokens.dart';
import 'web_side_nav.dart';
import 'web_search_state.dart';

/// Web-only desktop frame for the signed-in dashboard modules: a fixed side
/// navigation (replacing the phone drawer and bottom bar), a top bar, and the
/// module page in the content area. Public website pages are shown unframed.
class WebModuleFrame extends ConsumerStatefulWidget {
  const WebModuleFrame({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  static const maxContentWidth = 1280.0;

  /// Width for form and settings pages, so fields are not stretched across
  /// a desktop screen.
  static const formContentWidth = 820.0;

  /// Width for list and detail pages built from mobile cards.
  static const listContentWidth = 1100.0;
  static const uploadContentWidth = 780.0;

  static const _uploadPaths = {
    Routes.uploadEquipments,
    Routes.uploadTechnicians,
    Routes.uploadAmc,
  };

  /// Form and settings pages (matched by prefix, so `/add-task/new` counts).
  static const _formPaths = [
    Routes.addUser,
    Routes.editProfile,
    Routes.downloadQr,
  ];

  /// Shared lists are refreshed in the background at most this often.
  static const _refreshAfter = Duration(seconds: 60);

  /// Paths that are part of the public website or the sign-in flow.
  static const _unframedPaths = {
    Routes.splash,
    Routes.getStarted,
    Routes.login,
    Routes.register,
    Routes.forgotPassword,
    Routes.home,
    Routes.terms,
    Routes.privacy,
    Routes.contact,
    Routes.services,
    Routes.industries,
    Routes.technicians,
    Routes.about,
    Routes.howItWorks,
    Routes.unauthorized,
  };

  /// Modules that have a dedicated web layout; they draw straight onto the
  /// page background instead of inside a framed panel.
  static const _webDesignedPaths = {
    Routes.webDashboard,
    Routes.tasks,
    Routes.amcs,
    Routes.amcRenewals,
    Routes.pmSchedule,
    Routes.taskBoard,
    Routes.announcements,
  };

  /// Module pages shown in a card with their own icon-and-title header
  /// (matched by prefix, so `/add-task/new` counts).
  static const _bannerPaths = [
    Routes.addTask,
    Routes.createIndividualTask,
    Routes.addEquipment,
    Routes.ticketQueue,
    Routes.createAmc,
    Routes.uploadEquipments,
    Routes.uploadTechnicians,
    Routes.uploadAmc,
    Routes.downloadQr,
    Routes.technicianPerformance,
    Routes.auditLog,
    Routes.profile,
    Routes.changePassword,
    Routes.settings,
  ];

  /// Titles for pages that are not sidebar destinations.
  static const _detailTitles = {
    Routes.taskDetails: 'Task Details',
    Routes.companyDetails: 'Company Details',
    Routes.companyTasks: 'Company Tasks',
    Routes.companyEquipments: 'Company Equipments',
    Routes.equipmentDetails: 'Equipment Details',
    Routes.equipmentQr: 'Equipment QR',
    Routes.addEquipment: 'Add Equipment',
    Routes.addTask: 'Create Task',
    Routes.notifications: 'Notifications',
    Routes.announcements: 'Announcements',
    Routes.editProfile: 'Edit Profile',
    Routes.addUser: 'Add User',
    Routes.technicianTasks: 'Service Engineer Tasks',
    Routes.techniciansList: 'Service Engineers',
    Routes.assignTasks: 'Assign Tasks',
    Routes.verifiedEquipments: 'Verified Equipments',
    Routes.analytics: 'Analytics',
    Routes.scanner: 'Scan QR',
  };

  @override
  ConsumerState<WebModuleFrame> createState() => _WebModuleFrameState();
}

class _WebModuleFrameState extends ConsumerState<WebModuleFrame> {
  final _contentKey = GlobalKey();
  String _location = '';

  @override
  void initState() {
    super.initState();
    _location = _currentLocation();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(WebModuleFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.router, widget.router)) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
      _location = _currentLocation();
      ref.read(webModuleSearchQueryProvider.notifier).state = '';
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  String _currentLocation() {
    final config = widget.router.routerDelegate.currentConfiguration;
    if (config.isEmpty) return config.uri.path;
    return config.last.matchedLocation;
  }

  /// Route notifications can arrive mid-build (including the initial attach,
  /// when the scheduler still reports idle), so the update always waits for
  /// the end of the frame.
  void _onRouteChanged() {
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _syncLocation())
      ..ensureVisualUpdate();
  }

  void _syncLocation() {
    if (!mounted) return;
    final location = _currentLocation();
    if (location != _location) {
      setState(() => _location = location);
      ref.read(webModuleSearchQueryProvider.notifier).state = '';
      _refreshIfStale();
    }
  }

  DateTime _lastRefresh = DateTime.now();

  /// Re-fetches the cached lists after [WebModuleFrame._refreshAfter]. The
  /// previous data stays on screen while the new request runs.
  void _refreshIfStale() {
    if (!ref.read(isAuthenticatedProvider)) return;
    if (_location != Routes.webDashboard) return;
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < WebModuleFrame._refreshAfter) return;
    _lastRefresh = now;
    ref.invalidate(tasksProvider);
    ref.invalidate(companiesProvider);
    ref.invalidate(equipmentsProvider(null));
  }

  double _contentWidthFor(String location) {
    if (WebModuleFrame._uploadPaths
        .any((p) => location == p || location.startsWith('$p/'))) {
      return WebModuleFrame.uploadContentWidth;
    }
    for (final p in WebModuleFrame._formPaths) {
      if (location == p || location.startsWith('$p/')) {
        return WebModuleFrame.formContentWidth;
      }
    }
    return WebModuleFrame.listContentWidth;
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider).logout();
    widget.router.go(Routes.home);
  }

  void _navigate(String route) {
    if (route != _location) widget.router.go(route);
  }

  WebNavEntry? _entryFor(UserRole role) {
    for (final entry in WebSideNav.entriesFor(role)) {
      if (entry.route == _location) return entry;
    }
    return null;
  }

  String _titleFor(UserRole role) {
    for (final entry in WebSideNav.entriesFor(role)) {
      if (entry.route == _location) return entry.label;
    }
    for (final e in WebModuleFrame._detailTitles.entries) {
      if (_location == e.key || _location.startsWith('${e.key}/')) {
        return e.value;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final restoring = ref.watch(
      authStateProvider.select((s) => s.status == AuthStatus.unknown),
    );
    final protectedPage = _location.isNotEmpty &&
        !WebModuleFrame._unframedPaths.contains(_location);
    final framed = isAuthenticated && protectedPage;

    if (restoring && protectedPage) return const _WebRestoringSession();

    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    if (!framed) return content;

    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final webDesigned = WebModuleFrame._webDesignedPaths.contains(_location) ||
        _location.startsWith('${Routes.companyDetails}/');
    final bannered = WebModuleFrame._bannerPaths
        .any((p) => _location == p || _location.startsWith('$p/'));
    final title = _titleFor(role);

    return Material(
      color: WebTokens.cream,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebSideNav(
            activeRoute: _location,
            onNavigate: _navigate,
            onSignOut: _signOut,
          ),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(
                  title: title,
                  entry: bannered ? _entryFor(role) : null,
                  userName: user?.name ?? role.label,
                  roleLabel: role.label,
                  onNotifications: () => _navigate(Routes.announcements),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mq = MediaQuery.of(context);
                      if (webDesigned) {
                        return MediaQuery(
                          data: mq.copyWith(
                            size: constraints.biggest,
                            padding: EdgeInsets.zero,
                            viewPadding: EdgeInsets.zero,
                          ),
                          child: content,
                        );
                      }

                      final hPad = constraints.maxWidth > 900 ? 28.0 : 16.0;
                      final width = (constraints.maxWidth - hPad * 2)
                          .clamp(0.0, _contentWidthFor(_location));

                      if (bannered) {
                        return _HeaderCardShell(
                          width: width,
                          mq: mq,
                          constraints: constraints,
                          compact: WebModuleFrame._uploadPaths.any(
                            (p) =>
                                _location == p || _location.startsWith('$p/'),
                          ),
                          child: content,
                        );
                      }
                      final height = constraints.maxHeight - 48;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: width,
                          height: height,
                          margin: const EdgeInsets.only(top: 24),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: WebTokens.line),
                            boxShadow: WebTokens.softShadow,
                          ),
                          child: MediaQuery(
                            data: mq.copyWith(
                              size: Size(width, height),
                              padding: EdgeInsets.zero,
                              viewPadding: EdgeInsets.zero,
                            ),
                            child: content,
                          ),
                        ),
                      );
                    },
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

/// The page in a white card whose header shows the module icon and title on
/// a soft mint wash.
class _HeaderCardShell extends StatelessWidget {
  const _HeaderCardShell({
    required this.width,
    required this.mq,
    required this.constraints,
    this.compact = false,
    required this.child,
  });

  final double width;
  final MediaQueryData mq;
  final BoxConstraints constraints;
  final bool compact;
  final Widget child;

  static const _accentHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        color: const Color(0xFFF3F7F3),
        alignment: Alignment.center,
        child: SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(width, constraints.maxHeight),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      );
    }

    final height = (constraints.maxHeight - 40).clamp(0.0, double.infinity);

    return Stack(
      children: [
        // Soft background shapes behind the card.
        Positioned(right: -120, top: -140, child: _blob(420, 0.10)),
        Positioned(left: -160, bottom: -180, child: _blob(460, 0.07)),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(top: 20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: WebTokens.line),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A3F15).withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: _accentHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A3F15),
                        Color(0xFF106220),
                        Color(0xFF5FB36F),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, body) => MediaQuery(
                      data: mq.copyWith(
                        size: body.biggest,
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, double alpha) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF5FB36F).withValues(alpha: alpha),
                const Color(0xFF5FB36F).withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
}

/// Shown on a signed-in page while a page reload restores the session.
class _WebRestoringSession extends StatelessWidget {
  const _WebRestoringSession();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WebTokens.cream,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: WebTokens.green.withValues(alpha: 0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    size: 40,
                    color: WebTokens.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'EverGreen',
              style: WebTokens.heading(22).copyWith(color: WebTokens.green),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: WebTokens.green,
                  backgroundColor: Color(0x1F106220),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebTopBar extends ConsumerStatefulWidget {
  const _WebTopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
    required this.onNotifications,
    this.entry,
  });

  final String title;
  final WebNavEntry? entry;
  final String userName;
  final String roleLabel;
  final VoidCallback onNotifications;

  @override
  ConsumerState<_WebTopBar> createState() => _WebTopBarState();
}

class _WebTopBarState extends ConsumerState<_WebTopBar> {
  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(webModuleSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 900;
    final searchQuery = ref.watch(webModuleSearchQueryProvider);
    ref.listen<String>(webModuleSearchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });
    void submitSearch() {
      ref.read(webModuleSearchQueryProvider.notifier).state =
          _searchController.text.trim();
      _searchFocusNode.unfocus();
    }

    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final unreadCount = ref.watch(announcementControllerProvider).maybeWhen(
          data: (data) => data.unreadCountFor(userId),
          orElse: () => 0,
        );

    return Container(
      height: compact ? 64 : 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          if (widget.entry != null && !compact) ...[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF106220), Color(0xFF0A3F15)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.entry!.svgIcon != null
                  ? SvgPicture.asset(
                      widget.entry!.svgIcon!,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(widget.entry!.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
          ],
          if (compact)
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WebTokens.heading(18),
              ),
            )
          else
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WebTokens.heading(21),
            ),
          SizedBox(width: compact ? 8 : 24),
          if (compact)
            Expanded(
              flex: 3,
              child: _topBarSearchField(searchQuery, submitSearch),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desiredWidth = screenWidth >= 1400
                      ? 520.0
                      : screenWidth >= 1200
                          ? 460.0
                          : 360.0;
                  final searchWidth = constraints.maxWidth < desiredWidth
                      ? constraints.maxWidth
                      : desiredWidth;
                  return Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: searchWidth,
                      child: _topBarSearchField(searchQuery, submitSearch),
                    ),
                  );
                },
              ),
            ),
          SizedBox(width: compact ? 8 : 14),
          _Hoverable(
            onTap: widget.onNotifications,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTokens.cream,
                shape: BoxShape.circle,
                border: Border.all(color: WebTokens.line),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none,
                      size: 20,
                      color: WebTokens.ink,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -9,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 18),
            CircleAvatar(
              radius: 19,
              backgroundColor: WebTokens.mintSoft,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: WebTokens.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: WebTokens.green,
                ),
              ),
            ),
            if (screenWidth >= 1200) ...[
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTokens.bodyText(
                        13.5,
                        color: WebTokens.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(widget.roleLabel, style: WebTokens.bodyText(11.5)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _topBarSearchField(String searchQuery, VoidCallback submitSearch) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: WebTokens.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 19,
            color: WebTokens.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) =>
                  ref.read(webModuleSearchQueryProvider.notifier).state = value,
              onSubmitted: (_) => submitSearch(),
              textInputAction: TextInputAction.search,
              cursorColor: WebTokens.green,
              decoration: InputDecoration(
                hintText: 'Search this page',
                hintStyle: WebTokens.bodyText(13),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: WebTokens.bodyText(13, color: WebTokens.ink),
            ),
          ),
          if (searchQuery.isNotEmpty)
            Semantics(
              label: 'Clear search',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _searchController.clear();
                  ref.read(webModuleSearchQueryProvider.notifier).state = '';
                },
                child: const SizedBox(
                  width: 30,
                  height: 34,
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: WebTokens.faint,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Apply search',
            button: true,
            child: Material(
              color: WebTokens.green,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: submitSearch,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hoverable extends StatelessWidget {
  const _Hoverable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
