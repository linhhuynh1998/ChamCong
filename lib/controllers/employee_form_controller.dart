import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../models/employee_list_item.dart';
import '../models/location_option.dart';
import '../services/company_directory_service.dart';
import '../services/company_entity_service.dart';
import '../services/employee_directory_service.dart';

class EmployeeFormController extends ChangeNotifier {
  EmployeeFormController({
    this.initialEmployee,
    EmployeeDirectoryService? employeeService,
    CompanyDirectoryService? companyService,
    CompanyEntityService? companyEntityService,
  })  : _employeeService = employeeService ?? EmployeeDirectoryService(),
        _companyService = companyService ?? CompanyDirectoryService(),
        _companyEntityService = companyEntityService ?? CompanyEntityService(),
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
          text: _formatBirthDateForDisplay(initialEmployee?.birthDate ?? ''),
        ),
        addressController = TextEditingController(
          text: initialEmployee?.address ?? '',
        ) {
    _selectedAccessRoleId = (initialEmployee?.accessRoleId ?? '').trim();
    if (_selectedAccessRoleId.isEmpty) {
      _selectedAccessRoleId = _resolveInitialAccessRoleId(
        initialEmployee?.accessRole ?? '',
      );
    }
    _selectedAccessRoleName = _resolveAccessRoleName(
      initialEmployee?.accessRole ?? '',
    );
    _selectedStatusId = _resolveInitialStatusId(initialEmployee?.status ?? '');
    _selectedStatusName = _resolveStatusName(initialEmployee?.status ?? '');
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
  final CompanyEntityService _companyEntityService;

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
  List<LocationOption> _accessRoles = const <LocationOption>[];
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
  String _selectedStatusId = '1';
  String _selectedStatusName = 'Đang làm việc';

  static const List<LocationOption> employeeStatuses = <LocationOption>[
    LocationOption(id: '1', name: 'Đang làm việc'),
    LocationOption(id: '0', name: 'Ngừng làm việc'),
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
  List<LocationOption> get accessRoles => _accessRoles;
  String get selectedAccessRoleName => _selectedAccessRoleName;
  String get selectedRegionName => _selectedRegionName;
  String get selectedBranchName => _selectedBranchName;
  String get selectedDepartmentName => _selectedDepartmentName;
  String get selectedJobTitleName => _selectedJobTitleName;
  String get selectedStatusName => _selectedStatusName;

  Future<void> _bootstrap() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait(<Future<void>>[
        _loadAccessRoles(),
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

  Future<void> _loadAccessRoles() async {
    final entities =
        await _companyEntityService.listEntities('/company/permission-groups');
    _accessRoles = entities
        .where((item) => item.id.trim().isNotEmpty && item.name.trim().isNotEmpty)
        .map(
          (item) => LocationOption(
            id: item.id.trim(),
            name: item.name.trim(),
          ),
        )
        .toList();

    if (_selectedAccessRoleId.isNotEmpty) {
      _selectedAccessRoleName = _resolveAccessRoleName(_selectedAccessRoleId);
    } else if (_selectedAccessRoleName.isNotEmpty) {
      _selectedAccessRoleId = _resolveInitialAccessRoleId(_selectedAccessRoleName);
      _selectedAccessRoleName = _resolveAccessRoleName(_selectedAccessRoleName);
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

  void selectStatus(LocationOption option) {
    _selectedStatusId = option.id;
    _selectedStatusName = option.name;
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
              status: _selectedStatusId,
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
              status: _selectedStatusId,
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
    birthDateController.text = _formatBirthDateForDisplay(item.birthDate);
    addressController.text = item.address;
    _selectedAccessRoleId = item.accessRoleId.trim().isNotEmpty
        ? item.accessRoleId.trim()
        : _resolveInitialAccessRoleId(item.accessRole);
    _selectedAccessRoleName = _selectedAccessRoleId.isNotEmpty
        ? _resolveAccessRoleName(_selectedAccessRoleId)
        : _resolveAccessRoleName(item.accessRole);
    _selectedStatusId = _resolveInitialStatusId(item.status);
    _selectedStatusName = _resolveStatusName(item.status);
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
      return '';
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

    if (normalized == 'member' || normalized == 'employee') {
      return 'Nhân viên';
    }

    if (normalized == 'manager' || normalized == 'admin') {
      return 'Quản lý';
    }

    return name;
  }

  String _resolveInitialStatusId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '1';
    }

    for (final option in employeeStatuses) {
      if (option.id == normalized || option.name.toLowerCase() == normalized) {
        return option.id;
      }
    }

    if (normalized == 'active' ||
        normalized == 'working' ||
        normalized == 'enabled') {
      return '1';
    }
    if (normalized == 'inactive' ||
        normalized == 'disabled' ||
        normalized == '0') {
      return '0';
    }

    return value.trim().isEmpty ? '1' : value.trim();
  }

  String _resolveStatusName(String value) {
    final resolvedId = _resolveInitialStatusId(value).toLowerCase();
    for (final option in employeeStatuses) {
      if (option.id == resolvedId || option.name.toLowerCase() == resolvedId) {
        return option.name;
      }
    }

    return value.trim().isEmpty ? 'Đang làm việc' : value;
  }

  static String _formatBirthDateForDisplay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final dashParts = trimmed.split('-');
    if (dashParts.length == 3 && dashParts[0].length == 4) {
      final year = dashParts[0];
      final month = dashParts[1].padLeft(2, '0');
      final day = dashParts[2].padLeft(2, '0');
      return '$day-$month-$year';
    }

    final slashParts = trimmed.split('/');
    if (slashParts.length == 3 && slashParts[2].length == 4) {
      final day = slashParts[0].padLeft(2, '0');
      final month = slashParts[1].padLeft(2, '0');
      final year = slashParts[2];
      return '$day-$month-$year';
    }

    return trimmed;
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
