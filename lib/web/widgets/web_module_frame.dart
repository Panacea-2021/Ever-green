import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  };

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

  void _onRouteChanged() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      _syncLocation();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => _syncLocation());
    }
  }

  void _syncLocation() {
    if (!mounted) return;
    final location = _currentLocation();
    if (location != _location) setState(() => _location = location);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider).logout();
    widget.router.go(Routes.home);
  }

  void _navigate(String route) {
    if (route != _location) widget.router.go(route);
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

    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final webDesigned = WebModuleFrame._webDesignedPaths.contains(_location);

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
                  title: _titleFor(role),
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
                          .clamp(0.0, WebModuleFrame.maxContentWidth);
                      final height = constraints.maxHeight - 40;
                      return Center(
                        child: Container(
                          width: width,
                          height: height,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
