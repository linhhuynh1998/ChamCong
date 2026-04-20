import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/location_option.dart';
import 'session_service.dart';

class AdministrativeLocationService {
  AdministrativeLocationService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<LocationOption>> fetchCountries() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/location-options/countries',
      headers: _buildAuthHeaders(token ?? ''),
    );

    return _extractOptions(
      response,
      idKeys: const ['code', 'country_code', 'value', 'id'],
      nameKeys: const [
        'name',
        'label',
        'title',
        'country_name',
        'full_name',
        'fullName',
        'display_name',
        'text',
      ],
    );
  }

  Future<List<LocationOption>> fetchCities(String countryCode) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/location-options/cities',
      headers: _buildAuthHeaders(token ?? ''),
      queryParameters: <String, dynamic>{
        'country': countryCode,
      },
    );

    return _extractOptions(
      response,
      idKeys: const ['city_code', 'code', 'value', 'id'],
      nameKeys: const [
        'name',
        'label',
        'title',
        'city_name',
        'full_name',
        'fullName',
        'display_name',
        'text',
        'city',
      ],
    );
  }

  Future<List<LocationOption>> fetchWards(
    String countryCode,
    String cityCode,
  ) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/location-options/wards',
      headers: _buildAuthHeaders(token ?? ''),
      queryParameters: <String, dynamic>{
        'country': countryCode,
        'city_code': cityCode,
      },
    );

    return _extractOptions(
      response,
      idKeys: const ['ward_code', 'code', 'value', 'id', 'ward_id'],
      nameKeys: const [
        'name',
        'label',
        'title',
        'ward_name',
        'full_name',
        'fullName',
        'display_name',
        'text',
        'ward',
      ],
    );
  }

  Map<String, String> _buildAuthHeaders(String token) {
    if (token.trim().isEmpty) {
      throw ApiException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  List<LocationOption> _extractOptions(
    Map<String, dynamic> response, {
    required List<String> idKeys,
    required List<String> nameKeys,
  }) {
    final seed = _extractPrimaryPayload(response);
    final options = _extractOptionsRecursively(
      seed,
      idKeys: idKeys,
      nameKeys: nameKeys,
      fromListItem: seed is List,
    );

    final uniqueById = <String, LocationOption>{};
    for (final option in options) {
      uniqueById[option.id] = option;
    }

    return uniqueById.values.toList();
  }

  List<LocationOption> _extractOptionsRecursively(
    dynamic value, {
    required List<String> idKeys,
    required List<String> nameKeys,
    bool fromListItem = false,
  }) {
    final results = <LocationOption>[];

    if (value is Map<String, dynamic>) {
      final id = _pickFirstString(value, idKeys);
      final name = _pickFirstString(value, nameKeys);
      final fallbackName = _pickFirstString(
        value,
        const ['name', 'label', 'title', 'text', 'value'],
      );

      final resolvedName = name ?? fallbackName;
      final resolvedId = id ?? resolvedName;

      if (fromListItem && resolvedId != null && resolvedName != null) {
        results.add(
          LocationOption(
            id: resolvedId,
            name: resolvedName,
          ),
        );
      }

      for (final nested in _pickNestedPayloads(value)) {
        results.addAll(
          _extractOptionsRecursively(
            nested,
            idKeys: idKeys,
            nameKeys: nameKeys,
            fromListItem: nested is! Map<String, dynamic>,
          ),
        );
      }

      return results;
    }

    if (value is List) {
      for (final item in value) {
        results.addAll(
          _extractOptionsRecursively(
            item,
            idKeys: idKeys,
            nameKeys: nameKeys,
            fromListItem: true,
          ),
        );
      }
      return results;
    }

    final scalar = value?.toString().trim();
    if (fromListItem && scalar != null && scalar.isNotEmpty) {
      results.add(
        LocationOption(
          id: scalar,
          name: scalar,
        ),
      );
    }

    return results;
  }

  dynamic _extractPrimaryPayload(Map<String, dynamic> response) {
    for (final key in const [
      'data',
      'items',
      'results',
      'records',
      'countries',
      'cities',
      'wards',
    ]) {
      final value = response[key];
      if (value is List || value is Map<String, dynamic>) {
        return value;
      }
    }

    return response;
  }

  Iterable<dynamic> _pickNestedPayloads(Map<String, dynamic> source) sync* {
    for (final key in const [
      'data',
      'items',
      'results',
      'records',
      'countries',
      'cities',
      'wards',
    ]) {
      final value = source[key];
      if (value != null) {
        yield value;
      }
    }
  }

  String? _pickFirstString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
