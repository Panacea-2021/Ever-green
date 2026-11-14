import 'dart:math' as math;

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

enum _WebHeaderPanel { notifications, profile }

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

  /// These screens already render a back control beside their own heading.
  static const _pathsWithPageBackButton = {
    Routes.addUser,
    Routes.addTask,
    Routes.addEquipment,
    Routes.createAmc,
    Routes.createIndividualTask,
    Routes.uploadEquipments,
    Routes.uploadTechnicians,
    Routes.uploadAmc,
    Routes.downloadQr,
    Routes.technicianPerformance,
    Routes.auditLog,
    Routes.usersList,
    Routes.globalSearch,
    Routes.amcRenewals,
    Routes.pmSchedule,
    Routes.analytics,
    Routes.changePassword,
    Routes.taskBoard,
    Routes.assignTasks,
    Routes.techniciansList,
    Routes.technicianTasks,
    Routes.verifiedEquipments,
    Routes.notifications,
    Routes.scanner,
    Routes.issueTypes,
    Routes.serviceTypes,
    Routes.editProfile,
    Routes.taskDetails,
    Routes.companyDetails,
    Routes.companyTasks,
    Routes.companyEquipments,
    Routes.equipmentDetails,
    Routes.equipmentQr,
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
  };

  @override
  ConsumerState<WebModuleFrame> createState() => _WebModuleFrameState();
}

class _WebModuleFrameState extends ConsumerState<WebModuleFrame> {
  final _contentKey = GlobalKey();
  String _location = '';
  String? _previousLocation;
  _WebHeaderPanel? _headerPanel;

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
      _previousLocation = null;
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
      _previousLocation =
          _isProtectedLocation(location) && _isProtectedLocation(_location)
              ? _location
              : null;
      // Clear header actions when navigating to a new page
      // The new page will set its own actions if needed
      ref.read(webHeaderActionsProvider).clearActions();
      setState(() {
        _location = location;
        _headerPanel = null;
      });
      _refreshIfStale();
    }
  }

  void _toggleHeaderPanel(_WebHeaderPanel panel) {
    setState(() {
      _headerPanel = _headerPanel == panel ? null : panel;
    });
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

  bool _isProtectedLocation(String location) =>
      location.isNotEmpty && !WebModuleFrame._unframedPaths.contains(location);

  bool _hasPageBackButton(String location) {
    if (location == Routes.settings) return widget.router.canPop();
    return WebModuleFrame._pathsWithPageBackButton
        .any((path) => location == path || location.startsWith('$path/'));
  }

  void _navigateBack() {
    final previous = _previousLocation;
    if (previous != null && previous != _location) {
      widget.router.go(previous);
    } else {
      widget.router.go(Routes.webDashboard);
    }
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
    final showTopBar = _location != Routes.taskBoard || title.isNotEmpty;
    final user = ref.watch(currentUserProvider);

    return Material(
      color: WebTokens.cream,
      child: Row(
        children: [
          // ── Left side navigation (vertical sidebar) ───────────────────────
          WebSideNav(
            activeRoute: _location,
            onNavigate: _navigate,
            onSignOut: _signOut,
          ),
          // ── Content area ──────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, frameConstraints) {
                final panelWidth =
                    math.min(420.0, frameConstraints.maxWidth - 24);
                final panelHeight =
                    math.min(560.0, frameConstraints.maxHeight - 76);

                return Stack(
                  children: [
                    Column(
                      children: [
                        if (showTopBar)
                          _WebTopBar(
                            title: title,
                            showBackButton: title.isNotEmpty &&
                                !_hasPageBackButton(_location),
                            onBack: _navigateBack,
                            showUserInfo: _location == Routes.webDashboard,
                            user: user,
                            onNotificationsPressed: () => _toggleHeaderPanel(
                              _WebHeaderPanel.notifications,
                            ),
                            onProfilePressed: () => _toggleHeaderPanel(
                              _WebHeaderPanel.profile,
                            ),
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

                              final hPad =
                                  constraints.maxWidth > 900 ? 28.0 : 16.0;
                              final width = (constraints.maxWidth - hPad * 2)
                                  .clamp(0.0, _contentWidthFor(_location));

                              if (bannered) {
                                return _HeaderCardShell(
                                  width: width,
                                  mq: mq,
                                  constraints: constraints,
                                  compact: WebModuleFrame._uploadPaths.any(
                                    (p) =>
                                        _location == p ||
                                        _location.startsWith('$p/'),
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
                    if (_location == Routes.webDashboard &&
                        _headerPanel != null &&
                        panelWidth > 0 &&
                        panelHeight > 0)
                      Positioned(
                        top: 76,
                        right: 12,
                        child: TapRegion(
                          onTapOutside: (_) =>
                              setState(() => _headerPanel = null),
                          child: SizedBox(
                            width: panelWidth,
                            height: panelHeight,
                            child: _headerPanel == _WebHeaderPanel.notifications
                                ? _WebNotificationsPanel(
                                    onDismiss: () =>
                                        setState(() => _headerPanel = null),
                                    onViewAll: () {
                                      setState(() => _headerPanel = null);
                                      widget.router.go(Routes.notifications);
                                    },
                                  )
                                : _WebProfilePanel(
                                    user: user,
                                    role: role,
                                    onDismiss: () =>
                                        setState(() => _headerPanel = null),
                                    onViewProfile: () {
                                      setState(() => _headerPanel = null);
                                      widget.router.go(Routes.profile);
                                    },
                                    onSignOut: () async {
                                      setState(() => _headerPanel = null);
                                      await _signOut();
                                    },
                                  ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    required this.onBack,
    required this.user,
    required this.onNotificationsPressed,
    required this.onProfilePressed,
    this.showUserInfo = true,
    this.showBackButton = false,
  });

  final String title;
  final VoidCallback onBack;
  final User? user;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onProfilePressed;
  final bool showUserInfo;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = user?.name ?? '';
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final headerActions = ref.watch(webHeaderActionsProvider).actions;
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 480 ? 12.0 : 28.0;

    return Container(
      key: const ValueKey('web-module-top-bar'),
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              key: const ValueKey('web-module-back-button'),
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: WebTokens.ink,
              ),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
            ),
          if (showBackButton) const SizedBox(width: 8),
          if (title.isNotEmpty)
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WebTokens.heading(20),
              ),
            ),
          if (title.isEmpty) const Spacer(),
          // Page-specific action buttons (Reset, Save, etc.)
          if (headerActions.isNotEmpty) ...[
            WebHeaderActionButtons(actions: headerActions),
            if (showUserInfo) const SizedBox(width: 24),
          ],
          if (showUserInfo) ...[
            _NotificationBell(
              count: unreadCount,
              onPressed: onNotificationsPressed,
            ),
            const SizedBox(width: 18),
            _UserAvatar(
              name: userName,
              profilePictureUrl: user?.profilePictureUrl,
              onPressed: onProfilePressed,
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // No `tooltip:` here on purpose: WebModuleFrame is rendered by
    // MaterialApp.builder (see app.dart), i.e. *above* the Navigator, so a
    // Tooltip would look up an Overlay ancestor and fail with
    // "No Overlay widget found" on the web dashboard.
    return IconButton(
      key: const ValueKey('web-notification-button'),
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
    required this.profilePictureUrl,
    required this.onPressed,
  });

  final String name;
  final String? profilePictureUrl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('web-profile-button'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        label: 'Open profile menu',
        child: _ProfileAvatar(
          name: name,
          profilePictureUrl: profilePictureUrl,
          size: 38,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.profilePictureUrl,
    required this.size,
  });

  final String name;
  final String? profilePictureUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final initials = trimmedName.isEmpty
        ? '?'
        : trimmedName
            .split(RegExp(r'\s+'))
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join();
    final imageUrl = profilePictureUrl?.trim();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF106220), Color(0xFF0A3F15)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? _initials(initials)
          : Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(initials),
            ),
    );
  }

  Widget _initials(String value) => Text(
        value,
        style: TextStyle(
          fontFamily: WebTokens.fontFamily,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
}

class _WebNotificationsPanel extends ConsumerStatefulWidget {
  const _WebNotificationsPanel({
    required this.onDismiss,
    required this.onViewAll,
  });

  final VoidCallback onDismiss;
  final VoidCallback onViewAll;

  @override
  ConsumerState<_WebNotificationsPanel> createState() =>
      _WebNotificationsPanelState();
}

class _WebNotificationsPanelState
    extends ConsumerState<_WebNotificationsPanel> {
  final Set<int> _markingIds = {};
  bool _markingAll = false;
  String? _actionError;

  Future<void> _markRead({List<int>? ids}) async {
    if (_markingAll || (ids != null && ids.any(_markingIds.contains))) return;
    setState(() {
      _actionError = null;
      if (ids == null) {
        _markingAll = true;
      } else {
        _markingIds.addAll(ids);
      }
    });

    try {
      await ref.read(notificationsRepositoryProvider).markRead(ids: ids);
      ref.invalidate(notificationsControllerProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = 'Could not update notifications. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
          if (ids != null) _markingIds.removeAll(ids);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(notificationsControllerProvider);
    final unreadCount = feed.valueOrNull?.items
            .where((entry) => !entry.notification.isRead)
            .length ??
        0;

    return Material(
      key: const ValueKey('web-notifications-panel'),
      color: Colors.white,
      elevation: 18,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: WebTokens.heading(17),
                      ),
                    ),
                    if (unreadCount > 0)
                      compact
                          ? Semantics(
                              button: true,
                              label: 'Mark all notifications as read',
                              child: IconButton(
                                key: const ValueKey(
                                  'web-notifications-mark-all',
                                ),
                                onPressed:
                                    _markingAll ? null : () => _markRead(),
                                icon: const Icon(Icons.done_all, size: 20),
                              ),
                            )
                          : TextButton(
                              onPressed: _markingAll ? null : () => _markRead(),
                              child: Text(
                                _markingAll ? 'Saving...' : 'Mark all read',
                              ),
                            ),
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: WebTokens.line),
          if (_actionError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _actionError!,
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Expanded(
            child: feed.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: WebTokens.green),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: Color(0xFF8A938B),
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    const Text("Couldn't load notifications"),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(notificationsControllerProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) => data.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF8A938B),
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Color(0xFF505A52),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: data.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = data.items[index];
                        return _NotificationPanelItem(
                          entry: entry,
                          isMarking:
                              _markingIds.contains(entry.notification.id),
                          onMarkRead: () => _markRead(
                            ids: [entry.notification.id],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1, color: WebTokens.line),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: widget.onViewAll,
              child: const Text('View all notifications'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPanelItem extends StatelessWidget {
  const _NotificationPanelItem({
    required this.entry,
    required this.isMarking,
    required this.onMarkRead,
  });

  final NotificationEntry entry;
  final bool isMarking;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final notification = entry.notification;
    final createdAt = notification.createdAt?.toLocal();
    final timestamp = createdAt == null
        ? null
        : '${MaterialLocalizations.of(context).formatMediumDate(createdAt)} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFFFAFBFA)
            : const Color(0xFFF0F7F1),
        border: Border.all(
          color: notification.isRead
              ? WebTokens.line
              : WebTokens.green.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!notification.isRead) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 8),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: WebTokens.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    color: Color(0xFF1E2A20),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                notification.isRead ? 'Read' : 'Unread',
                style: TextStyle(
                  color: notification.isRead
                      ? const Color(0xFF737C74)
                      : WebTokens.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (notification.description.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              notification.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF626B63),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (timestamp != null || entry.acceptedBy != null) ...[
            const SizedBox(height: 8),
            if (timestamp != null)
              Text(
                timestamp,
                style: const TextStyle(
                  color: Color(0xFF737C74),
                  fontSize: 11,
                ),
              ),
            if (entry.acceptedBy != null) ...[
              const SizedBox(height: 3),
              Text(
                'Accepted by ${entry.acceptedBy}',
                style: const TextStyle(
                  color: Color(0xFF737C74),
                  fontSize: 11,
                ),
              ),
            ],
          ],
          if (!notification.isRead) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: ValueKey('notification-mark-read-${notification.id}'),
                onPressed: isMarking ? null : onMarkRead,
                child: Text(isMarking ? 'Saving...' : 'Mark as read'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WebProfilePanel extends StatelessWidget {
  const _WebProfilePanel({
    required this.user,
    required this.role,
    required this.onDismiss,
    required this.onViewProfile,
    required this.onSignOut,
  });

  final User? user;
  final UserRole role;
  final VoidCallback onDismiss;
  final VoidCallback onViewProfile;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final name = user?.name.trim() ?? '';
    final email = user?.email.trim() ?? '';
    final phone = user?.phone.trim() ?? '';

    return Material(
      key: const ValueKey('web-profile-panel'),
      color: Colors.white,
      elevation: 18,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              children: [
                _ProfileAvatar(
                  name: name,
                  profilePictureUrl: user?.profilePictureUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Profile details unavailable' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2A20),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (user != null)
                        Text(
                          role.label,
                          style: const TextStyle(
                            color: Color(0xFF6D776F),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          if (user != null) ...[
            if (email.isNotEmpty)
              _ProfileDetail(icon: Icons.email_outlined, value: email),
            if (phone.isNotEmpty)
              _ProfileDetail(icon: Icons.phone_outlined, value: phone),
          ],
          const Divider(height: 1, color: WebTokens.line),
          ListTile(
            key: const ValueKey('web-profile-view'),
            leading: const Icon(Icons.person_outline, color: WebTokens.green),
            title: const Text('Profile'),
            dense: true,
            onTap: onViewProfile,
          ),
          ListTile(
            key: const ValueKey('web-profile-logout'),
            leading: const Icon(Icons.logout, color: Color(0xFF8D342E)),
            title: const Text('Log out'),
            dense: true,
            onTap: () async => onSignOut(),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF737C74)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF505A52),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}
