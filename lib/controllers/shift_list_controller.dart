import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/shift_item.dart';
import '../services/shift_service.dart';

class ShiftListController extends ChangeNotifier {
  ShiftListController({
    ShiftService? shiftService,
  }) : _shiftService = shiftService ?? ShiftService() {
    loadShifts();
  }

  final ShiftService _shiftService;

  bool _isLoading = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  List<ShiftItem> _items = const <ShiftItem>[];

  bool get isLoading => _isLoading;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<ShiftItem> get items => _items;

  Future<void> loadShifts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _shiftService.listShifts();
      _lastActionSucceeded = true;
      _statusMessage = 'Tải danh sách ca thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được danh sách ca.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
