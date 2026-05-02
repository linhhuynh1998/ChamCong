import '../core/network/api_client.dart';
import '../models/employee_profile.dart';
import '../models/login_response.dart';
import 'session_service.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;
  EmployeeProfile? _cachedProfile;
  DateTime? _cachedProfileAt;

  static const Duration _profileCacheTtl = Duration(hours: 2);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
      formUrlEncoded: true,
    );

    final loginResponse = LoginResponse.fromJson(response);

    if (loginResponse.token case final token?) {
      await _sessionService.saveToken(token);
    }

    _cachedProfile = null;
    _cachedProfileAt = null;
    await _sessionService.clearProfileCache();

    return loginResponse;
  }

  Future<EmployeeProfile> me({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedProfileAt != null &&
        DateTime.now().difference(_cachedProfileAt!) < _profileCacheTtl) {
      return _cachedProfile!;
    }

    if (!forceRefresh) {
      final cached = await _sessionService.getProfileCache();
      if (cached.profileJson != null &&
          cached.cachedAt != null &&
          DateTime.now().difference(cached.cachedAt!) < _profileCacheTtl) {
        final profile = EmployeeProfile.fromJson(cached.profileJson!);
        _cachedProfile = profile;
        _cachedProfileAt = cached.cachedAt;
        return profile;
      }
    }

    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/auth/me',
      headers: _buildAuthHeaders(token),
    );

    final profile = EmployeeProfile.fromJson(response);
    _cachedProfile = profile;
    _cachedProfileAt = DateTime.now();
    await _sessionService.saveProfileCache(profile.toJson());

    return profile;
  }

  Future<void> logout() async {
    final token = await _sessionService.getToken();

    try {
      if (token != null && token.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          headers: _buildAuthHeaders(token),
        );
      }
    } finally {
      _cachedProfile = null;
      _cachedProfileAt = null;
      await _sessionService.clearProfileCache();
      await _sessionService.clearToken();
    }
  }

  Future<void> refreshAppState() async {
    _cachedProfile = null;
    _cachedProfileAt = null;
    await _sessionService.clearProfileCache();
  }

  Future<String?> getSavedToken() {
    return _sessionService.getToken();
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
