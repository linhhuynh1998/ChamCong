import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import 'session_service.dart';

class RequestsService {
  RequestsService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  /// Fetch requests between [start] and [end] (inclusive).
  /// Uses query params `start_date` and `end_date` in `yyyy-MM-dd` format.
  Future<List<Map<String, dynamic>>> fetchRequests({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final token = await _sessionService.getToken();
      _debugPrintToken(token);
      final queryParameters = <String, dynamic>{
        'start_date': _formatDate(start),
        'end_date': _formatDate(end),
        'per_page': 100,
        'limit': 100,
      };
      final requests = <Map<String, dynamic>>[];

      requests.addAll(
        await _fetchRequestPages(
          token: token,
          queryParameters: queryParameters,
        ),
      );

      for (final status in const ['pending', 'approved', 'rejected']) {
        try {
          requests.addAll(
            await _fetchRequestPages(
              token: token,
              queryParameters: <String, dynamic>{
                ...queryParameters,
                'status': status,
              },
            ),
          );
        } catch (_) {}
      }

      return _dedupeRequests(requests);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchRequestDetail(String id) async {
    final token = await _sessionService.getToken();
    _debugPrintToken(token);
    final response = await _apiClient.get(
      '/requests/$id',
      headers: _buildAuthHeaders(token),
    );

    return _extractMap(response);
  }

  Future<RequestSummaryCounts> fetchRequestSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final token = await _sessionService.getToken();
    _debugPrintToken(token);
    final response = await _apiClient.get(
      '/requests/summary',
      queryParameters: {
        'start_date': _formatDate(start),
        'end_date': _formatDate(end),
      },
      headers: _buildAuthHeaders(token),
    );

    return RequestSummaryCounts.fromJson(_extractMap(response));
  }

  Future<String> createRequest({
    required String requestType,
    required String employeeId,
    required Map<String, dynamic> fields,
    String? companyId,
    List<Map<String, dynamic>> details = const <Map<String, dynamic>>[],
  }) async {
    final token = await _sessionService.getToken();
    _debugPrintToken(token);

    final body = <String, dynamic>{
      if (companyId != null && companyId.trim().isNotEmpty)
        'company_id': _numericStringOrText(companyId),
      'request_type': requestType.trim(),
      'employee_id': _numericStringOrText(employeeId),
      'fields': fields,
      'details': details,
    };

    final response = await _apiClient.post(
      '/requests',
      headers: _buildAuthHeaders(token),
      body: body,
    );

    return response['message']?.toString() ?? 'Gửi yêu cầu thành công.';
  }

  Future<String> updateRequestStatus({
    required String id,
    required String status,
    String? companyId,
  }) async {
    final token = await _sessionService.getToken();
    _debugPrintToken(token);

    final body = <String, dynamic>{
      'ids': <String>[id],
      'status': status,
      if (companyId != null && companyId.trim().isNotEmpty)
        'company_id': companyId.trim(),
    };

    final response = await _apiClient.patch(
      '/requests/status',
      headers: _buildAuthHeaders(token),
      body: body,
    );

    return response['message']?.toString() ?? 'Cập nhật trạng thái thành công.';
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, String> _buildAuthHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _numericStringOrText(String value) {
    final trimmed = value.trim();
    return int.tryParse(trimmed) ?? trimmed;
  }

  void _debugPrintToken(String? token) {
    debugPrint(
        '[AUTH TOKEN] ${token == null || token.isEmpty ? 'EMPTY' : 'Bearer $token'}');
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> body) {
    final payload = _extractListPayload(body);

    if (payload is List) {
      return _mapList(payload);
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'requests',
        'items',
        'results',
        'records'
      ]) {
        final value = payload[key];
        if (value is List) {
          return _mapList(value);
        }
      }
    }

    return <Map<String, dynamic>>[];
  }

  dynamic _extractListPayload(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'requests',
        'items',
        'results',
        'records'
      ]) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }

      return data;
    }

    for (final key in const ['requests', 'items', 'results', 'records']) {
      final value = body[key];
      if (value is List) {
        return value;
      }
    }

    if (body is List) {
      return body;
    }

    return body;
  }

  List<Map<String, dynamic>> _mapList(List source) {
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchRequestPages({
    required String? token,
    required Map<String, dynamic> queryParameters,
  }) async {
    final response = await _apiClient.get(
      '/requests',
      queryParameters: queryParameters,
      headers: _buildAuthHeaders(token),
    );

    final requests = <Map<String, dynamic>>[
      ..._extractList(response),
    ];
    final lastPage = _pickPaginationInt(
      response,
      const ['last_page', 'lastPage', 'total_pages', 'totalPages'],
    );

    if (lastPage != null && lastPage > 1) {
      final maxPage = lastPage > 20 ? 20 : lastPage;
      for (var page = 2; page <= maxPage; page++) {
        final pageResponse = await _apiClient.get(
          '/requests',
          queryParameters: <String, dynamic>{
            ...queryParameters,
            'page': page,
          },
          headers: _buildAuthHeaders(token),
        );
        requests.addAll(_extractList(pageResponse));
      }
    }

    return requests;
  }

  List<Map<String, dynamic>> _dedupeRequests(
    List<Map<String, dynamic>> source,
  ) {
    final seen = <String>{};
    final results = <Map<String, dynamic>>[];

    for (final item in source) {
      final id = (item['id'] ?? item['request_id'])?.toString().trim() ?? '';
      if (id.isNotEmpty && !seen.add(id)) {
        continue;
      }
      results.add(item);
    }

    return results;
  }

  int? _pickPaginationInt(Map<String, dynamic> body, List<String> keys) {
    final maps = <Map<String, dynamic>>[
      body,
      if (body['data'] is Map<String, dynamic>)
        body['data'] as Map<String, dynamic>,
      if (body['meta'] is Map<String, dynamic>)
        body['meta'] as Map<String, dynamic>,
    ];

    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _extractMap(Map<String, dynamic> body) {
    for (final key in ['data', 'item', 'result', 'record', 'request']) {
      final v = body[key];
      if (v is Map<String, dynamic>) {
        return v;
      }
    }

    return body;
  }
}

class RequestSummaryCounts {
  const RequestSummaryCounts({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int pending;
  final int approved;
  final int rejected;

  factory RequestSummaryCounts.fromJson(Map<String, dynamic> json) {
    return RequestSummaryCounts(
      pending: _pickInt(json, const [
        'pending',
        'pending_count',
        'request',
        'requests',
        'request_count',
        'total_request',
        'total_requests',
        'yeu_cau',
        'yêu_cầu',
      ]),
      approved: _pickInt(json, const [
        'approved',
        'approve',
        'approved_count',
        'accept',
        'accepted',
        'accepted_count',
        'chap_thuan',
        'chấp_thuận',
      ]),
      rejected: _pickInt(json, const [
        'rejected',
        'reject',
        'rejected_count',
        'denied',
        'denied_count',
        'refused',
        'refused_count',
        'tu_choi',
        'từ_chối',
      ]),
    );
  }

  static int _pickInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        final value = _intFromValue(json[key]);
        if (value != null) return value;
      }
    }

    for (final entry in json.entries) {
      final normalizedEntryKey = _normalizeKey(entry.key);
      for (final key in keys) {
        if (normalizedEntryKey == _normalizeKey(key)) {
          final value = _intFromValue(entry.value);
          if (value != null) return value;
        }
      }
    }

    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _pickInt(value, keys);
        if (nested > 0) return nested;
      } else if (value is Map) {
        final nested = _pickInt(Map<String, dynamic>.from(value), keys);
        if (nested > 0) return nested;
      }
    }

    return 0;
  }

  static int? _intFromValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
