import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/employee_profile.dart';
import '../services/auth_service.dart';

class AccountController extends ChangeNotifier {
  AccountController({
    AuthService? authService,
  }) : _authService = authService ?? AuthService() {
    loadProfile();
  }

  final AuthService _authService;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = 'Đang tải tài khoản...';
  EmployeeProfile? _profile;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  EmployeeProfile? get profile => _profile;

  Future<void> loadProfile({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _authService.me(forceRefresh: forceRefresh);
      _lastActionSucceeded = true;
      _statusMessage = 'Tải thông tin tài khoản thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được thông tin tài khoản.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _authService.logout();
      _lastActionSucceeded = true;
      _statusMessage = 'Đã đăng xuất.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Đăng xuất cục bộ thành công.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refreshApp() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _authService.refreshAppState();
      await loadProfile(forceRefresh: true);
      _lastActionSucceeded = true;
      _statusMessage = 'Đã làm mới ứng dụng.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không thể làm mới ứng dụng.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
