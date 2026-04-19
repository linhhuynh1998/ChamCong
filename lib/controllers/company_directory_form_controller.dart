import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../services/company_directory_service.dart';

class CompanyDirectoryFormController extends ChangeNotifier {
  CompanyDirectoryFormController({
    required this.endpoint,
    required this.requiresRegionId,
    CompanyDirectoryItem? initialItem,
    CompanyDirectoryService? service,
  })  : _service = service ?? CompanyDirectoryService(),
        this.initialItem = initialItem,
        nameController = TextEditingController(text: initialItem?.name ?? ''),
        descriptionController = TextEditingController(
          text: initialItem?.description ?? '',
        ),
        regionIdController = TextEditingController(
          text: initialItem?.regionId ?? '',
        ),
        branchIdController = TextEditingController(
          text: initialItem?.branchId ?? '',
        ),
        subBranchIdController = TextEditingController(),
        departmentIdController = TextEditingController(
          text: initialItem?.departmentId ?? '',
        ),
        employeeIdController = TextEditingController(),
        countryController = TextEditingController(
          text: initialItem?.country ?? 'Việt Nam',
        ),
        cityController = TextEditingController(text: initialItem?.city ?? ''),
        wardController = TextEditingController(text: initialItem?.ward ?? ''),
        addressDetailController = TextEditingController(
          text: initialItem?.addressDetail ?? '',
        ),
        fullAddressController = TextEditingController(
          text: initialItem?.fullAddress ??
              initialItem?.description ??
              '',
        ),
        latitudeController = TextEditingController(
          text: initialItem?.latitude ?? '',
        ),
        longitudeController = TextEditingController(
          text: initialItem?.longitude ?? '',
        ),
        radiusController = TextEditingController(
          text: initialItem?.radius ?? '150',
        ) {
    _selectedBranchName = initialItem?.branchName ?? '';
    _selectedDepartmentName = initialItem?.departmentName ?? '';
    if (requiresRegionId) {
      loadRegions();
    }
    if (isAttendanceLocationForm) {
      loadAttendanceDependencies();
    }
  }

  final String endpoint;
  final bool requiresRegionId;
  final CompanyDirectoryItem? initialItem;
  final CompanyDirectoryService _service;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController regionIdController;
  final TextEditingController branchIdController;
  final TextEditingController subBranchIdController;
  final TextEditingController departmentIdController;
  final TextEditingController employeeIdController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController wardController;
  final TextEditingController addressDetailController;
  final TextEditingController fullAddressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController radiusController;

  bool _isLoadingRegions = false;
  bool _isLoadingBranches = false;
  bool _isLoadingDepartments = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  String _selectedRegionName = '';
  String _selectedBranchName = '';
  String _selectedDepartmentName = '';
  List<CompanyDirectoryItem> _regions = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _branches = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _departments = const <CompanyDirectoryItem>[];

  bool get isAttendanceLocationForm => endpoint == '/company/attendance-location';
  bool get isLoadingRegions => _isLoadingRegions;
  bool get isLoadingBranches => _isLoadingBranches;
  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  bool get isEditing => (initialItem?.id ?? '').isNotEmpty;
  String get statusMessage => _statusMessage;
  List<CompanyDirectoryItem> get regions => _regions;
  List<CompanyDirectoryItem> get branches => _branches;
  List<CompanyDirectoryItem> get departments => _departments;

  String? get selectedRegionId => _normalizedValue(regionIdController);
  String? get selectedBranchId => _normalizedValue(branchIdController);
  String? get selectedDepartmentId => _normalizedValue(departmentIdController);

  String get selectedRegionName =>
      _selectedRegionName.isNotEmpty
          ? _selectedRegionName
          : _resolveNameById(_regions, selectedRegionId);
  String get selectedBranchName =>
      _selectedBranchName.isNotEmpty
          ? _selectedBranchName
          : _resolveNameById(_branches, selectedBranchId);
  String get selectedDepartmentName =>
      _selectedDepartmentName.isNotEmpty
          ? _selectedDepartmentName
          : _resolveNameById(_departments, selectedDepartmentId);

  String? _normalizedValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _resolveNameById(
    List<CompanyDirectoryItem> items,
    String? selectedId,
  ) {
    if (selectedId == null) {
      return '';
    }

    for (final item in items) {
      if (item.id == selectedId) {
        return item.name;
      }
    }

    return '';
  }

  Future<void> loadRegions() async {
    if (!requiresRegionId) {
      return;
    }

    _isLoadingRegions = true;
    notifyListeners();

    try {
      _regions = await _service.listItems('/company/regions');
      if (selectedRegionId != null && _selectedRegionName.isEmpty) {
        _selectedRegionName = _resolveNameById(_regions, selectedRegionId);
      }
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được danh sách vùng.';
    } finally {
      _isLoadingRegions = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendanceDependencies() async {
    _isLoadingBranches = true;
    _isLoadingDepartments = true;
    notifyListeners();

    try {
      final results = await Future.wait<List<CompanyDirectoryItem>>([
        _service.listItems('/company/branches'),
        _service.listItems('/company/departments'),
      ]);
      _branches = results[0];
      _departments = results[1];
      if (selectedBranchId != null && _selectedBranchName.isEmpty) {
        _selectedBranchName = _resolveNameById(_branches, selectedBranchId);
      }
      if (selectedDepartmentId != null && _selectedDepartmentName.isEmpty) {
        _selectedDepartmentName =
            _resolveNameById(_departments, selectedDepartmentId);
      }
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu danh mục.';
    } finally {
      _isLoadingBranches = false;
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  void selectRegion(CompanyDirectoryItem region) {
    regionIdController.text = region.id;
    _selectedRegionName = region.name;
    notifyListeners();
  }

  void selectBranch(CompanyDirectoryItem branch) {
    branchIdController.text = branch.id;
    _selectedBranchName = branch.name;
    notifyListeners();
  }

  void selectDepartment(CompanyDirectoryItem department) {
    departmentIdController.text = department.id;
    _selectedDepartmentName = department.name;
    notifyListeners();
  }

  Future<String> submit() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final regionId = regionIdController.text.trim();
    final branchId = branchIdController.text.trim();
    final departmentId = departmentIdController.text.trim();
    final subBranchId = subBranchIdController.text.trim();
    final employeeId = employeeIdController.text.trim();
    final country = countryController.text.trim();
    final city = cityController.text.trim();
    final ward = wardController.text.trim();
    final addressDetail = addressDetailController.text.trim();
    final fullAddress = fullAddressController.text.trim();
    final latitude = latitudeController.text.trim();
    final longitude = longitudeController.text.trim();
    final radius = radiusController.text.trim();

    if (name.isEmpty) {
      return _fail('Vui lòng nhập tên.');
    }

    if (requiresRegionId && regionId.isEmpty) {
      return _fail('Vui lòng chọn vùng.');
    }

    if (isAttendanceLocationForm && description.isEmpty) {
      return _fail('Vui lòng nhập địa chỉ.');
    }

    if (isAttendanceLocationForm && branchId.isEmpty) {
      return _fail('Vui lòng chọn chi nhánh.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final extraBody = isAttendanceLocationForm
          ? <String, dynamic>{
              'address': description,
              'branch_id': branchId,
              if (country.isNotEmpty) 'country': country,
              if (city.isNotEmpty) 'city': city,
              if (ward.isNotEmpty) 'ward': ward,
              if (addressDetail.isNotEmpty) 'address_detail': addressDetail,
              if (fullAddress.isNotEmpty) 'full_address': fullAddress,
              if (latitude.isNotEmpty) 'latitude': latitude,
              if (longitude.isNotEmpty) 'longitude': longitude,
              if (subBranchId.isNotEmpty) 'sub_branch_id': subBranchId,
              if (departmentId.isNotEmpty) 'department_id': departmentId,
              if (employeeId.isNotEmpty) 'employee_id': employeeId,
              if (radius.isNotEmpty) 'radius': radius,
            }
          : null;

      final message = isEditing
          ? await _service.updateItem(
              endpoint,
              initialItem!.id,
              name: name,
              description: description,
              regionId: regionId,
              extraBody: extraBody,
            )
          : await _service.createItem(
              endpoint,
              name: name,
              description: description,
              regionId: regionId,
              extraBody: extraBody,
            );

      _lastActionSucceeded = true;
      _statusMessage = message;
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      return _fail('Không thể lưu dữ liệu. Vui lòng thử lại.');
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

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    regionIdController.dispose();
    branchIdController.dispose();
    subBranchIdController.dispose();
    departmentIdController.dispose();
    employeeIdController.dispose();
    countryController.dispose();
    cityController.dispose();
    wardController.dispose();
    addressDetailController.dispose();
    fullAddressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
    super.dispose();
  }
}
