import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/region_item.dart';
import 'session_service.dart';

class RegionService {
  RegionService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<RegionItem>> listRegions() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/regions',
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
        .map(RegionItem.fromJson)
        .toList();
  }

  Future<RegionItem> getRegionDetail(String id) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/regions/$id',
      headers: _buildAuthHeaders(token),
    );

    return RegionItem.fromJson(response);
  }

  Future<String> createRegion({
    required String name,
    String? note,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      '/regions',
      headers: _buildAuthHeaders(token),
      body: <String, dynamic>{
        'name': name.trim(),
        'note': note?.trim() ?? '',
        'description': note?.trim() ?? '',
      },
      formUrlEncoded: true,
    );

    debugPrint('[REGION CREATE RESPONSE] $response');

    return response['message']?.toString() ??
        response['msg']?.toString() ??
        'T?o vùng thành công.';
  }

  Future<String> updateRegion({
    required String id,
    required String name,
    String? note,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      '/regions/$id',
      headers: _buildAuthHeaders(token),
      body: <String, dynamic>{
        '_method': 'PUT',
        'name': name.trim(),
        'note': note?.trim() ?? '',
        'description': note?.trim() ?? '',
      },
      formUrlEncoded: true,
    );

    debugPrint('[REGION UPDATE RESPONSE] $response');

    return response['message']?.toString() ??
        response['msg']?.toString() ??
        'C?p nh?t vùng thành công.';
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
