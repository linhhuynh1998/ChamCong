import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_exception.dart';
import '../models/location_snapshot.dart';

class LocationService {
  static const double _maxAcceptedAccuracyMeters = 100;
  static const Duration _snapshotCacheTtl = Duration(seconds: 20);

  LocationSnapshot? _cachedSnapshot;
  DateTime? _cachedSnapshotAt;
  String? _cachedSnapshotKey;

  Future<LocationSnapshot> getLocationSnapshot({
    required double companyLatitude,
    required double companyLongitude,
    required double allowedRadiusKm,
    String companyAddress = '',
    bool allowCached = true,
  }) async {
    if (companyLatitude == 0 && companyLongitude == 0) {
      throw ApiException('Toa do cong ty khong hop le.');
    }

    final cacheKey = [
      companyLatitude,
      companyLongitude,
      allowedRadiusKm,
      companyAddress,
    ].join('|');
    final now = DateTime.now();
    if (allowCached &&
        _cachedSnapshot != null &&
        _cachedSnapshotAt != null &&
        _cachedSnapshotKey == cacheKey &&
        now.difference(_cachedSnapshotAt!) <= _snapshotCacheTtl) {
      return _cachedSnapshot!;
    }

    final permission = await _ensurePermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException('Ung dung chua duoc cap quyen vi tri.');
    }

    await _ensurePreciseLocationIfNeeded();

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: _buildLocationSettings(),
    );

    if (currentPosition.accuracy > _maxAcceptedAccuracyMeters) {
      throw ApiException(
        'Do chinh xac vi tri hien tai qua thap (${currentPosition.accuracy.toStringAsFixed(0)} m). '
        'Vui long bat GPS, di chuyen ra khu vuc thong thoang va thu lai.',
      );
    }

    final currentAddress = await _resolveCurrentAddress(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final distanceMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      companyLatitude,
      companyLongitude,
    );

    final distanceKm = distanceMeters / 1000;

    final snapshot = LocationSnapshot(
      companyAddress: companyAddress,
      currentAddress: currentAddress,
      distanceKm: distanceKm,
      isWithinAllowedRadius: distanceKm <= allowedRadiusKm,
      accuracy: currentPosition.accuracy,
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      companyLatitude: companyLatitude,
      companyLongitude: companyLongitude,
    );

    _cachedSnapshot = snapshot;
    _cachedSnapshotAt = now;
    _cachedSnapshotKey = cacheKey;

    return snapshot;
  }

  Future<LocationPermission> _ensurePermission() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw ApiException('Dich vu vi tri dang tat. Vui long bat GPS de tiep tuc.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  Future<void> _ensurePreciseLocationIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final accuracyStatus = await Geolocator.getLocationAccuracy();
    if (accuracyStatus == LocationAccuracyStatus.reduced) {
      throw ApiException(
        'Android đang cấp quyền vị trí xấp xỉ. Vui lòng vào phần quyền ứng dụng và bật “Vị trí chính xác” để cập nhật đúng vị trí.',
      );
    }
  }

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.best,
    );
  }

  Future<String> _resolveCurrentAddress(double latitude, double longitude) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isEmpty) {
      return 'Không xác định được địa chỉ hiện tại.';
    }

    final placemark = placemarks.first;
    final parts = <String?>[
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    if (parts.isEmpty) {
      return 'Không xác định được địa chỉ hiện tại.';
    }

    return parts.join(', ');
  }
}
