import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppLocalNotificationService {
  AppLocalNotificationService._();

  static final AppLocalNotificationService instance =
      AppLocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'app_notifications',
    'Thông báo ứng dụng',
    description: 'Thông báo cục bộ sau khi gửi yêu cầu thành công',
    importance: Importance.high,
  );

  Future<void> showRequestCreated({
    required String requestType,
    required String message,
  }) async {
    await _ensureInitialized();

    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Yêu cầu đã được gửi',
        '$requestType: $message',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
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
    } catch (e) {
      debugPrint(
          '[LOCAL NOTIFICATION] Failed to show request notification: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(initializationSettings);

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
      await androidImplementation.requestNotificationsPermission();
    }
  }
}
