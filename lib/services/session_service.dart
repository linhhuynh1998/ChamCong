import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _profileCacheKey = 'employee_profile_cache';
  static const String _profileCacheAtKey = 'employee_profile_cache_at';
  static final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();
  String? _cachedToken;
  bool _hasLoadedToken = false;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _hasLoadedToken = true;
    final prefs = await _prefsFuture;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    if (_hasLoadedToken) {
      return _cachedToken;
    }

    final prefs = await _prefsFuture;
    _cachedToken = prefs.getString(_tokenKey);
    _hasLoadedToken = true;
    return _cachedToken;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _hasLoadedToken = true;
    final prefs = await _prefsFuture;
    await prefs.remove(_tokenKey);
  }

  Future<void> saveProfileCache(Map<String, dynamic> profileJson) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_profileCacheKey, jsonEncode(profileJson));
    await prefs.setString(
      _profileCacheAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<({Map<String, dynamic>? profileJson, DateTime? cachedAt})>
      getProfileCache() async {
    final prefs = await _prefsFuture;
    final rawProfile = prefs.getString(_profileCacheKey);
    final rawCachedAt = prefs.getString(_profileCacheAtKey);

    Map<String, dynamic>? profileJson;
    if (rawProfile != null && rawProfile.isNotEmpty) {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map<String, dynamic>) {
        profileJson = decoded;
      }
    }

    final cachedAt = rawCachedAt == null ? null : DateTime.tryParse(rawCachedAt);
    return (profileJson: profileJson, cachedAt: cachedAt);
  }

  Future<void> clearProfileCache() async {
    final prefs = await _prefsFuture;
    await prefs.remove(_profileCacheKey);
    await prefs.remove(_profileCacheAtKey);
  }
}
