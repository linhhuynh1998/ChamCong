import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../models/shift_item.dart';
import '../services/company_directory_service.dart';
import '../services/shift_service.dart';

class ShiftFormController extends ChangeNotifier {
  ShiftFormController({
    this.initialItem,
    ShiftService? shiftService,
    CompanyDirectoryService? companyDirectoryService,
  })  : _shiftService = shiftService ?? ShiftService(),
        _companyDirectoryService =
            companyDirectoryService ?? CompanyDirectoryService(),
        nameController = TextEditingController(text: initialItem?.name ?? ''),
        startHourController = TextEditingController(
          text: initialItem?.startHour ?? '',
        ),
        startMinuteController = TextEditingController(
          text: initialItem?.startMinute ?? '',
        ),
        endHourController = TextEditingController(
          text: initialItem?.endHour ?? '',
        ),
        endMinuteController = TextEditingController(
          text: initialItem?.endMinute ?? '',
        ) {
    _selectedRegionIds = {
      ...initialItem?.regionIds ?? const <String>[],
      if ((initialItem?.regionId ?? '').isNotEmpty) initialItem!.regionId!,
    };
    _selectedRegionNames = {
      if ((initialItem?.regionName ?? '').isNotEmpty) initialItem!.regionName!,
    };
    _selectedBranchIds = {
      ...initialItem?.branchIds ?? const <String>[],
      if ((initialItem?.branchId ?? '').isNotEmpty) initialItem!.branchId!,
    };
    _selectedBranchNames = {
      if ((initialItem?.branchName ?? '').isNotEmpty) initialItem!.branchName!,
    };
    _selectedDepartmentIds = {
      ...initialItem?.departmentIds ?? const <String>[]
    };
    _selectedDepartmentNames = {
      ...initialItem?.departmentNames ?? const <String>[],
    };
    _selectedJobTitleIds = {...initialItem?.jobTitleIds ?? const <String>[]};
    _selectedJobTitleNames = {
      ...initialItem?.jobTitleNames ?? const <String>[],
    };
    _selectedWeekdays = {...initialItem?.weekdays ?? const <int>[]};
    loadLookups();
  }

  final ShiftItem? initialItem;
  final ShiftService _shiftService;
  final CompanyDirectoryService _companyDirectoryService;
  final TextEditingController nameController;
  final TextEditingController startHourController;
  final TextEditingController startMinuteController;
  final TextEditingController endHourController;
  final TextEditingController endMinuteController;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  Set<String> _selectedRegionIds = <String>{};
  Set<String> _selectedRegionNames = <String>{};
  Set<String> _selectedBranchIds = <String>{};
  Set<String> _selectedBranchNames = <String>{};
  Set<String> _selectedDepartmentIds = <String>{};
  Set<String> _selectedDepartmentNames = <String>{};
  Set<String> _selectedJobTitleIds = <String>{};
  Set<String> _selectedJobTitleNames = <String>{};
  Set<int> _selectedWeekdays = <int>{};
  List<CompanyDirectoryItem> _regions = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _branches = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _departments = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _jobTitles = const <CompanyDirectoryItem>[];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isEditing => initialItem != null && initialItem!.id.isNotEmpty;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<CompanyDirectoryItem> get regions => _regions;
  List<CompanyDirectoryItem> get branches => _branches;
  List<CompanyDirectoryItem> get departments => _departments;
  List<CompanyDirectoryItem> get jobTitles => _jobTitles;
  List<String> get selectedRegionIds => _selectedRegionIds.toList();
  List<String> get selectedRegionNames => _selectedRegionNames.toList();
  List<String> get selectedBranchIds => _selectedBranchIds.toList();
  List<String> get selectedBranchNames => _selectedBranchNames.toList();
  List<String> get selectedDepartmentIds => _selectedDepartmentIds.toList();
  List<String> get selectedDepartmentNames => _selectedDepartmentNames.toList();
  List<String> get selectedJobTitleIds => _selectedJobTitleIds.toList();
  List<String> get selectedJobTitleNames => _selectedJobTitleNames.toList();
  List<int> get selectedWeekdays => _selectedWeekdays.toList()..sort();

  Future<void> loadLookups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _companyDirectoryService.listItems('/company/regions'),
        _companyDirectoryService.listItems('/company/branches'),
        _companyDirectoryService.listItems('/company/departments'),
        _companyDirectoryService.listItems('/company/job-titles'),
        if (isEditing) _shiftService.fetchShiftDetail(initialItem!.id),
      ]);

      _regions =
          (results[0] as List).whereType<CompanyDirectoryItem>().toList();
      _branches =
          (results[1] as List).whereType<CompanyDirectoryItem>().toList();
      _departments =
          (results[2] as List).whereType<CompanyDirectoryItem>().toList();
      _jobTitles =
          (results[3] as List).whereType<CompanyDirectoryItem>().toList();

      final detail = results.length > 4 ? results[4] as ShiftItem? : null;
      if (detail != null) {
        _applyShiftDetail(detail);
      }

      _selectedRegionIds = _resolveIdsByNames(
        _regions,
        _selectedRegionIds,
        _selectedRegionNames,
      );
      _selectedRegionNames = _resolveNamesByIds(
        _regions,
        _selectedRegionIds,
        _selectedRegionNames,
      );
      _selectedBranchIds = _resolveIdsByNames(
        _branches,
        _selectedBranchIds,
        _selectedBranchNames,
      );
      _selectedBranchNames = _resolveNamesByIds(
        _branches,
        _selectedBranchIds,
        _selectedBranchNames,
      );
      _selectedDepartmentIds = _resolveIdsByNames(
        _departments,
        _selectedDepartmentIds,
        _selectedDepartmentNames,
      );
      _selectedDepartmentNames = _resolveNamesByIds(
        _departments,
        _selectedDepartmentIds,
        _selectedDepartmentNames,
      );
      _selectedJobTitleIds = _resolveIdsByNames(
        _jobTitles,
        _selectedJobTitleIds,
        _selectedJobTitleNames,
      );
      _selectedJobTitleNames = _resolveNamesByIds(
        _jobTitles,
        _selectedJobTitleIds,
        _selectedJobTitleNames,
      );
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu xếp ca.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyShiftDetail(ShiftItem detail) {
    if (detail.name.trim().isNotEmpty) {
      nameController.text = detail.name;
    }
    if (detail.startHour.trim().isNotEmpty) {
      startHourController.text = detail.startHour;
    }
    if (detail.startMinute.trim().isNotEmpty) {
      startMinuteController.text = detail.startMinute;
    }
    if (detail.endHour.trim().isNotEmpty) {
      endHourController.text = detail.endHour;
    }
    if (detail.endMinute.trim().isNotEmpty) {
      endMinuteController.text = detail.endMinute;
    }
    if (detail.regionIds.isNotEmpty) {
      _selectedRegionIds = detail.regionIds.toSet();
    } else if ((detail.regionId ?? '').trim().isNotEmpty) {
      _selectedRegionIds = {detail.regionId!.trim()};
    }
    if ((detail.regionName ?? '').trim().isNotEmpty) {
      _selectedRegionNames = {detail.regionName!.trim()};
    }
    if (detail.branchIds.isNotEmpty) {
      _selectedBranchIds = detail.branchIds.toSet();
    } else if ((detail.branchId ?? '').trim().isNotEmpty) {
      _selectedBranchIds = {detail.branchId!.trim()};
    }
    if ((detail.branchName ?? '').trim().isNotEmpty) {
      _selectedBranchNames = {detail.branchName!.trim()};
    }
    if (detail.departmentIds.isNotEmpty) {
      _selectedDepartmentIds = detail.departmentIds.toSet();
    }
    if (detail.departmentNames.isNotEmpty) {
      _selectedDepartmentNames = detail.departmentNames.toSet();
    }
    if (detail.jobTitleIds.isNotEmpty) {
      _selectedJobTitleIds = detail.jobTitleIds.toSet();
    }
    if (detail.jobTitleNames.isNotEmpty) {
      _selectedJobTitleNames = detail.jobTitleNames.toSet();
    }
    if (detail.weekdays.isNotEmpty) {
      _selectedWeekdays = detail.weekdays.toSet();
    }
  }

  void replaceSelectedRegions(List<CompanyDirectoryItem> items) {
    _selectedRegionIds = items.map((item) => item.id).toSet();
    _selectedRegionNames = items.map((item) => item.name).toSet();
    notifyListeners();
  }

  void replaceSelectedBranches(List<CompanyDirectoryItem> items) {
    _selectedBranchIds = items.map((item) => item.id).toSet();
    _selectedBranchNames = items.map((item) => item.name).toSet();
    notifyListeners();
  }

  void replaceSelectedDepartments(List<CompanyDirectoryItem> items) {
    _selectedDepartmentIds = items.map((item) => item.id).toSet();
    _selectedDepartmentNames = items.map((item) => item.name).toSet();
    notifyListeners();
  }

  void replaceSelectedJobTitles(List<CompanyDirectoryItem> items) {
    _selectedJobTitleIds = items.map((item) => item.id).toSet();
    _selectedJobTitleNames = items.map((item) => item.name).toSet();
    notifyListeners();
  }

  void toggleWeekday(int weekday) {
    if (_selectedWeekdays.contains(weekday)) {
      _selectedWeekdays.remove(weekday);
    } else {
      _selectedWeekdays.add(weekday);
    }
    notifyListeners();
  }

  Future<String> submit() async {
    final name = nameController.text.trim();
    final startHour = _normalizeTimePart(startHourController.text);
    final startMinute = _normalizeTimePart(startMinuteController.text);
    final endHour = _normalizeTimePart(endHourController.text);
    final endMinute = _normalizeTimePart(endMinuteController.text);

    if (name.isEmpty) {
      return _fail('Vui lòng nhập tên ca.');
    }

    if (startHour == null || startMinute == null) {
      return _fail('Vui lòng nhập giờ bắt đầu hợp lệ.');
    }

    if (endHour == null || endMinute == null) {
      return _fail('Vui lòng nhập giờ kết thúc hợp lệ.');
    }

    if (_selectedRegionIds.isEmpty) {
      return _fail('Vui lòng chọn ít nhất một vùng.');
    }

    if (_selectedBranchIds.isEmpty) {
      return _fail('Vui lòng chọn ít nhất một chi nhánh.');
    }

    if (_selectedDepartmentIds.isEmpty) {
      return _fail('Vui lòng chọn ít nhất một phòng ban.');
    }

    if (_selectedJobTitleIds.isEmpty) {
      return _fail('Vui lòng chọn ít nhất một chức vụ.');
    }

    if (_selectedWeekdays.isEmpty) {
      return _fail('Vui lòng chọn ít nhất một ngày làm việc.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final message = isEditing
          ? await _shiftService.updateShift(
              id: initialItem!.id,
              name: name,
              startHour: startHour,
              startMinute: startMinute,
              endHour: endHour,
              endMinute: endMinute,
              regionId: selectedRegionIds.first,
              branchId: selectedBranchIds.first,
              departmentIds: selectedDepartmentIds,
              jobTitleIds: selectedJobTitleIds,
              weekdays: selectedWeekdays,
            )
          : await _shiftService.createShift(
              name: name,
              startHour: startHour,
              startMinute: startMinute,
              endHour: endHour,
              endMinute: endMinute,
              regionId: selectedRegionIds.first,
              branchId: selectedBranchIds.first,
              departmentIds: selectedDepartmentIds,
              jobTitleIds: selectedJobTitleIds,
              weekdays: selectedWeekdays,
            );

      _lastActionSucceeded = true;
      _statusMessage = message;
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      return _fail('Không thể lưu xếp ca. Vui lòng thử lại.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Set<String> _resolveNamesByIds(
    List<CompanyDirectoryItem> items,
    Set<String> ids,
    Set<String> fallback,
  ) {
    final names = items
        .where((item) => ids.contains(item.id))
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet();
    return names.isEmpty ? fallback : names;
  }

  Set<String> _resolveIdsByNames(
    List<CompanyDirectoryItem> items,
    Set<String> currentIds,
    Set<String> names,
  ) {
    if (currentIds.isNotEmpty || names.isEmpty) {
      return currentIds;
    }

    final normalizedNames =
        names.map((name) => name.trim().toLowerCase()).toSet();
    return items
        .where(
          (item) => normalizedNames.contains(item.name.trim().toLowerCase()),
        )
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
  }

  String? _normalizeTimePart(String input) {
    final value = int.tryParse(input.trim());
    if (value == null) {
      return null;
    }
    return value.toString().padLeft(2, '0');
  }

  String _fail(String message) {
    _lastActionSucceeded = false;
    _statusMessage = message;
    notifyListeners();
    return message;
  }

  @override
  void dispose() {
    nameController.dispose();
    startHourController.dispose();
    startMinuteController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();
    super.dispose();
  }
}
