import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

/// Firebase Cloud Messaging for the backend's task notifications. The backend
/// sends to every token registered for the user (`tokens` table), so the
/// device token is sent on sign-in and again whenever FCM rotates it.
class PushService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  PushService(this._apiClient, this._tokenStorage);

  static bool _ready = false;
  static StreamSubscription<String>? _refreshSub;
  static final _local = FlutterLocalNotificationsPlugin();
  static final _taskTaps = StreamController<int>.broadcast();
  static int? _pendingTaskId;

  /// Task ids from notifications the user tapped while the app was running.
  static Stream<int> get taskTaps => _taskTaps.stream;

  /// Task id from the notification that launched the app, consumed once.
  static int? takePendingTaskId() {
    final id = _pendingTaskId;
    _pendingTaskId = null;
    return id;
  }

  /// The backend puts the ticket id in `data.task_link`.
  static int? _taskIdOf(Map<String, dynamic> data) {
    final raw = data['task_link'] ?? data['task_id'] ?? data['taskId'];
    final id = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    return id != null && id > 0 ? id : null;
  }

  static void _openTask(int? id) {
    if (id == null) return;
    if (_taskTaps.hasListener) {
      _taskTaps.add(id);
    } else {
      _pendingTaskId = id;
    }
  }

  static const _channel = AndroidNotificationChannel(
    'evergreen_default',
    'EverGreen updates',
    description: 'Ticket and service updates',
    importance: Importance.high,
  );

  /// Never throws: the app must still start if Firebase is unavailable.
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _openTask(int.tryParse(response.payload ?? '')),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _openTask(_taskIdOf(message.data)));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _pendingTaskId = _taskIdOf(initial.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _pendingTaskId ??= int.tryParse(launch!.notificationResponse?.payload ?? '');
      }
      _ready = true;
    } catch (e) {
      debugPrint('PushService: Firebase unavailable ($e)');
    }
  }

  static Future<String?> currentToken() async {
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  /// Asks for notification permission and registers this device's token.
  Future<void> registerForUser() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await currentToken();
      if (token != null) await _upsert(token);
      await _refreshSub?.cancel();
      _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(_upsert);
    } catch (e) {
      debugPrint('PushService: token registration failed ($e)');
    }
  }

  Future<void> _upsert(String token) async {
    if (!await _tokenStorage.hasValidTokens()) return;
    final deviceId = await _tokenStorage.getDeviceId();
    await _apiClient.post<dynamic>(
      'user/upsertToken',
      data: {'fcm_id': token, 'device_id': deviceId},
    );
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      payload: _taskIdOf(message.data)?.toString(),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}
