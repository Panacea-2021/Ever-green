import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';

/// Sends the user back to Home when the Android back button is pressed while
/// one of the secondary bottom-navigation tabs is showing.
///
/// Switching tabs uses `context.go`, so the route stack keeps a single entry
/// and go_router reports that there is nothing to pop. Without this widget the
/// framework falls through to `SystemNavigator.pop()` and the OS closes the app.
/// Intercepting the notification before that fallback keeps the app open while
/// leaving pushed pages (details, settings, dialogs) to pop as usual.
class RootTabBackHandling extends StatefulWidget {
  const RootTabBackHandling({
    super.key,
    required this.router,
    required this.child,
  });

  /// Router whose current location decides what a back press should do.
  final GoRouter router;

  final Widget child;

  /// Tabs that fall back to [Routes.home] instead of closing the app.
  static const List<String> homeFallbackPaths = <String>[
    Routes.amcs,
    Routes.tasks,
    Routes.profile,
  ];

  /// Whether [path] is one of the secondary tabs (or a page inside one).
  static bool isSecondaryTab(String path) => homeFallbackPaths
      .any((tab) => path == tab || path.startsWith('$tab/'));

  @override
  State<RootTabBackHandling> createState() => _RootTabBackHandlingState();
}

class _RootTabBackHandlingState extends State<RootTabBackHandling>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // The browser owns the history on web; leave it untouched.
    if (kIsWeb) return false;

    final delegate = widget.router.routerDelegate;
    // A pushed page or an open dialog must pop first.
    if (delegate.canPop()) return false;

    final path = delegate.currentConfiguration.uri.path;
    if (!RootTabBackHandling.isSecondaryTab(path)) return false;

    widget.router.go(Routes.home);
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
