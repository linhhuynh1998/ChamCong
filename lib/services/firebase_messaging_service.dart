import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
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
  debugPrint('[FCM] Background message received: ${message.messageId}');
  debugPrint('[FCM] Background message title: ${message.notification?.title}');
  debugPrint('[FCM] Background message body: ${message.notification?.body}');
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
  bool _apnsRetryScheduled = false;
  int _apnsRetryCount = 0;
  static const int _maxApnsRetryCount = 5;

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

    debugPrint('[FCM] Starting initialization...');

    // Request permission for notifications
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] Authorization status: ${settings.authorizationStatus}');

    await _messaging.setAutoInitEnabled(true);

    // Local notifications are shown manually in onMessage, so disable the
    // platform foreground presentation to avoid duplicate banners on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    debugPrint(
        '[FCM] Foreground presentation options set: alert=false, badge=false, sound=false');

    await _initializeLocalNotifications();

    await registerCurrentDeviceToken();

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] Device Token refreshed: $token');
      await _sendTokenToBackend(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] ===== FOREGROUND MESSAGE RECEIVED =====');
      debugPrint('[FCM] Message ID: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
      debugPrint('[FCM] Data: ${message.data}');
      _showSystemNotification(message);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] ===== MESSAGE OPENED FROM BACKGROUND =====');
      debugPrint('[FCM] Message ID: ${message.messageId}');
      _openNotificationsPage();
      _handleMessage(message, onNotificationTap);
    });

    // Handle terminated message tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] ===== APP OPENED FROM TERMINATED STATE =====');
      debugPrint('[FCM] Message ID: ${initialMessage.messageId}');
      _openNotificationsPage();
      _handleMessage(initialMessage, onNotificationTap);
    }

    debugPrint('[FCM] Initialization complete');
  }

  Future<void> registerCurrentDeviceToken(
      {bool resetRetryState = false}) async {
    try {
      if (resetRetryState) {
        _apnsRetryScheduled = false;
        _apnsRetryCount = 0;
      }

      debugPrint(
          '[FCM] Attempting to get device token (attempt ${_apnsRetryCount + 1}/$_maxApnsRetryCount)');

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint('[FCM] APNs token still unavailable, scheduling retry');
          _scheduleApnsRetry();
          return;
        }

        debugPrint('[FCM] APNs token available: $apnsToken');
      }

      // Try to get FCM token
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        debugPrint('[FCM] Error getting FCM token: $e');
        // If we get APNS token not set error, retry with delay
        if (e.toString().contains('apns-token-not-set')) {
          debugPrint('[FCM] APNs token not yet set, will retry...');
          _scheduleApnsRetry();
          return;
        }
        rethrow;
      }

      debugPrint('[FCM] Device Token: $token');
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] FCM token is null/empty, scheduling retry');
        _scheduleApnsRetry();
        return;
      }

      await _sendTokenToBackend(token);

      // Stop retry loop once FCM token is available and sent.
      _apnsRetryScheduled = false;
      _apnsRetryCount = 0;
    } catch (e) {
      debugPrint('[FCM] Get/register device token failed: $e');
      _scheduleApnsRetry();
    }
  }

  Future<void> refreshAndRegisterCurrentDeviceToken() async {
    try {
      debugPrint('[FCM] Deleting current device token before refresh...');
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Delete device token failed, continuing: $e');
    }

    await registerCurrentDeviceToken(resetRetryState: true);
  }

  Future<String?> _waitForApnsToken() async {
    const int maxAttempts = 8;
    const Duration delay = Duration(seconds: 2);

    for (var i = 0; i < maxAttempts; i++) {
      final token = await _messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      debugPrint(
          '[FCM] APNs token not ready yet (attempt ${i + 1}/$maxAttempts)');

      if (i < maxAttempts - 1) {
        await Future<void>.delayed(delay);
      }
    }

    return null;
  }

  void _scheduleApnsRetry() {
    if (_apnsRetryScheduled) {
      return;
    }

    if (_apnsRetryCount >= _maxApnsRetryCount) {
      debugPrint(
        '[FCM] Stop retrying APNs token after $_maxApnsRetryCount attempts. '
        'If on a real device, verify Push Notifications capability and provisioning profile.',
      );
      return;
    }

    _apnsRetryScheduled = true;
    final delaySeconds = 3 + (_apnsRetryCount * 2); // 3, 5, 7, 9, 11 seconds
    debugPrint(
        '[FCM] Scheduling retry in ${delaySeconds}s (attempt ${_apnsRetryCount + 1})');

    Future<void>.delayed(Duration(seconds: delaySeconds), () async {
      _apnsRetryScheduled = false;
      _apnsRetryCount++;
      await registerCurrentDeviceToken();
    });
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }
    _localNotificationsInitialized = true;

    debugPrint('[FCM] Initializing local notifications...');

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {
        debugPrint('[FCM] Local notification tapped');
        _openNotificationsPage();
      },
    );

    debugPrint('[FCM] Local notifications initialized for iOS');

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_androidChannel);
      await androidImplementation.requestNotificationsPermission();
      debugPrint('[FCM] Android notification channel created');
    }
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    try {
      final title = _messageTitle(message);
      final body = _messageBody(message);

      debugPrint(
          '[FCM] Showing system notification - Title: $title, Body: $body');

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
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('[FCM] System notification displayed successfully');
    } catch (e) {
      debugPrint('[FCM] Error showing system notification: $e');
    }
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
