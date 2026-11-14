import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/evergreen_repository.dart';
import '../../core/router/routes.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/data/notifications_provider.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import 'web_header_actions.dart';
import 'web_side_nav.dart' show WebNavEntry, WebSideNav;

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
    Routes.myTasks,
    Routes.myServiceTasks,
    Routes.amcs,
    Routes.amcRenewals,
    Routes.pmSchedule,
    Routes.taskBoard,
    Routes.ticketQueue,
    Routes.reports,
    Routes.announcements,
    Routes.enquiries,
  };

  /// Module pages shown in a card with their own icon-and-title header
  /// (matched by prefix, so `/add-task/new` counts).
  static const _bannerPaths = [
    Routes.addTask,
    Routes.createIndividualTask,
    Routes.addEquipment,
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
    Routes.myTasks: 'My Tasks',
    Routes.myServiceTasks: 'My Service Tasks',
    Routes.editProfile: 'Edit Profile',
    Routes.addUser: 'Add User',
    Routes.technicianTasks: 'Service Engineer Tasks',
    Routes.techniciansList: 'Service Engineers',
    Routes.assignTasks: 'Assign Tasks',
    Routes.verifiedEquipments: 'Verified Equipments',
    Routes.analytics: 'Analytics',
    Routes.scanner: 'Scan QR',
    Routes.reports: 'Reports & Export Center',
    Routes.enquiries: 'Enquiries',
  };

  @override
  ConsumerState<WebModuleFrame> createState() => _WebModuleFrameState();
}

class _WebModuleFrameState extends ConsumerState<WebModuleFrame> {
  final _contentKey = GlobalKey();
  final List<String> _locationHistory = [];
  String _location = '';
  bool _skipNextHistoryUpdate = false;

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
      if (_skipNextHistoryUpdate) {
        _skipNextHistoryUpdate = false;
      } else if (_isModuleLocation(_location) &&
          _isModuleLocation(location)) {
        _locationHistory.add(_location);
      } else if (!_isModuleLocation(location)) {
        _locationHistory.clear();
      }
      // Clear header actions when navigating to a new page
      // The new page will set its own actions if needed
      ref.read(webHeaderActionsProvider).clearActions();
      setState(() => _location = location);
      _refreshIfStale();
    }
  }

  bool _isModuleLocation(String location) =>
      location.isNotEmpty && !WebModuleFrame._unframedPaths.contains(location);

  void _goBack() {
    final previous = _locationHistory.isNotEmpty
        ? _locationHistory.removeLast()
        : Routes.webDashboard;
    if (previous == _location) return;
    _skipNextHistoryUpdate = true;
    widget.router.go(previous);
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

    final role = ref.watch(currentUserRoleProvider);
    final webDesigned = WebModuleFrame._webDesignedPaths.contains(_location) ||
        _location.startsWith('${Routes.companyDetails}/');
    final bannered = WebModuleFrame._bannerPaths
        .any((p) => _location == p || _location.startsWith('$p/'));
    final title = _titleFor(role);

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Material(
      color: WebTokens.cream,
      child: Row(
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
                  router: widget.router,
                  onBack: _goBack,
                  showUserInfo: _location == Routes.webDashboard,
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
                          entry: _entryFor(role),
                          title: title,
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
    this.entry,
    this.title,
    required this.child,
  });

  final double width;
  final MediaQueryData mq;
  final BoxConstraints constraints;
  final bool compact;
  final WebNavEntry? entry;
  final String? title;
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

/// Slim white title bar shown below the side nav on non-full-bleed pages.
/// Shows page title, and on the Dashboard, also shows notification bell and
/// user avatar. Also displays page-specific action buttons from the
/// webHeaderActionsProvider.
class _WebTopBar extends ConsumerWidget {
  const _WebTopBar({
    required this.title,
    required this.router,
    required this.onBack,
    this.showUserInfo = true,
  });

  final String title;
  final GoRouter router;
  final VoidCallback onBack;
  final bool showUserInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? '';
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final headerActions = ref.watch(webHeaderActionsProvider).actions;

    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          if (title.isNotEmpty) ...[
            IconButton(
              key: const ValueKey('web-module-back-button'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WebTokens.heading(20),
              ),
            ),
          ],
          const Spacer(),
          // Page-specific action buttons (Reset, Save, etc.)
          if (headerActions.isNotEmpty) ...[
            WebHeaderActionButtons(actions: headerActions),
            if (showUserInfo) const SizedBox(width: 24),
          ],
          if (showUserInfo) ...[
            _NotificationBell(
              count: unreadCount,
              onPressed: () => router.push(Routes.notifications),
            ),
            SizedBox(width: compact ? 8 : 18),
            _UserAvatar(
              name: userName,
              onPressed: () => router.go(Routes.profile),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // No `tooltip:` here on purpose: WebModuleFrame is rendered by
    // MaterialApp.builder (see app.dart), i.e. *above* the Navigator, so a
    // Tooltip would look up an Overlay ancestor and fail with
    // "No Overlay widget found" on the web dashboard.
    return IconButton(
      key: const ValueKey('web-notifications-button'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: WebTokens.green,
        child: const Icon(Icons.notifications_outlined, size: 24),
      ),
      onPressed: onPressed,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.onPressed,
  });

  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Semantics(
      button: true,
      label: 'Open profile',
      child: InkWell(
        key: const ValueKey('web-profile-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF106220), Color(0xFF0A3F15)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
