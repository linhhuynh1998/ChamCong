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
}
