import '../core/network/api_client.dart';
import '../models/company_directory_item.dart';
import 'session_service.dart';

class CompanyDirectoryService {
  CompanyDirectoryService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<CompanyDirectoryItem>> listItems(String endpoint) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      endpoint,
      headers: _buildAuthHeaders(token),
    );

    final rawList = _extractList(response);

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CompanyDirectoryItem.fromJson)
        .toList();
  }

  Future<String> createItem(
    String endpoint, {
    required String name,
    String? description,
    String? regionId,
    Map<String, dynamic>? extraBody,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      endpoint,
      headers: _buildAuthHeaders(token),
      body: _buildBody(
        name: name,
        description: description,
        regionId: regionId,
        extraBody: extraBody,
      ),
      formUrlEncoded: true,
    );

    return response['message']?.toString() ?? 'Lưu dữ liệu thành công.';
  }

  Future<String> updateItem(
    String endpoint,
    String id, {
    required String name,
    String? description,
    String? regionId,
    Map<String, dynamic>? extraBody,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.patch(
      '$endpoint/$id',
      headers: _buildAuthHeaders(token),
      body: _buildBody(
        name: name,
        description: description,
        regionId: regionId,
        extraBody: extraBody,
      ),
      formUrlEncoded: true,
    );

    return response['message']?.toString() ?? 'Cập nhật dữ liệu thành công.';
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['items'],
      response['results'],
      response['records'],
      response['departments'],
      response['branches'],
      response['regions'],
      response['job_titles'],
      response['jobTitles'],
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
          candidate['departments'],
          candidate['branches'],
          candidate['regions'],
          candidate['job_titles'],
          candidate['jobTitles'],
        ];

        for (final nestedCandidate in nested) {
          if (nestedCandidate is List<dynamic>) {
            return nestedCandidate;
          }
        }

        final recursiveList = _findFirstList(candidate.values);
        if (recursiveList.isNotEmpty) {
          return recursiveList;
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

  Map<String, dynamic> _buildBody({
    required String name,
    String? description,
    String? regionId,
    Map<String, dynamic>? extraBody,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'description': description?.trim() ?? '',
      if (regionId != null && regionId.trim().isNotEmpty)
        'region_id': regionId.trim(),
      ...?extraBody,
    };
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
