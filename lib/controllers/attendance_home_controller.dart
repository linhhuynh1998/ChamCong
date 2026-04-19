import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/attendance_day_record.dart';
import '../models/location_snapshot.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class AttendanceHomeController extends ChangeNotifier {
  AttendanceHomeController({
    AuthService? authService,
    AttendanceService? attendanceService,
    LocationService? locationService,
  })  : _authService = authService ?? AuthService(),
        _attendanceService = attendanceService ?? AttendanceService(),
        _locationService = locationService ?? LocationService() {
    loadProfile();
  }

  final AuthService _authService;
  final AttendanceService _attendanceService;
  final LocationService _locationService;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _employeeName = 'Nhân Viên';
  String _employeeEmail = '';
  String _employeeId = '';
  String _statusMessage = 'Đang tải thông tin chấm công...';
  String _companyAddress = '';
  double? _companyLatitude;
  double? _companyLongitude;
  double _companyRadiusKm = 0.3;
  LocationSnapshot? _locationSnapshot;
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;
  String? _attendanceLogId;
  Map<DateTime, AttendanceDayRecord> _attendanceHistory =
      <DateTime, AttendanceDayRecord>{};

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get employeeName => _employeeName;
  String get employeeEmail => _employeeEmail;
  String get employeeId => _employeeId;
  String get statusMessage => _statusMessage;
  String get companyAddress => _companyAddress;
  double get companyRadiusKm => _companyRadiusKm;
  LocationSnapshot? get locationSnapshot => _locationSnapshot;
  bool get hasCheckedInToday => _hasCheckedInToday;
  bool get hasCheckedOutToday => _hasCheckedOutToday;
  Map<DateTime, AttendanceDayRecord> get attendanceHistory => _attendanceHistory;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _authService.me();
      _employeeId = profile.id;
      _employeeName = profile.name;
      _employeeEmail = profile.email;
      _companyAddress = profile.companyAddress;
      _companyLatitude = profile.companyLatitude;
      _companyLongitude = profile.companyLongitude;
      _companyRadiusKm = profile.companyRadiusKm;
      await Future.wait(<Future<void>>[
        _loadAttendanceHistory(),
        _refreshLocationSilently(),
      ]);
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

  Future<void> _refreshLocationSilently() async {
    try {
      await refreshLocation(silent: true);
    } on ApiException {
      rethrow;
    } catch (_) {
      // Keep startup smooth when location is slower than the rest of the data.
    }
  }

  Future<void> refreshLocation({bool silent = false}) async {
    if (!silent) {
      _isSubmitting = true;
      notifyListeners();
    }

    try {
      final companyLatitude = _companyLatitude;
      final companyLongitude = _companyLongitude;
      if (companyLatitude == null || companyLongitude == null) {
        throw ApiException('API chưa trả về tọa độ công ty.');
      }

      _locationSnapshot = await _fetchLocationSnapshot(
        allowCached: silent,
      );
      _lastActionSucceeded = true;
      _statusMessage =
          'Bạn đang cách công ty ${_locationSnapshot!.distanceKm.toStringAsFixed(2)} km.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không thể lấy vị trí hiện tại.';
    } finally {
      if (!silent) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  Future<String> checkIn() async {
    return submitCheckIn();
  }

  Future<String> submitCheckIn({
    String? reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final companyLatitude = _companyLatitude;
      final companyLongitude = _companyLongitude;
      if (companyLatitude == null || companyLongitude == null) {
        throw ApiException('API chưa trả về tọa độ công ty.');
      }

      _locationSnapshot = await _fetchLocationSnapshot();
      final checkedAt = DateTime.now().toIso8601String();
      final message = await _attendanceService.checkIn(
        body: _buildAttendanceBody(
          snapshot: _locationSnapshot!,
          reason: reason,
          isCheckout: false,
        ),
      );
      _lastActionSucceeded = true;
      _hasCheckedInToday = true;
      _hasCheckedOutToday = false;
      _upsertTodayAttendance(checkInTime: checkedAt, checkOutTime: null);
      _statusMessage =
          '$message Khoảng cách hiện tại: ${_locationSnapshot!.distanceKm.toStringAsFixed(2)} km.';
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

  Future<String> submitCheckOut({
    String? reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final companyLatitude = _companyLatitude;
      final companyLongitude = _companyLongitude;
      if (companyLatitude == null || companyLongitude == null) {
        throw ApiException('API chưa trả về tọa độ công ty.');
      }

      _locationSnapshot = await _fetchLocationSnapshot();
      final checkedAt = DateTime.now().toIso8601String();
      final message = await _attendanceService.checkOut(
        body: _buildAttendanceBody(
          snapshot: _locationSnapshot!,
          reason: reason,
          isCheckout: true,
        ),
      );
      _lastActionSucceeded = true;
      _hasCheckedOutToday = true;
      _upsertTodayAttendance(checkInTime: null, checkOutTime: checkedAt);
      _statusMessage =
          '$message Khoảng cách hiện tại: ${_locationSnapshot!.distanceKm.toStringAsFixed(2)} km.';
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      const message = 'Rời ca thất bại. Vui lòng thử lại.';
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

  Map<String, dynamic> _buildAttendanceBody({
    required LocationSnapshot snapshot,
    required bool isCheckout,
    String? reason,
  }) {
    final actionAt = DateTime.now();
    final checkedAt = actionAt.toIso8601String();
    final workDate = _formatWorkDate(actionAt);
    final distanceKm = double.parse(snapshot.distanceKm.toStringAsFixed(3));
    final normalizedReason = reason?.trim();

    return <String, dynamic>{
      'attendance_log_id': _attendanceLogId ?? '',
      'employee_id': _employeeId,
      'work_date': workDate,
      'location': snapshot.currentAddress,
      'latitude': snapshot.latitude,
      'longitude': snapshot.longitude,
      'lat': snapshot.latitude,
      'lng': snapshot.longitude,
      'accuracy': snapshot.accuracy.toStringAsFixed(0),
      'current_latitude': snapshot.latitude,
      'current_longitude': snapshot.longitude,
      'current_address': snapshot.currentAddress,
      'address': snapshot.currentAddress,
      'company_latitude': snapshot.companyLatitude,
      'company_longitude': snapshot.companyLongitude,
      'company_address': snapshot.companyAddress,
      'distance_km': distanceKm,
      'distance': distanceKm,
      'allowed_radius_km': _companyRadiusKm,
      'radius_km': _companyRadiusKm,
      'is_within_allowed_radius': snapshot.isWithinAllowedRadius,
      'inside_radius': snapshot.isWithinAllowedRadius,
      'checkin_time': isCheckout ? '' : checkedAt,
      'checkout_time': isCheckout ? checkedAt : '',
      'checked_at': checkedAt,
      'reason': normalizedReason ?? '',
      'late_reason': isCheckout ? '' : (normalizedReason ?? ''),
      'checkout_reason': isCheckout ? (normalizedReason ?? '') : '',
      'early_checkout_reason': isCheckout ? (normalizedReason ?? '') : '',
      'source': 'mobile_app',
      'platform': 'flutter',
    };
  }

  String _formatWorkDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  Future<LocationSnapshot> _fetchLocationSnapshot({
    bool allowCached = true,
  }) {
    return _locationService.getLocationSnapshot(
      companyLatitude: _companyLatitude!,
      companyLongitude: _companyLongitude!,
      allowedRadiusKm: _companyRadiusKm,
      companyAddress: _companyAddress,
      allowCached: allowCached,
    );
  }

  Future<void> _loadAttendanceHistory() async {
    final records = await _attendanceService.listAttendance();
    _attendanceHistory = <DateTime, AttendanceDayRecord>{
      for (final record in records) record.workDate: record,
    };

    final today = _normalizeDate(DateTime.now());
    final todayRecord = _attendanceHistory[today];
    if (todayRecord != null) {
      _attendanceLogId = todayRecord.id.isEmpty ? _attendanceLogId : todayRecord.id;
      _hasCheckedInToday = todayRecord.hasCheckedIn;
      _hasCheckedOutToday = todayRecord.hasCheckedOut;
    }
  }

  void _upsertTodayAttendance({
    String? checkInTime,
    String? checkOutTime,
  }) {
    final today = _normalizeDate(DateTime.now());
    final current = _attendanceHistory[today];
    _attendanceHistory = <DateTime, AttendanceDayRecord>{
      ..._attendanceHistory,
      today: AttendanceDayRecord(
        id: current?.id ?? _attendanceLogId ?? '',
        workDate: today,
        checkInTime: checkInTime ?? current?.checkInTime,
        checkOutTime: checkOutTime ?? current?.checkOutTime,
        location: _locationSnapshot?.currentAddress ?? current?.location ?? '',
        status: current?.status ?? '',
        statusLabel: current?.statusLabel ?? '',
        shiftName: current?.shiftName ?? '',
        shiftStartTime: current?.shiftStartTime,
        shiftEndTime: current?.shiftEndTime,
      ),
    };
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
