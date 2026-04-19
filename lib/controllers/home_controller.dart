import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AuthService? authService,
    AttendanceService? attendanceService,
  })  : _authService = authService ?? AuthService(),
        _attendanceService = attendanceService ?? AttendanceService() {
    loadProfile();
  }

  final AuthService _authService;
  final AttendanceService _attendanceService;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _employeeName = 'Nhân viên';
  String _employeeEmail = '';
  String _statusMessage = 'Đang tải thông tin chấm công...';

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get employeeName => _employeeName;
  String get employeeEmail => _employeeEmail;
  String get statusMessage => _statusMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _authService.me();
      _employeeName = profile.name;
      _employeeEmail = profile.email;
      _lastActionSucceeded = true;
      _statusMessage = 'Sẵn sàng chấm công cho hôm nay.';
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

  Future<String> checkIn() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final message = await _attendanceService.checkIn();
      _lastActionSucceeded = true;
      _statusMessage = message;
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      const message = 'Chấm công thất bại. Vui lòng thử lại.';
      _lastActionSucceeded = false;
      _statusMessage = message;
      return message;
    } finally {
      _isSubmitting = false;
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
}
