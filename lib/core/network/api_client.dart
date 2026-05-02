import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session_handler.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formUrlEncoded = false,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      formUrlEncoded: formUrlEncoded,
    );
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formUrlEncoded = false,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      formUrlEncoded: formUrlEncoded,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formUrlEncoded = false,
  }) async {
    final uri = Uri.parse(
      '$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}',
    ).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': formUrlEncoded
          ? 'application/x-www-form-urlencoded'
          : 'application/json',
      ...?headers,
    };
    final requestBody = formUrlEncoded
        ? _encodeFormBody(body ?? <String, dynamic>{})
        : jsonEncode(body ?? <String, dynamic>{});

    _debugLogRequest(
      method: method,
      uri: uri,
      headers: requestHeaders,
      body: requestBody,
    );

    late final http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: requestHeaders)
              .timeout(ApiConfig.connectTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: requestHeaders,
                body: requestBody,
              )
              .timeout(ApiConfig.connectTimeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(
                uri,
                headers: requestHeaders,
                body: requestBody,
              )
              .timeout(ApiConfig.connectTimeout);
          break;
        default:
          throw ApiException('Method $method is not supported.');
      }
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException('Đường dẫn API không hợp lệ.');
    } on http.ClientException catch (error) {
      throw ApiException('Không thể kết nối tới máy chủ: ${error.message}');
    } on Exception {
      throw ApiException('Kết nối API thất bại. Vui lòng thử lại.');
    }

    _debugLogResponse(
      method: method,
      uri: uri,
      response: response,
    );

    return _handleResponse(
      response,
      hasAuthorizationHeader: requestHeaders.containsKey('Authorization'),
    );
  }

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    required bool hasAuthorizationHeader,
  }) {
    final responseBody = utf8.decode(response.bodyBytes).trim();

    Map<String, dynamic> decodedBody = <String, dynamic>{};
    if (responseBody.isNotEmpty) {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        decodedBody = decoded;
      } else {
        decodedBody = <String, dynamic>{'data': decoded};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final message = _buildErrorMessage(decodedBody) ??
        decodedBody['message']?.toString() ??
        decodedBody['error']?.toString() ??
        'Yêu cầu thất bại.';

    if (response.statusCode == 401 && hasAuthorizationHeader) {
      AuthSessionHandler.handleUnauthorized(
        message: message.isNotEmpty
            ? message
            : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  void _debugLogRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Object? body,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[API REQUEST] $method $uri');
    debugPrint('[API REQUEST HEADERS] ${_sanitizeHeaders(headers)}');
    if (body != null) {
      debugPrint('[API REQUEST BODY] $body');
    }
  }

  void _debugLogResponse({
    required String method,
    required Uri uri,
    required http.Response response,
  }) {
    if (!kDebugMode) {
      return;
    }

    final responseBody = utf8.decode(response.bodyBytes);
    debugPrint('[API RESPONSE] $method $uri');
    debugPrint('[API RESPONSE STATUS] ${response.statusCode}');
    debugPrint('[API RESPONSE BODY] $responseBody');
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = <String, String>{...headers};
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer ***';
    }
    return sanitized;
  }

  String? _buildErrorMessage(Map<String, dynamic> decodedBody) {
    final baseMessage = decodedBody['message']?.toString().trim() ?? '';
    final errors = decodedBody['errors'];
    if (errors is! Map) {
      return baseMessage.isEmpty ? null : baseMessage;
    }

    final detailMessages = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            detailMessages.add(text);
          }
        }
        continue;
      }

      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        detailMessages.add(text);
      }
    }

    if (detailMessages.isEmpty) {
      return baseMessage.isEmpty ? null : baseMessage;
    }

    if (baseMessage.isEmpty) {
      return detailMessages.join('\n');
    }

    return '$baseMessage\n${detailMessages.join('\n')}';
  }

  String _encodeFormBody(Map<String, dynamic> body) {
    final segments = <String>[];

    body.forEach((key, value) {
      if (value == null) {
        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            segments.add(
              '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(text)}',
            );
          }
        }
        return;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        segments.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(text)}',
        );
      }
    });

    return segments.join('&');
  }
}
