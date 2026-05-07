import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/routes/app_navigator.dart';
import '../core/routes/app_routes.dart';
import '../firebase_options.dart';
import 'app_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AppNotificationService _notificationService = AppNotificationService();
  bool _initialized = false;
  bool _localNotificationsInitialized = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'request_notifications',
    'Thông báo yêu cầu',
    description: 'Thông báo yêu cầu và trạng thái duyệt yêu cầu',
    importance: Importance.high,
  );

  /// Initialize Firebase Messaging
  Future<void> initialize({
    required Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    // Request permission for notifications
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await _initializeLocalNotifications();

    await registerCurrentDeviceToken();

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] Device Token refreshed: $token');
      await _sendTokenToBackend(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      _showSystemNotification(message);
      _showForegroundMessage(message);
      _handleMessage(message, onNotificationTap);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened from background: ${message.messageId}');
      _openNotificationsPage();
      _handleMessage(message, onNotificationTap);
    });

    // Handle terminated message tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated: ${initialMessage.messageId}');
      _openNotificationsPage();
      _handleMessage(initialMessage, onNotificationTap);
    }
  }

  Future<void> registerCurrentDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Device Token: $token');
      await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] Get/register device token failed: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }
    _localNotificationsInitialized = true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) => _openNotificationsPage(),
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_androidChannel);
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    final title = _messageTitle(message);
    final body = _messageBody(message);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _sendTokenToBackend(String? token) async {
    if (token == null || token.trim().isEmpty) {
      return;
    }

    try {
      await _notificationService.registerDeviceToken(token);
      debugPrint('[FCM] Device token registered to backend');
    } catch (e) {
      debugPrint('[FCM] Register backend token failed: $e');
    }
  }

  /// Handle incoming message
  void _handleMessage(
    RemoteMessage message,
    Function(Map<String, dynamic>) onNotificationTap,
  ) {
    final data = message.data;
    debugPrint('[FCM] Message data: $data');

    if (data.isNotEmpty) {
      onNotificationTap(data);
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final context = AppNavigator.context;
    if (context == null) {
      return;
    }

    final title = message.notification?.title ?? 'Thông báo';
    final body = message.notification?.body ?? '';
    final text = body.isEmpty ? title : '$title\n$body';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Xem',
          onPressed: _openNotificationsPage,
        ),
      ),
    );
  }

  void _openNotificationsPage() {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    navigator.pushNamed(AppRoutes.notifications);
  }

  String _messageTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title']?.toString() ??
        'Thông báo';
  }

  String _messageBody(RemoteMessage message) {
    return message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from topic: $topic');
  }
}
