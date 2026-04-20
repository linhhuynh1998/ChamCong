import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/employee_list_item.dart';
import '../services/employee_directory_service.dart';

class EmployeeListController extends ChangeNotifier {
  EmployeeListController({
    EmployeeDirectoryService? service,
  }) : _service = service ?? EmployeeDirectoryService() {
    searchController.addListener(_handleQueryChanged);
    loadEmployees();
  }

  final EmployeeDirectoryService _service;
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  List<EmployeeListItem> _allEmployees = const <EmployeeListItem>[];
  List<EmployeeListItem> _visibleEmployees = const <EmployeeListItem>[];

  bool get isLoading => _isLoading;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<EmployeeListItem> get visibleEmployees => _visibleEmployees;

  Future<void> loadEmployees() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allEmployees = await _service.listEmployees();
      _lastActionSucceeded = true;
      _statusMessage = 'Tải danh sách nhân viên thành công.';
      _applyFilter();
    } on ApiException catch (error) {
      _allEmployees = const <EmployeeListItem>[];
      _visibleEmployees = const <EmployeeListItem>[];
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _allEmployees = const <EmployeeListItem>[];
      _visibleEmployees = const <EmployeeListItem>[];
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được danh sách nhân viên.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleQueryChanged() {
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final query = searchController.text;
    _visibleEmployees = _allEmployees
        .where((employee) => employee.matchesQuery(query))
        .toList();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }
}
