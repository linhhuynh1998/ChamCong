import '../core/network/api_client.dart';
import '../models/company_entity_item.dart';
import 'session_service.dart';

class CompanyEntityService {
  CompanyEntityService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<CompanyEntityItem>> listEntities(String endpoint) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      endpoint,
      headers: _buildAuthHeaders(token),
    );

    final rawList = _extractList(response);

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CompanyEntityItem.fromJson)
        .toList();
  }

  Future<String> createEntity({
    required String endpoint,
    required String name,
    required String description,
    String? regionId,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      endpoint,
      headers: _buildAuthHeaders(token),
      body: <String, dynamic>{
        if (regionId != null && regionId.trim().isNotEmpty)
          'region_id': regionId.trim(),
        'name': name.trim(),
        'description': description.trim(),
      },
      formUrlEncoded: true,
    );

    return response['message']?.toString() ??
        response['msg']?.toString() ??
        'Lưu dữ liệu thành công.';
  }

  Future<String> updateEntity({
    required String endpoint,
    required String id,
    required String name,
    required String description,
    String? regionId,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      '$endpoint/$id',
      headers: _buildAuthHeaders(token),
      body: <String, dynamic>{
        '_method': 'PATCH',
        if (regionId != null && regionId.trim().isNotEmpty)
          'region_id': regionId.trim(),
        'name': name.trim(),
        'description': description.trim(),
      },
      formUrlEncoded: true,
    );

    return response['message']?.toString() ??
        response['msg']?.toString() ??
        'Cập nhật dữ liệu thành công.';
  }

  Map<String, String> _buildAuthHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['items'],
      response['records'],
      response['results'],
      response['permission_groups'],
      response['permissionGroups'],
      response['groups'],
    ];

    for (final candidate in candidates) {
      if (candidate is List<dynamic>) {
        return candidate;
      }

      if (candidate is Map<String, dynamic>) {
        final nested = <dynamic>[
          candidate['items'],
          candidate['records'],
          candidate['results'],
          candidate['data'],
          candidate['permission_groups'],
          candidate['permissionGroups'],
          candidate['groups'],
        ];

        for (final nestedCandidate in nested) {
          if (nestedCandidate is List<dynamic>) {
            return nestedCandidate;
          }
        }

        final recursive = _findFirstList(candidate.values);
        if (recursive.isNotEmpty) {
          return recursive;
        }
      }
    }

    return _findFirstList(response.values);
  }

  List<dynamic> _findFirstList(Iterable<dynamic> values) {
    for (final value in values) {
      if (value is List<dynamic>) {
        return value;
      }

      if (value is Map<String, dynamic>) {
        final nested = _findFirstList(value.values);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return const <dynamic>[];
  }
}
