import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/environment_config.dart';
import 'core/push/push_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initialize();

  EnvironmentConfig.initialize(Environment.dev);

  // On web, prevent the browser from restoring the previous scroll position
  // on refresh, so the page always starts at the top and renders top-to-bottom.
  try {
    html.window.history.scrollRestoration = 'manual';
    html.window.scrollTo(0, 0);
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: EverGreenApp(),
    ),
  );
}
