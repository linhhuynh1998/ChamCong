import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
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

  Future<CompanyDirectoryItem?> fetchItem(String endpoint) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      endpoint,
      headers: _buildAuthHeaders(token),
    );

    final rawItem = _extractItemMap(response);
    if (rawItem == null || rawItem.isEmpty) {
      final rawList = _extractList(response);
      final mappedItems = rawList.whereType<Map<String, dynamic>>().toList();
      final firstItem = mappedItems.isNotEmpty ? mappedItems.first : null;
      if (firstItem == null || firstItem.isEmpty) {
        return null;
      }
      return CompanyDirectoryItem.fromJson(firstItem);
    }

    return CompanyDirectoryItem.fromJson(rawItem);
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
    final resolvedEndpoint = endpoint == '/company/location'
        ? endpoint
        : '$endpoint/$id';

    final response = await _apiClient.patch(
      resolvedEndpoint,
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

  Future<({String? latitude, String? longitude})> geocodeAddress({
    required String country,
    required String city,
    required String ward,
    required String addressDetail,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/location-options/geocode',
      headers: _buildAuthHeaders(token),
      queryParameters: <String, dynamic>{
        'country': country,
        'city': city,
        'ward': ward,
        'address_detail': addressDetail,
      },
    );

    final latitude = _findFirstStringByKeys(
      response,
      const ['latitude', 'lat', 'checkin_latitude'],
    );
    final longitude = _findFirstStringByKeys(
      response,
      const ['longitude', 'lng', 'lon', 'checkin_longitude'],
    );

    if ((latitude ?? '').isEmpty || (longitude ?? '').isEmpty) {
      throw ApiException('Không lấy được tọa độ từ địa chỉ đã nhập.');
    }

    return (latitude: latitude, longitude: longitude);
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

  Map<String, dynamic>? _extractItemMap(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['item'],
      response['result'],
      response['record'],
      response['location'],
      response['company'],
      response,
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        final nestedLocation = _findLocationLikeMap(candidate);
        if (nestedLocation != null) {
          return nestedLocation;
        }

        final nestedList = _extractList(candidate);
        if (nestedList.isEmpty && _looksLikeSingleItem(candidate)) {
          return candidate;
        }
      }

      if (candidate is List) {
        final mappedItems = candidate.whereType<Map<String, dynamic>>().toList();
        final firstMap = mappedItems.isNotEmpty ? mappedItems.first : null;
        if (firstMap != null && firstMap.isNotEmpty) {
          return firstMap;
        }
      }
    }

    return null;
  }

  Map<String, dynamic>? _findLocationLikeMap(Map<String, dynamic> source) {
    if (_looksLikeLocationMap(source)) {
      return source;
    }

    for (final value in source.values) {
      if (value is Map<String, dynamic>) {
        final nested = _findLocationLikeMap(value);
        if (nested != null) {
          return nested;
        }
      }

      if (value is List) {
        for (final item in value.whereType<Map<String, dynamic>>()) {
          final nested = _findLocationLikeMap(item);
          if (nested != null) {
            return nested;
          }
        }
      }
    }

    return null;
  }

  bool _looksLikeLocationMap(Map<String, dynamic> map) {
    const keys = <String>{
      'address',
      'address_detail',
      'city',
      'ward',
      'latitude',
      'longitude',
      'default_branch_id',
      'radius_meters',
      'full_address',
      'countries',
    };

    int matches = 0;
    for (final key in keys) {
      if (map.containsKey(key) && _normalizeScalarString(map[key]) != null) {
        matches++;
      }
    }

    return matches >= 2;
  }

  bool _looksLikeSingleItem(Map<String, dynamic> map) {
    if (_looksLikeLocationMap(map)) {
      return true;
    }

    return _normalizeScalarString(map['id']) != null ||
        _normalizeScalarString(map['name']) != null ||
        _normalizeScalarString(map['description']) != null;
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

  String? _findFirstStringByKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final directValue = source[key];
      final normalized = _normalizeScalarString(directValue);
      if (normalized != null) {
        return normalized;
      }
    }

    return _findFirstStringRecursively(source.values, keys);
  }

  String? _findFirstStringRecursively(
    Iterable<dynamic> values,
    List<String> keys,
  ) {
    for (final value in values) {
      final normalized = _normalizeScalarString(value);
      if (normalized != null && keys.isEmpty) {
        return normalized;
      }

      if (value is Map<String, dynamic>) {
        for (final key in keys) {
          final nestedDirect = _normalizeScalarString(value[key]);
          if (nestedDirect != null) {
            return nestedDirect;
          }
        }

        final nested = _findFirstStringRecursively(value.values, keys);
        if (nested != null) {
          return nested;
        }
      }

      if (value is List<dynamic>) {
        final nested = _findFirstStringRecursively(value, keys);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String? _normalizeScalarString(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toString();
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
