import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/app_notification_item.dart';
import 'session_service.dart';

class AppNotificationService {
  AppNotificationService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<void> registerDeviceToken(String token, {String? platform}) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final authToken = await _sessionService.getToken();
    await _apiClient.post(
      '/device-token',
      headers: _buildAuthHeaders(authToken),
      body: <String, dynamic>{
        'token': trimmed,
        'platform': platform ?? _platformName,
      },
    );
  }

  Future<List<AppNotificationItem>> fetchNotifications() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/notifications',
      headers: _buildAuthHeaders(token),
    );

    return _extractList(response)
        .map(AppNotificationItem.fromJson)
        .toList(growable: false);
  }

  Future<void> markAsRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final token = await _sessionService.getToken();
    await _apiClient.patch(
      '/notifications/$trimmed/read',
      headers: _buildAuthHeaders(token),
    );
  }

  Future<void> markAllAsRead() async {
    final token = await _sessionService.getToken();
    await _apiClient.patch(
      '/notifications/read-all',
      headers: _buildAuthHeaders(token),
    );
  }

  Map<String, String> _buildAuthHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
    return 'unknown';
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> body) {
    final payload = body['data'];
    if (payload is List) {
      return _mapList(payload);
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['notifications', 'items', 'results', 'records']) {
        final value = payload[key];
        if (value is List) {
          return _mapList(value);
        }
      }
    }

    for (final key in const ['notifications', 'items', 'results', 'records']) {
      final value = body[key];
      if (value is List) {
        return _mapList(value);
      }
    }

    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _mapList(List source) {
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
