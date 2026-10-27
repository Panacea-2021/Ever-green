import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/environment_config.dart';
import 'core/push/push_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initialize();

  EnvironmentConfig.initialize(Environment.prod);

  runApp(
    const ProviderScope(
      child: EverGreenApp(),
    ),
  );
}
