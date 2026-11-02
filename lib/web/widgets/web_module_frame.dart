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
import '../theme/web_tokens.dart';
import 'web_side_nav.dart';

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

  /// Form and settings pages (matched by prefix, so `/add-task/new` counts).
  static const _formPaths = [
    Routes.addTask,
    Routes.addEquipment,
    Routes.createAmc,
    Routes.createIndividualTask,
    Routes.addUser,
    Routes.editProfile,
    Routes.changePassword,
    Routes.uploadEquipments,
    Routes.uploadTechnicians,
    Routes.uploadAmc,
    Routes.downloadQr,
    Routes.profile,
    Routes.settings,
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
      _refreshIfStale();
    }
  }

  DateTime _lastRefresh = DateTime.now();

  /// Re-fetches the cached lists after [WebModuleFrame._refreshAfter]. The
  /// previous data stays on screen while the new request runs.
  void _refreshIfStale() {
    if (!ref.read(isAuthenticatedProvider)) return;
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < WebModuleFrame._refreshAfter) return;
    _lastRefresh = now;
    ref.invalidate(tasksProvider);
    ref.invalidate(companiesProvider);
    ref.invalidate(equipmentsProvider(null));
  }

  double _contentWidthFor(String location) {
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
    final framed = isAuthenticated &&
        _location.isNotEmpty &&
        !WebModuleFrame._unframedPaths.contains(_location);

    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    if (!framed) return content;

    // Keep the shared lists cached (and start loading them) for the whole
    // signed-in session, so modules open with data instead of re-fetching.
    ref.listen(tasksProvider, (_, __) {});
    ref.listen(companiesProvider, (_, __) {});
    ref.listen(equipmentsProvider(null), (_, __) {});

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
                  title: bannered ? '' : title,
                  userName: user?.name ?? role.label,
                  roleLabel: role.label,
                  onSearch: () => _navigate(Routes.globalSearch),
                  onNotifications: () => _navigate(Routes.notifications),
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
                          title: title,
                          entry: _entryFor(role),
                          width: width,
                          mq: mq,
                          constraints: constraints,
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
    required this.title,
    required this.entry,
    required this.width,
    required this.mq,
    required this.constraints,
    required this.child,
  });

  final String title;
  final WebNavEntry? entry;
  final double width;
  final MediaQueryData mq;
  final BoxConstraints constraints;
  final Widget child;

  static const _headerHeight = 78.0;

  @override
  Widget build(BuildContext context) {
    final height = (constraints.maxHeight - 48).clamp(0.0, double.infinity);
    final bodyHeight = (height - _headerHeight - 1).clamp(0.0, double.infinity);
    final e = entry;
    final icon = e?.svgIcon != null
        ? SvgPicture.asset(
            e!.svgIcon!,
            width: 21,
            height: 21,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          )
        : Icon(
            e?.icon ?? Icons.dashboard_outlined,
            size: 21,
            color: Colors.white,
          );

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(top: 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WebTokens.line),
          boxShadow: WebTokens.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: _headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFEAF4EC), Colors.white],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WebTokens.green,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: WebTokens.green.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTokens.heading(19),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: WebTokens.line),
            SizedBox(
              height: bodyHeight,
              child: MediaQuery(
                data: mq.copyWith(
                  size: Size(width, bodyHeight),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
    required this.onSearch,
    required this.onNotifications,
  });

  final String title;
  final String userName;
  final String roleLabel;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WebTokens.heading(21),
            ),
          ),
          _Hoverable(
            onTap: onSearch,
            child: Container(
              width: wide ? 280 : 200,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: WebTokens.cream,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: WebTokens.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: WebTokens.faint),
                  const SizedBox(width: 8),
                  Text('Search…', style: WebTokens.bodyText(13)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          _Hoverable(
            onTap: onNotifications,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTokens.cream,
                shape: BoxShape.circle,
                border: Border.all(color: WebTokens.line),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 20,
                color: WebTokens.ink,
              ),
            ),
          ),
          const SizedBox(width: 18),
          CircleAvatar(
            radius: 19,
            backgroundColor: WebTokens.mintSoft,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: WebTokens.fontFamily,
                fontWeight: FontWeight.w700,
                color: WebTokens.green,
              ),
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTokens.bodyText(
                      13.5,
                      color: WebTokens.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(roleLabel, style: WebTokens.bodyText(11.5)),
                ],
              ),
            ),
          ],
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
