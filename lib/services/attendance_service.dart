import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/attendance_day_record.dart';
import 'session_service.dart';

class AttendanceService {
  AttendanceService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<AttendanceDayRecord>> listAttendance() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/attendance',
      headers: _buildAuthHeaders(token),
    );

    final rawList = switch (response['data']) {
      List<dynamic> data => data,
      Map<String, dynamic> data when data['items'] is List<dynamic> =>
        data['items'] as List<dynamic>,
      Map<String, dynamic> data when data['records'] is List<dynamic> =>
        data['records'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(AttendanceDayRecord.fromJson)
        .toList();
  }

  Future<String> checkIn({
    Map<String, dynamic>? body,
  }) async {
    return _submitAttendance(
      endpoint: '/attendance/checkin',
      body: body,
      debugLabel: 'CHECKIN',
      fallbackMessage: 'Chấm công thành công.',
    );
  }

  Future<String> checkOut({
    Map<String, dynamic>? body,
  }) async {
    return _submitAttendance(
      endpoint: '/attendance/checkout',
      body: body,
      debugLabel: 'CHECKOUT',
      fallbackMessage: 'Rời ca thành công.',
    );
  }

  Future<String> _submitAttendance({
    required String endpoint,
    required String debugLabel,
    required String fallbackMessage,
    Map<String, dynamic>? body,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      endpoint,
      headers: _buildAuthHeaders(token),
      body: body,
      formUrlEncoded: true,
    );

    if (kDebugMode) {
      debugPrint('[$debugLabel PARSED RESPONSE] $response');
    }

    final data = response['data'];
    final nestedData = data is Map<String, dynamic> ? data : null;
    final message = response['message']?.toString() ??
        response['msg']?.toString() ??
        nestedData?['message']?.toString() ??
        nestedData?['msg']?.toString() ??
        fallbackMessage;

    if (kDebugMode) {
      debugPrint('[$debugLabel MESSAGE] $message');
    }

    return message;
  }

  Map<String, String> _buildAuthHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }
}
