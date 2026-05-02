import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/company_directory_form_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/company_directory_item.dart';
import '../../models/location_option.dart';

class CompanyDirectoryFormPage extends StatefulWidget {
  const CompanyDirectoryFormPage({
    super.key,
    required this.title,
    required this.endpoint,
    this.requiresRegionId = false,
    this.initialItem,
  });

  final String title;
  final String endpoint;
  final bool requiresRegionId;
  final CompanyDirectoryItem? initialItem;

  @override
  State<CompanyDirectoryFormPage> createState() =>
      _CompanyDirectoryFormPageState();
}

class _CompanyDirectoryFormPageState extends State<CompanyDirectoryFormPage> {
  late final CompanyDirectoryFormController _controller;

  bool get _isAttendanceLocationForm => widget.endpoint == '/company/location';

  String get _pageTitle {
    if (_isAttendanceLocationForm) {
      return 'Cập nhật vị trí';
    }

    return _controller.isEditing
        ? 'Chi tiết ${widget.title}'
        : 'Tạo ${widget.title}';
  }

  String get _submitLabel {
    if (_isAttendanceLocationForm) {
      return 'Lưu';
    }

    if (_controller.isEditing) {
      return 'Lưu';
    }

    return 'Tạo';
  }

  @override
  void initState() {
    super.initState();
    _controller = CompanyDirectoryFormController(
      endpoint: widget.endpoint,
      requiresRegionId: widget.requiresRegionId,
      initialItem: widget.initialItem,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showRegionPicker() async {
    if (_controller.isLoadingRegions) {
      return;
    }

    if (_controller.regions.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu vùng để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn vùng',
      items: _controller.regions,
      selectedId: _controller.selectedRegionId,
    );

    if (selected != null) {
      _controller.selectRegion(selected);
    }
  }

  Future<void> _showBranchPicker() async {
    if (_controller.isLoadingBranches) {
      return;
    }

    if (_controller.branches.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu chi nhánh để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn chi nhánh',
      items: _controller.branches,
      selectedId: _controller.selectedBranchId,
    );

    if (selected != null) {
      _controller.selectBranch(selected);
    }
  }

  Future<void> _showDepartmentPicker() async {
    if (_controller.isLoadingDepartments) {
      return;
    }

    if (_controller.departments.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu phòng ban để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn phòng ban',
      items: _controller.departments,
      selectedId: _controller.selectedDepartmentId,
    );

    if (selected != null) {
      _controller.selectDepartment(selected);
    }
  }

  Future<void> _showCountryPicker() async {
    if (_controller.isLoadingCountries) {
      return;
    }

    if (_controller.countries.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu quốc gia để chọn.');
      return;
    }

    final selected = await _showLocationPicker(
      title: 'Chọn quốc gia',
      items: _controller.countries,
      selectedId: _controller.selectedCountryId,
    );

    if (selected != null) {
      await _controller.selectCountry(selected);
    }
  }

  Future<void> _showCityPicker() async {
    if (_controller.isLoadingCities) {
      return;
    }

    if (_controller.cities.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu thành phố để chọn.');
      return;
    }

    final selected = await _showLocationPicker(
      title: 'Chọn thành phố',
      items: _controller.cities,
      selectedId: _controller.selectedCityId,
    );

    if (selected != null) {
      await _controller.selectCity(selected);
    }
  }

  Future<void> _showWardPicker() async {
    if (_controller.isLoadingWards) {
      return;
    }

    if (_controller.selectedCityId == null) {
      AppNotice.showError(context, 'Vui lòng chọn thành phố trước.');
      return;
    }

    if (_controller.wards.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu phường/xã để chọn.');
      return;
    }

    final selected = await _showLocationPicker(
      title: 'Chọn phường/xã',
      items: _controller.wards,
      selectedId: _controller.selectedWardId,
    );

    if (selected != null) {
      _controller.selectWard(selected);
    }
  }

  Future<CompanyDirectoryItem?> _showItemPicker({
    required String title,
    required List<CompanyDirectoryItem> items,
    required String? selectedId,
  }) async {
    return showModalBottomSheet<CompanyDirectoryItem>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selectedId == item.id;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: item.description.trim().isEmpty
                            ? null
                            : Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                ),
                              ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textPrimary,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<LocationOption?> _showLocationPicker({
    required String title,
    required List<LocationOption> items,
    required String? selectedId,
  }) async {
    return showModalBottomSheet<LocationOption>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selectedId == item.id;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textPrimary,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final message = await _controller.submit();
    if (!mounted) {
      return;
    }

    if (_controller.lastActionSucceeded) {
      AppNotice.showSuccess(context, message);
      Navigator.of(context).pop(true);
    } else {
      AppNotice.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: _pageTitle,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _controller.isSubmitting ? null : _submit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: _controller.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_submitLabel),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_isAttendanceLocationForm) {
              return _AttendanceLocationEditorForm(
                controller: _controller,
                onSelectBranch: _showBranchPicker,
                onSelectDepartment: _showDepartmentPicker,
                onSelectCountry: _showCountryPicker,
                onSelectCity: _showCityPicker,
                onSelectWard: _showWardPicker,
                onUseCurrentLocation: _controller.fillWithCurrentLocation,
              );
            }

            return _DefaultDirectoryForm(
              controller: _controller,
              title: widget.title,
              requiresRegionId: widget.requiresRegionId,
              onSelectRegion: _showRegionPicker,
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceLocationEditorForm extends StatelessWidget {
  const _AttendanceLocationEditorForm({
    required this.controller,
    required this.onSelectBranch,
    required this.onSelectDepartment,
    required this.onSelectCountry,
    required this.onSelectCity,
    required this.onSelectWard,
    required this.onUseCurrentLocation,
  });

  final CompanyDirectoryFormController controller;
  final VoidCallback onSelectBranch;
  final VoidCallback onSelectDepartment;
  final VoidCallback onSelectCountry;
  final VoidCallback onSelectCity;
  final VoidCallback onSelectWard;
  final Future<void> Function() onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      children: [
        _buildFieldLabel('Quốc gia'),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.countryController.text.trim().isEmpty
              ? 'Chọn quốc gia'
              : controller.countryController.text.trim(),
          isLoading: controller.isLoadingCountries,
          onTap: onSelectCountry,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Thành phố'),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.cityController.text.trim().isEmpty
              ? 'Chọn thành phố'
              : controller.cityController.text.trim(),
          isLoading: controller.isLoadingCities,
          onTap: onSelectCity,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Phường/Xã'),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.wardController.text.trim().isEmpty
              ? 'Chọn phường/xã'
              : controller.wardController.text.trim(),
          isLoading: controller.isLoadingWards,
          onTap: onSelectWard,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Địa chỉ chi tiết'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.addressDetailController,
          minLines: 1,
          maxLines: 1,
          hintText: 'Nhập địa chỉ chi tiết',
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Địa chỉ (tự động)'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.fullAddressController,
          minLines: 2,
          maxLines: 3,
          hintText: 'Nhập địa chỉ tổng hợp',
          readOnly: true,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Chi nhánh', isRequired: true),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.selectedBranchName.isEmpty
              ? 'Chọn chi nhánh'
              : controller.selectedBranchName,
          isLoading: controller.isLoadingBranches,
          onTap: onSelectBranch,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Phòng ban'),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.selectedDepartmentName.isEmpty
              ? 'Chọn phòng ban'
              : controller.selectedDepartmentName,
          isLoading: controller.isLoadingDepartments,
          onTap: onSelectDepartment,
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Vĩ độ checkin'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.latitudeController,
          minLines: 1,
          maxLines: 1,
          hintText: controller.isResolvingCoordinates
              ? 'Đang lấy vĩ độ...'
              : '10.842433',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Kinh độ checkin'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.longitudeController,
          minLines: 1,
          maxLines: 1,
          hintText: controller.isResolvingCoordinates
              ? 'Đang lấy kinh độ...'
              : '106.679459',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 34),
        _buildFieldLabel('Bán kính checkin (m)'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.radiusController,
          minLines: 1,
          maxLines: 1,
          hintText: '150',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        _LocationMapCard(
          latitude: controller.mapLatitude,
          longitude: controller.mapLongitude,
          radiusMeters: controller.mapRadiusMeters,
          isLocating: controller.isFetchingCurrentLocation,
          onUseCurrentLocation: onUseCurrentLocation,
        ),
      ],
    );
  }
}

Widget _buildFieldLabel(String title, {bool isRequired = false}) {
  return _FieldLabel(
    title: title,
    isRequired: isRequired,
  );
}

class _DefaultDirectoryForm extends StatelessWidget {
  const _DefaultDirectoryForm({
    required this.controller,
    required this.title,
    required this.requiresRegionId,
    required this.onSelectRegion,
  });

  final CompanyDirectoryFormController controller;
  final String title;
  final bool requiresRegionId;
  final VoidCallback onSelectRegion;

  bool get _isRegionForm => title == 'vùng';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _LegacyFieldSection(
          label: _isRegionForm ? 'Tên vùng' : 'Tên $title',
          isRequired: true,
          child: _LegacyTextField(
            controller: controller.nameController,
            hintText: 'Nhập tên $title',
          ),
        ),
        const SizedBox(height: 16),
        _LegacyFieldSection(
          label: _isRegionForm ? 'Mô tả' : 'Địa chỉ',
          child: _LegacyTextField(
            controller: controller.descriptionController,
            hintText: _isRegionForm ? 'Nhập mô tả' : 'Nhập địa chỉ',
            minLines: _isRegionForm ? 6 : 1,
            maxLines: _isRegionForm ? 6 : 1,
          ),
        ),
        if (requiresRegionId) ...[
          const SizedBox(height: 16),
          _LegacyFieldSection(
            label: 'Vùng',
            isRequired: true,
            child: _LegacySelectorField(
              label: controller.selectedRegionName.isEmpty
                  ? 'Chọn vùng'
                  : controller.selectedRegionName,
              isLoading: controller.isLoadingRegions,
              onTap: onSelectRegion,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegacyFieldSection extends StatelessWidget {
  const _LegacyFieldSection({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(title: label, isRequired: isRequired),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.title,
    this.isRequired = false,
  });

  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: title),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFB22B2B),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegacyTextField extends StatelessWidget {
  const _LegacyTextField({
    required this.controller,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.muted,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.minLines,
    required this.maxLines,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 17,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 17,
          color: Color(0xFFD3D3D3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFDCDCDC),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _LegacySelectorField extends StatelessWidget {
  const _LegacySelectorField({
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isLoading ? 'Đang tải danh sách vùng...' : label,
                  style: TextStyle(
                    fontSize: 16,
                    color: label == 'Chọn vùng' || isLoading
                        ? AppColors.muted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDCDCDC),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isLoading ? 'Đang tải dữ liệu...' : label,
                  style: TextStyle(
                    fontSize: 17,
                    color: isLoading || label.startsWith('Chọn')
                        ? const Color(0xFFD3D3D3)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA9A9A9),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationMapCard extends StatelessWidget {
  const _LocationMapCard({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isLocating,
    required this.onUseCurrentLocation,
  });

  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final bool isLocating;
  final Future<void> Function() onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = latitude != null && longitude != null;
    final target = LatLng(
      latitude ?? 10.7769,
      longitude ?? 106.7009,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: target,
                initialZoom: hasCoordinates ? 18.5 : 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.b2msr',
                ),
                if (hasCoordinates)
                  CircleLayer(
                    circles: <CircleMarker>[
                      CircleMarker(
                        point: target,
                        radius: radiusMeters / 3.5,
                        useRadiusInMeter: true,
                        color: const Color(0x669FFF5A),
                        borderStrokeWidth: 2,
                        borderColor: const Color(0x889FFF5A),
                      ),
                    ],
                  ),
                if (hasCoordinates)
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: target,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: Color(0xFFC61C1C),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                heroTag: 'current-location-map-button',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: isLocating ? null : onUseCurrentLocation,
                child: isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
