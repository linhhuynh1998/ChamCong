import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../services/company_directory_service.dart';

class CompanyDirectoryListController extends ChangeNotifier {
  CompanyDirectoryListController({
    required this.endpoint,
    CompanyDirectoryService? service,
  }) : _service = service ?? CompanyDirectoryService() {
    loadItems();
  }

  final String endpoint;
  final CompanyDirectoryService _service;

  bool _isLoading = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  List<CompanyDirectoryItem> _items = const <CompanyDirectoryItem>[];

  bool get isLoading => _isLoading;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<CompanyDirectoryItem> get items => _items;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _service.listItems(endpoint);
      _lastActionSucceeded = true;
      _statusMessage = 'Tải danh sách thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
