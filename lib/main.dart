import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/environment_config.dart';
import 'core/push/push_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initialize();

  // Draw behind the system bars so each screen's background extends all the
  // way up into the status bar and down into the navigation bar (edge-to-edge).
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Transparent system bars with dark icons, so they blend into the app's
  // light backgrounds everywhere.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Default entry point = the release configuration.
  EnvironmentConfig.initialize(Environment.prod);

  runApp(
    const ProviderScope(
      child: EverGreenApp(),
    ),
  );
}
