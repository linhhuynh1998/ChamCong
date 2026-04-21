import '../core/network/api_client.dart';
import '../models/shift_item.dart';
import 'session_service.dart';

class ShiftService {
  ShiftService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<ShiftItem>> listShifts() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/attendance/shifts',
      headers: _buildAuthHeaders(token),
    );

    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(ShiftItem.fromJson)
        .toList();
  }

  Future<ShiftItem?> fetchShiftDetail(String id) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/attendance/shifts/$id',
      headers: _buildAuthHeaders(token),
    );

    final rawItem = _extractItem(response);
    if (rawItem == null || rawItem.isEmpty) {
      return null;
    }

    return ShiftItem.fromJson(rawItem);
  }

  Future<String> createShift({
    required String name,
    required String startHour,
    required String startMinute,
    required String endHour,
    required String endMinute,
    required String regionId,
    required String branchId,
    required List<String> departmentIds,
    required List<String> jobTitleIds,
    required List<int> weekdays,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      '/attendance/shifts',
      headers: _buildAuthHeaders(token),
      formUrlEncoded: true,
      body: _buildBody(
        name: name,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        regionId: regionId,
        branchId: branchId,
        departmentIds: departmentIds,
        jobTitleIds: jobTitleIds,
        weekdays: weekdays,
      ),
    );

    return response['message']?.toString() ?? 'Tạo ca thành công.';
  }

  Future<String> updateShift({
    required String id,
    required String name,
    required String startHour,
    required String startMinute,
    required String endHour,
    required String endMinute,
    required String regionId,
    required String branchId,
    required List<String> departmentIds,
    required List<String> jobTitleIds,
    required List<int> weekdays,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.patch(
      '/attendance/shifts/$id',
      headers: _buildAuthHeaders(token),
      formUrlEncoded: true,
      body: _buildBody(
        name: name,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        regionId: regionId,
        branchId: branchId,
        departmentIds: departmentIds,
        jobTitleIds: jobTitleIds,
        weekdays: weekdays,
      ),
    );

    return response['message']?.toString() ?? 'Cập nhật ca thành công.';
  }

  Map<String, String> _buildAuthHeaders(String? token) {
    return token == null || token.isEmpty
        ? const <String, String>{}
        : <String, String>{'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _buildBody({
    required String name,
    required String startHour,
    required String startMinute,
    required String endHour,
    required String endMinute,
    required String regionId,
    required String branchId,
    required List<String> departmentIds,
    required List<String> jobTitleIds,
    required List<int> weekdays,
  }) {
    return <String, dynamic>{
      'name': name,
      'start_hour': startHour,
      'start_minute': startMinute,
      'end_hour': endHour,
      'end_minute': endMinute,
      'region_id': regionId,
      'branch_id': branchId,
      'department_ids[]': departmentIds,
      'job_title_ids[]': jobTitleIds,
      'weekdays[]': weekdays,
    };
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['items'],
      response['results'],
      response['records'],
      response['shifts'],
    ];

    for (final candidate in candidates) {
      if (candidate is List<dynamic>) {
        return candidate;
      }

      if (candidate is Map<String, dynamic>) {
        final nested = <dynamic>[
          candidate['items'],
          candidate['data'],
          candidate['results'],
          candidate['records'],
          candidate['shifts'],
        ];

        for (final item in nested) {
          if (item is List<dynamic>) {
            return item;
          }
        }
      }
    }

    return const <dynamic>[];
  }

  Map<String, dynamic>? _extractItem(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['item'],
      response['result'],
      response['record'],
      response['shift'],
      response,
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        final nested = <dynamic>[
          candidate['shift'],
          candidate['data'],
          candidate['item'],
          candidate['result'],
          candidate['record'],
        ];

        for (final item in nested) {
          if (item is Map<String, dynamic> && item.isNotEmpty) {
            return item;
          }
        }

        if (_looksLikeShift(candidate)) {
          return candidate;
        }
      }
    }

    return null;
  }

  bool _looksLikeShift(Map<String, dynamic> item) {
    const keys = <String>{
      'name',
      'start_hour',
      'start_time',
      'end_hour',
      'end_time',
      'region_id',
      'branch_id',
      'weekdays',
    };

    return item.keys.any(keys.contains);
  }
}
