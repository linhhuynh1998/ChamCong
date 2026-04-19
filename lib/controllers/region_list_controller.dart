import 'package:flutter/material.dart';
import 'package:b2msr/services/region_service.dart';

import '../core/network/api_exception.dart';
import '../models/region_item.dart';

class RegionListController extends ChangeNotifier {
  RegionListController({
    RegionService? regionService,
  }) : _regionService = regionService ?? RegionService() {
    loadRegions();
  }

  final RegionService _regionService;

  bool _isLoading = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  List<RegionItem> _regions = const <RegionItem>[];

  bool get isLoading => _isLoading;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<RegionItem> get regions => _regions;

  Future<void> loadRegions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _regions = await _regionService.listRegions();
      _lastActionSucceeded = true;
      _statusMessage = 'Tải danh sách vùng thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được danh sách vùng.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
