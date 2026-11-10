import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/auth_state_provider.dart';
import 'shared/widgets/global_scroll_to_top.dart';
import 'web/widgets/web_module_frame.dart';

class EverGreenApp extends ConsumerStatefulWidget {
  const EverGreenApp({super.key});

  // Transparent system bars with dark icons so they blend into the app's
  // light backgrounds everywhere (edge-to-edge).
  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  ConsumerState<EverGreenApp> createState() => _EverGreenAppState();
}

class _EverGreenAppState extends ConsumerState<EverGreenApp> {
  /// Paths shown before the user reaches the app; a tapped notification waits
  /// until navigation has moved past them.
  static const _entryPaths = {
    Routes.splash,
    Routes.getStarted,
    Routes.login,
    Routes.register,
    Routes.forgotPassword,
  };

  StreamSubscription<int>? _tapSub;
  GoRouter? _router;
  int? _pendingTaskId;

  @override
  void initState() {
    super.initState();
    _pendingTaskId = PushService.takePendingTaskId();
    _tapSub = PushService.taskTaps.listen((id) {
      _pendingTaskId = id;
      _openPendingTask();
    });
  }

  void _attach(GoRouter router) {
    if (identical(_router, router)) return;
    _router?.routerDelegate.removeListener(_openPendingTask);
    _router = router;
    router.routerDelegate.addListener(_openPendingTask);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingTask());
  }

  void _openPendingTask() {
    final id = _pendingTaskId;
    final router = _router;
    if (id == null || router == null || !mounted) return;
    if (!ref.read(authStateProvider).isAuthenticated) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (_entryPaths.contains(path)) return;
    _pendingTaskId = null;
    router.push('${Routes.taskDetails}/$id');
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _router?.routerDelegate.removeListener(_openPendingTask);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    _attach(router);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: EverGreenApp._overlayStyle,
      child: MaterialApp.router(
        title: 'EverGreen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // Force light theme so dark-mode phones do not break the UI.
        themeMode: ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => GlobalScrollToTop(
          child: kIsWeb
              ? WebModuleFrame(
                  router: router,
                  child: child ?? const SizedBox.shrink(),
                )
              : child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
