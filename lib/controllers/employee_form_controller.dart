import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../models/employee_list_item.dart';
import '../models/location_option.dart';
import '../services/company_directory_service.dart';
import '../services/employee_directory_service.dart';

class EmployeeFormController extends ChangeNotifier {
  EmployeeFormController({
    this.initialEmployee,
    EmployeeDirectoryService? employeeService,
    CompanyDirectoryService? companyService,
  })  : _employeeService = employeeService ?? EmployeeDirectoryService(),
        _companyService = companyService ?? CompanyDirectoryService(),
        nameController = TextEditingController(
          text: initialEmployee?.name ?? '',
        ),
        phoneController = TextEditingController(
          text: initialEmployee?.phone ?? '',
        ),
        emailController = TextEditingController(
          text: initialEmployee?.email ?? '',
        ),
        employeeCodeController = TextEditingController(
          text: initialEmployee?.employeeCode ?? '',
        ),
        birthDateController = TextEditingController(
          text: initialEmployee?.birthDate ?? '',
        ),
        addressController = TextEditingController(
          text: initialEmployee?.address ?? '',
        ) {
    _selectedAccessRoleId = _resolveInitialAccessRoleId(
      initialEmployee?.accessRole ?? '',
    );
    _selectedAccessRoleName = _resolveAccessRoleName(
      initialEmployee?.accessRole ?? '',
    );
    _selectedRegionId = initialEmployee?.regionId ?? '';
    _selectedRegionName = initialEmployee?.regionName ?? '';
    _selectedBranchId = initialEmployee?.branchId ?? '';
    _selectedBranchName = initialEmployee?.branchName ?? '';
    _selectedDepartmentId = initialEmployee?.departmentId ?? '';
    _selectedDepartmentName = initialEmployee?.department ?? '';
    _selectedJobTitleId = initialEmployee?.jobTitleId ?? '';
    _selectedJobTitleName = initialEmployee?.jobTitle ?? '';
    _bootstrap();
  }

  final EmployeeListItem? initialEmployee;
  final EmployeeDirectoryService _employeeService;
  final CompanyDirectoryService _companyService;

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController employeeCodeController;
  final TextEditingController birthDateController;
  final TextEditingController addressController;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  List<CompanyDirectoryItem> _regions = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _branches = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _departments = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _jobTitles = const <CompanyDirectoryItem>[];
  String _selectedAccessRoleId = '';
  String _selectedAccessRoleName = '';
  String _selectedRegionId = '';
  String _selectedRegionName = '';
  String _selectedBranchId = '';
  String _selectedBranchName = '';
  String _selectedDepartmentId = '';
  String _selectedDepartmentName = '';
  String _selectedJobTitleId = '';
  String _selectedJobTitleName = '';

  static const List<LocationOption> accessRoles = <LocationOption>[
    LocationOption(id: 'manager', name: 'Quản lý'),
    LocationOption(id: 'member', name: 'Nhân viên'),
  ];

  bool get isEditing => (initialEmployee?.id ?? '').trim().isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  String get statusMessage => _statusMessage;
  List<CompanyDirectoryItem> get regions => _regions;
  List<CompanyDirectoryItem> get branches => _branches;
  List<CompanyDirectoryItem> get departments => _departments;
  List<CompanyDirectoryItem> get jobTitles => _jobTitles;
  String get selectedAccessRoleName => _selectedAccessRoleName;
  String get selectedRegionName => _selectedRegionName;
  String get selectedBranchName => _selectedBranchName;
  String get selectedDepartmentName => _selectedDepartmentName;
  String get selectedJobTitleName => _selectedJobTitleName;

  Future<void> _bootstrap() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait(<Future<void>>[
        _loadRegions(),
        _loadBranches(),
        _loadDepartments(),
        _loadJobTitles(),
      ]);

      if (isEditing) {
        final detail =
            await _employeeService.fetchEmployee(initialEmployee!.id);
        if (detail != null) {
          _applyEmployee(detail);
        }
      }

      _lastActionSucceeded = true;
      _statusMessage = 'Tải thông tin nhân viên thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được thông tin nhân viên.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRegions() async {
    _regions = await _companyService.listItems('/company/regions');
    if (_selectedRegionId.isNotEmpty && _selectedRegionName.isEmpty) {
      _selectedRegionName = _resolveNameById(_regions, _selectedRegionId);
    }
  }

  Future<void> _loadBranches() async {
    _branches = await _companyService.listItems('/company/branches');
    if (_selectedBranchId.isNotEmpty && _selectedBranchName.isEmpty) {
      _selectedBranchName = _resolveNameById(_branches, _selectedBranchId);
    }
  }

  Future<void> _loadDepartments() async {
    _departments = await _companyService.listItems('/company/departments');
    if (_selectedDepartmentId.isNotEmpty && _selectedDepartmentName.isEmpty) {
      _selectedDepartmentName =
          _resolveNameById(_departments, _selectedDepartmentId);
    }
  }

  Future<void> _loadJobTitles() async {
    _jobTitles = await _companyService.listItems('/company/job-titles');
    if (_selectedJobTitleId.isNotEmpty && _selectedJobTitleName.isEmpty) {
      _selectedJobTitleName = _resolveNameById(_jobTitles, _selectedJobTitleId);
    }
  }

  void selectAccessRole(LocationOption option) {
    _selectedAccessRoleId = option.id;
    _selectedAccessRoleName = option.name;
    notifyListeners();
  }

  void setBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    birthDateController.text = '$day-$month-$year';
    notifyListeners();
  }

  void selectRegion(CompanyDirectoryItem item) {
    _selectedRegionId = item.id;
    _selectedRegionName = item.name;
    notifyListeners();
  }

  void selectBranch(CompanyDirectoryItem item) {
    _selectedBranchId = item.id;
    _selectedBranchName = item.name;
    notifyListeners();
  }

  void selectDepartment(CompanyDirectoryItem item) {
    _selectedDepartmentId = item.id;
    _selectedDepartmentName = item.name;
    notifyListeners();
  }

  void selectJobTitle(CompanyDirectoryItem item) {
    _selectedJobTitleId = item.id;
    _selectedJobTitleName = item.name;
    notifyListeners();
  }

  Future<String> submit() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final employeeCode = employeeCodeController.text.trim();

    if (name.isEmpty) {
      return _fail('Vui lòng nhập họ và tên.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final message = isEditing
          ? await _employeeService.updateEmployee(
              initialEmployee!.id,
              name: name,
              phone: phone,
              email: email,
              employeeCode: employeeCode,
              birthDate: birthDateController.text.trim(),
              address: addressController.text.trim(),
              accessRoleId: _selectedAccessRoleId,
              accessRoleName: _selectedAccessRoleName,
              regionId: _selectedRegionId,
              branchId: _selectedBranchId,
              departmentId: _selectedDepartmentId,
              jobTitleId: _selectedJobTitleId,
            )
          : await _employeeService.createEmployee(
              name: name,
              phone: phone,
              email: email,
              employeeCode: employeeCode,
              birthDate: birthDateController.text.trim(),
              address: addressController.text.trim(),
              accessRoleId: _selectedAccessRoleId,
              accessRoleName: _selectedAccessRoleName,
              regionId: _selectedRegionId,
              branchId: _selectedBranchId,
              departmentId: _selectedDepartmentId,
              jobTitleId: _selectedJobTitleId,
            );

      _lastActionSucceeded = true;
      _statusMessage = message;
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      return _fail('Không thể lưu nhân viên. Vui lòng thử lại.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _fail(String message) {
    _lastActionSucceeded = false;
    _statusMessage = message;
    notifyListeners();
    return message;
  }

  void _applyEmployee(EmployeeListItem item) {
    nameController.text = item.name;
    phoneController.text = item.phone;
    emailController.text = item.email;
    employeeCodeController.text = item.employeeCode;
    birthDateController.text = item.birthDate;
    addressController.text = item.address;
    _selectedAccessRoleId = _resolveInitialAccessRoleId(item.accessRole);
    _selectedAccessRoleName = _resolveAccessRoleName(item.accessRole);
    _selectedRegionId = item.regionId;
    _selectedRegionName =
        item.regionName.isNotEmpty ? item.regionName : _selectedRegionName;
    _selectedBranchId = item.branchId;
    _selectedBranchName =
        item.branchName.isNotEmpty ? item.branchName : _selectedBranchName;
    _selectedDepartmentId = item.departmentId;
    _selectedDepartmentName =
        item.department.isNotEmpty ? item.department : _selectedDepartmentName;
    _selectedJobTitleId = item.jobTitleId;
    _selectedJobTitleName =
        item.jobTitle.isNotEmpty ? item.jobTitle : _selectedJobTitleName;
  }

  String _resolveNameById(List<CompanyDirectoryItem> items, String selectedId) {
    for (final item in items) {
      if (item.id == selectedId) {
        return item.name;
      }
    }

    return '';
  }

  String _resolveInitialAccessRoleId(String name) {
    final normalized = name.trim().toLowerCase();
    for (final option in accessRoles) {
      if (option.name.toLowerCase() == normalized ||
          option.id.toLowerCase() == normalized) {
        return option.id;
      }
    }

    if (normalized == 'employee') {
      return 'member';
    }

    return '';
  }

  String _resolveAccessRoleName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    for (final option in accessRoles) {
      if (option.name.toLowerCase() == normalized ||
          option.id.toLowerCase() == normalized) {
        return option.name;
      }
    }

    if (normalized == 'employee' || normalized == 'member') {
      return 'Nhân viên';
    }

    return name;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    employeeCodeController.dispose();
    birthDateController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
