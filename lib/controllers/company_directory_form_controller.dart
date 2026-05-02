import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/company_directory_item.dart';
import '../models/location_option.dart';
import '../services/administrative_location_service.dart';
import '../services/company_directory_service.dart';
import '../services/location_service.dart';

class CompanyDirectoryFormController extends ChangeNotifier {
  static const Duration _geocodeDebounceDelay = Duration(milliseconds: 650);

  CompanyDirectoryFormController({
    required this.endpoint,
    required this.requiresRegionId,
    this.initialItem,
    CompanyDirectoryService? service,
    AdministrativeLocationService? administrativeLocationService,
    LocationService? locationService,
  })  : _service = service ?? CompanyDirectoryService(),
        _administrativeLocationService =
            administrativeLocationService ?? AdministrativeLocationService(),
        _locationService = locationService ?? LocationService(),
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
          text: initialItem?.fullAddress ?? initialItem?.description ?? '',
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
    _editingItemId = initialItem?.id ?? '';
    _selectedBranchName = initialItem?.branchName ?? '';
    _selectedDepartmentName = initialItem?.departmentName ?? '';
    countryController.addListener(_syncDerivedAddressFields);
    cityController.addListener(_syncDerivedAddressFields);
    wardController.addListener(_syncDerivedAddressFields);
    addressDetailController.addListener(_syncDerivedAddressFields);
    if (isAttendanceLocationForm) {
      _initializeAttendanceLocationForm();
    } else if (requiresRegionId) {
      loadRegions();
    }
    _syncDerivedAddressFields();
  }

  final String endpoint;
  final bool requiresRegionId;
  final CompanyDirectoryItem? initialItem;
  final CompanyDirectoryService _service;
  final AdministrativeLocationService _administrativeLocationService;
  final LocationService _locationService;
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
  bool _isLoadingCountries = false;
  bool _isLoadingCities = false;
  bool _isLoadingWards = false;
  bool _isResolvingCoordinates = false;
  bool _isSubmitting = false;
  bool _isFetchingCurrentLocation = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';
  String _selectedRegionName = '';
  String _selectedBranchName = '';
  String _selectedDepartmentName = '';
  String _editingItemId = '';
  String? _selectedCountryId;
  String? _selectedCityId;
  String? _selectedWardId;
  List<CompanyDirectoryItem> _regions = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _branches = const <CompanyDirectoryItem>[];
  List<CompanyDirectoryItem> _departments = const <CompanyDirectoryItem>[];
  List<LocationOption> _countries = const <LocationOption>[];
  List<LocationOption> _cities = const <LocationOption>[];
  List<LocationOption> _wards = const <LocationOption>[];
  Timer? _geocodeDebounce;
  String _lastGeocodeKey = '';

  bool get isAttendanceLocationForm =>
      endpoint == '/company/location';
  bool get isUpdateOnlyAttendanceLocationForm => isAttendanceLocationForm;
  bool get isLoadingRegions => _isLoadingRegions;
  bool get isLoadingBranches => _isLoadingBranches;
  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isLoadingCountries => _isLoadingCountries;
  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingWards => _isLoadingWards;
  bool get isResolvingCoordinates => _isResolvingCoordinates;
  bool get isSubmitting => _isSubmitting;
  bool get isFetchingCurrentLocation => _isFetchingCurrentLocation;
  bool get lastActionSucceeded => _lastActionSucceeded;
  bool get isEditing =>
      isUpdateOnlyAttendanceLocationForm || _editingItemId.isNotEmpty;
  String get statusMessage => _statusMessage;
  List<CompanyDirectoryItem> get regions => _regions;
  List<CompanyDirectoryItem> get branches => _branches;
  List<CompanyDirectoryItem> get departments => _departments;
  List<LocationOption> get countries => _countries;
  List<LocationOption> get cities => _cities;
  List<LocationOption> get wards => _wards;

  String? get selectedRegionId => _normalizedValue(regionIdController);
  String? get selectedBranchId => _normalizedValue(branchIdController);
  String? get selectedDepartmentId => _normalizedValue(departmentIdController);

  String get selectedRegionName => _selectedRegionName.isNotEmpty
      ? _selectedRegionName
      : _resolveNameById(_regions, selectedRegionId);
  String get selectedBranchName => _selectedBranchName.isNotEmpty
      ? _selectedBranchName
      : _resolveNameById(_branches, selectedBranchId);
  String get selectedDepartmentName => _selectedDepartmentName.isNotEmpty
      ? _selectedDepartmentName
      : _resolveNameById(_departments, selectedDepartmentId);
  String? get selectedCountryId => _selectedCountryId;
  String? get selectedCityId => _selectedCityId;
  String? get selectedWardId => _selectedWardId;

  double? get mapLatitude => double.tryParse(latitudeController.text.trim());
  double? get mapLongitude => double.tryParse(longitudeController.text.trim());
  double get mapRadiusMeters =>
      double.tryParse(radiusController.text.trim()) ?? 300;

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

  Future<void> _initializeAttendanceLocationForm() async {
    if (requiresRegionId) {
      await loadRegions();
    }

    await _loadExistingAttendanceLocation();
    await loadAttendanceDependencies();
    await loadAdministrativeLocations();
  }

  Future<void> _loadExistingAttendanceLocation() async {
    try {
      final item = await _service.fetchItem(endpoint);
      if (item == null) {
        _editingItemId = initialItem?.id ?? '';
        return;
      }

      _applyItemToForm(item);
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _editingItemId = initialItem?.id ?? '';
        _lastActionSucceeded = true;
        return;
      }

      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được thông tin vị trí hiện tại.';
    } finally {
      notifyListeners();
    }
  }

  void _applyItemToForm(CompanyDirectoryItem item) {
    _editingItemId = item.id.isNotEmpty ? item.id : (initialItem?.id ?? '1');
    nameController.text = item.name;
    descriptionController.text = item.description;
    regionIdController.text = item.regionId ?? '';
    branchIdController.text = item.branchId ?? '';
    departmentIdController.text = item.departmentId ?? '';
    countryController.text = item.country ?? countryController.text;
    cityController.text = item.city ?? '';
    wardController.text = item.ward ?? '';
    addressDetailController.text = item.addressDetail ?? '';
    fullAddressController.text = item.fullAddress ?? item.description;
    latitudeController.text = item.latitude ?? '';
    longitudeController.text = item.longitude ?? '';
    radiusController.text = item.radius ?? radiusController.text;
    _selectedRegionName = item.regionName ?? _selectedRegionName;
    _selectedBranchName = item.branchName ?? _selectedBranchName;
    _selectedDepartmentName = item.departmentName ?? _selectedDepartmentName;
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

  Future<void> loadAdministrativeLocations() async {
    _isLoadingCountries = true;
    notifyListeners();

    try {
      _countries = await _administrativeLocationService.fetchCountries();
      _selectedCountryId = _resolveLocationId(
        _countries,
        countryController.text.trim(),
      );
      final initialCountry = _selectedCountryId != null
          ? _findLocationById(_countries, _selectedCountryId!)
          : (_countries.isNotEmpty ? _countries.first : null);

      if (initialCountry != null) {
        countryController.text = initialCountry.name;
        await selectCountry(
          initialCountry,
          notify: false,
          preserveCurrentCity: true,
          preserveCurrentWard: true,
        );
      }

      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu tỉnh/thành.';
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }

  Future<void> loadWardsForCity(
    String cityId, {
    bool preserveCurrentWard = false,
  }) async {
    _isLoadingWards = true;
    if (!preserveCurrentWard) {
      _selectedWardId = null;
      wardController.clear();
    }
    _wards = const <LocationOption>[];
    notifyListeners();

    try {
      final countryCode = (_selectedCountryId ?? '').trim();
      if (countryCode.isEmpty) {
        _lastActionSucceeded = false;
        _statusMessage = 'Không xác định được quốc gia để tải phường/xã.';
        return;
      }

      _wards = await _administrativeLocationService.fetchWards(
        countryCode,
        cityId,
      );
      if (preserveCurrentWard) {
        _selectedWardId =
            _resolveLocationId(_wards, wardController.text.trim());
        if (_wards.isEmpty && wardController.text.trim().isNotEmpty) {
          _wards = <LocationOption>[
            LocationOption(
              id: wardController.text.trim(),
              name: wardController.text.trim(),
            ),
          ];
          _selectedWardId = wardController.text.trim();
        }
      }
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu phường/xã.';
    } finally {
      _isLoadingWards = false;
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

  Future<void> selectCountry(
    LocationOption country, {
    bool notify = true,
    bool preserveCurrentCity = false,
    bool preserveCurrentWard = false,
  }) async {
    final previousCityName = cityController.text.trim();
    final previousWardName = wardController.text.trim();

    _selectedCountryId = country.id;
    countryController.text = country.name;
    _cities = const <LocationOption>[];
    _wards = const <LocationOption>[];
    _selectedCityId = null;
    _selectedWardId = null;
    if (!preserveCurrentCity) {
      cityController.clear();
    }
    if (!preserveCurrentWard) {
      wardController.clear();
    }

    _isLoadingCities = true;
    if (notify) {
      notifyListeners();
    }

    try {
      _cities = await _administrativeLocationService.fetchCities(country.id);

      if (preserveCurrentCity && previousCityName.isNotEmpty) {
        _selectedCityId = _resolveLocationId(_cities, previousCityName);
      }

      final selectedCity = _selectedCityId != null
          ? _findLocationById(_cities, _selectedCityId!)
          : null;

      if (selectedCity != null) {
        cityController.text = selectedCity.name;
        await loadWardsForCity(
          selectedCity.id,
          preserveCurrentWard: preserveCurrentWard && previousWardName.isNotEmpty,
        );
      } else if (preserveCurrentCity) {
        cityController.clear();
        wardController.clear();
      }

      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không tải được dữ liệu thành phố.';
    } finally {
      _isLoadingCities = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> selectCity(LocationOption city) async {
    _selectedCityId = city.id;
    cityController.text = city.name;
    await loadWardsForCity(city.id);
    notifyListeners();
  }

  void selectWard(LocationOption ward) {
    _selectedWardId = ward.id;
    wardController.text = ward.name;
    notifyListeners();
  }

  String? _resolveLocationId(List<LocationOption> items, String name) {
    final normalizedValue = name.trim().toLowerCase();
    if (normalizedValue.isEmpty) {
      return null;
    }

    for (final item in items) {
      final normalizedItemName = item.name.trim().toLowerCase();
      final normalizedItemId = item.id.trim().toLowerCase();
      if (normalizedItemName == normalizedValue ||
          normalizedItemId == normalizedValue) {
        return item.id;
      }
    }

    for (final item in items) {
      final normalizedItemName = item.name.trim().toLowerCase();
      if (normalizedItemName.contains(normalizedValue) ||
          normalizedValue.contains(normalizedItemName)) {
        return item.id;
      }
    }

    return null;
  }

  LocationOption? _findLocationById(List<LocationOption> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  void _syncDerivedAddressFields() {
    final parts = <String>[
      addressDetailController.text.trim(),
      wardController.text.trim(),
      cityController.text.trim(),
      countryController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();

    final fullAddress = parts.join(', ');
    if (fullAddressController.text.trim() != fullAddress) {
      fullAddressController.value = fullAddressController.value.copyWith(
        text: fullAddress,
        selection: TextSelection.collapsed(offset: fullAddress.length),
        composing: TextRange.empty,
      );
    }

    if (descriptionController.text.trim() != fullAddress) {
      descriptionController.value = descriptionController.value.copyWith(
        text: fullAddress,
        selection: TextSelection.collapsed(offset: fullAddress.length),
        composing: TextRange.empty,
      );
    }

    if (isAttendanceLocationForm && nameController.text.trim() != fullAddress) {
      nameController.value = nameController.value.copyWith(
        text: fullAddress,
        selection: TextSelection.collapsed(offset: fullAddress.length),
        composing: TextRange.empty,
      );
    }

    _scheduleGeocodeIfNeeded();
  }

  void _scheduleGeocodeIfNeeded() {
    if (!isAttendanceLocationForm) {
      return;
    }

    final country = countryController.text.trim();
    final countryCode = (_selectedCountryId ?? '').trim();
    final city = cityController.text.trim();
    final ward = wardController.text.trim();
    final addressDetail = addressDetailController.text.trim();

    final hasEnoughData = countryCode.isNotEmpty &&
        city.isNotEmpty &&
        ward.isNotEmpty &&
        addressDetail.isNotEmpty;

    if (!hasEnoughData) {
      _geocodeDebounce?.cancel();
      _lastGeocodeKey = '';
      return;
    }

    final geocodeKey = [countryCode, city, ward, addressDetail].join('|');
    if (_lastGeocodeKey == geocodeKey &&
        latitudeController.text.isNotEmpty &&
        longitudeController.text.isNotEmpty) {
      return;
    }

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(_geocodeDebounceDelay, () {
      resolveCoordinatesFromAddress(
        country: country,
        countryCode: countryCode,
        city: city,
        ward: ward,
        addressDetail: addressDetail,
        geocodeKey: geocodeKey,
      );
    });
  }

  Future<void> resolveCoordinatesFromAddress({
    required String country,
    required String countryCode,
    required String city,
    required String ward,
    required String addressDetail,
    required String geocodeKey,
  }) async {
    _isResolvingCoordinates = true;
    notifyListeners();

    try {
      final result = await _service.geocodeAddress(
        country: countryCode,
        city: city,
        ward: ward,
        addressDetail: addressDetail,
      );

      final latestKey = [
        countryController.text.trim(),
        cityController.text.trim(),
        wardController.text.trim(),
        addressDetailController.text.trim(),
      ].join('|');
      if (latestKey != geocodeKey) {
        return;
      }

      latitudeController.text = result.latitude ?? '';
      longitudeController.text = result.longitude ?? '';
      _lastGeocodeKey = geocodeKey;
      _lastActionSucceeded = true;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      latitudeController.clear();
      longitudeController.clear();
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không thể lấy tọa độ từ địa chỉ đã nhập.';
      latitudeController.clear();
      longitudeController.clear();
    } finally {
      _isResolvingCoordinates = false;
      notifyListeners();
    }
  }

  Future<void> fillWithCurrentLocation() async {
    _isFetchingCurrentLocation = true;
    notifyListeners();

    try {
      final result = await _locationService.getCurrentLocationDetails();

      latitudeController.text = result.latitude.toString();
      longitudeController.text = result.longitude.toString();

      if (result.country.isNotEmpty) {
        final resolvedCountry = _resolveCountryOption(result.country);
        if (resolvedCountry != null) {
          await selectCountry(
            resolvedCountry,
            notify: false,
            preserveCurrentCity: false,
            preserveCurrentWard: false,
          );
        } else {
          countryController.text = result.country;
        }
      }

      if (result.city.isNotEmpty && _cities.isNotEmpty) {
        final cityId = _resolveLocationId(_cities, result.city);
        final city = cityId != null ? _findLocationById(_cities, cityId) : null;
        if (city != null) {
          await selectCity(city);
        } else {
          cityController.text = result.city;
        }
      } else if (result.city.isNotEmpty) {
        cityController.text = result.city;
      }

      if (result.ward.isNotEmpty && _wards.isNotEmpty) {
        final wardId = _resolveLocationId(_wards, result.ward);
        final ward = wardId != null ? _findLocationById(_wards, wardId) : null;
        if (ward != null) {
          selectWard(ward);
        } else {
          wardController.text = result.ward;
        }
      } else if (result.ward.isNotEmpty) {
        wardController.text = result.ward;
      }

      final detail = result.street.isNotEmpty
          ? result.street
          : result.address.split(',').first.trim();
      if (detail.isNotEmpty) {
        addressDetailController.text = detail;
      }

      _lastGeocodeKey = '';
      _lastActionSucceeded = true;
      _statusMessage = 'Đã lấy vị trí hiện tại.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không thể lấy vị trí hiện tại.';
    } finally {
      _isFetchingCurrentLocation = false;
      notifyListeners();
    }
  }

  LocationOption? _resolveCountryOption(String value) {
    final normalizedValue = value.trim().toLowerCase();
    if (normalizedValue.isEmpty) {
      return null;
    }

    for (final item in _countries) {
      final normalizedName = item.name.trim().toLowerCase();
      final normalizedId = item.id.trim().toLowerCase();
      if (normalizedName == normalizedValue ||
          normalizedId == normalizedValue ||
          (normalizedValue == 'vietnam' && normalizedId == 'vn') ||
          (normalizedValue == 'việt nam' && normalizedId == 'vn')) {
        return item;
      }
    }

    return null;
  }

  Future<String> submit() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final regionId = regionIdController.text.trim();
    final branchId = branchIdController.text.trim();
    final departmentId = departmentIdController.text.trim();
    final subBranchId = subBranchIdController.text.trim();
    final employeeId = employeeIdController.text.trim();
    final countryCode = (_selectedCountryId ?? '').trim();
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

    if (isAttendanceLocationForm && countryCode.isEmpty) {
      return _fail('Vui lòng chọn quốc gia.');
    }

    if (isAttendanceLocationForm && city.isEmpty) {
      return _fail('Vui lòng chọn thành phố.');
    }

    if (isAttendanceLocationForm && ward.isEmpty) {
      return _fail('Vui lòng chọn phường/xã.');
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
              'countries': countryCode,
              'default_branch_id': branchId,
              if (city.isNotEmpty) 'city': city,
              if (ward.isNotEmpty) 'ward': ward,
              if (addressDetail.isNotEmpty) 'address_detail': addressDetail,
              if (fullAddress.isNotEmpty) 'full_address': fullAddress,
              if (latitude.isNotEmpty) 'latitude': latitude,
              if (longitude.isNotEmpty) 'longitude': longitude,
              if (subBranchId.isNotEmpty) 'sub_branch_id': subBranchId,
              if (departmentId.isNotEmpty)
                'default_department_id': departmentId,
              if (employeeId.isNotEmpty) 'employee_id': employeeId,
              if (radius.isNotEmpty) 'radius_meters': radius,
            }
          : null;

      final shouldUseUpdateCall = isEditing || isAttendanceLocationForm;

      final message = shouldUseUpdateCall
          ? await _service.updateItem(
              endpoint,
              initialItem?.id ?? '',
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
    _geocodeDebounce?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    regionIdController.dispose();
    branchIdController.dispose();
    subBranchIdController.dispose();
    departmentIdController.dispose();
    employeeIdController.dispose();
    countryController.removeListener(_syncDerivedAddressFields);
    cityController.removeListener(_syncDerivedAddressFields);
    wardController.removeListener(_syncDerivedAddressFields);
    addressDetailController.removeListener(_syncDerivedAddressFields);
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
