import 'package:flutter/material.dart';

import '../../controllers/employee_form_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/company_directory_item.dart';
import '../../models/employee_list_item.dart';
import '../../models/location_option.dart';

class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({
    super.key,
    this.initialEmployee,
  });

  final EmployeeListItem? initialEmployee;

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  late final EmployeeFormController _controller;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        EmployeeFormController(initialEmployee: widget.initialEmployee);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Future<void> _pickAccessRole() async {
    final selected = await _showOptionPicker<LocationOption>(
      title: 'Quyền truy cập',
      items: _controller.accessRoles,
      selectedId: _controller.selectedAccessRoleName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectAccessRole(selected);
    }
  }

  Future<void> _pickStatus() async {
    final selected = await _showOptionPicker<LocationOption>(
      title: 'Trạng thái',
      items: EmployeeFormController.employeeStatuses,
      selectedId: _controller.selectedStatusName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectStatus(selected);
    }
  }

  Future<void> _pickRegion() async {
    final selected = await _showOptionPicker<CompanyDirectoryItem>(
      title: 'Vùng',
      items: _controller.regions,
      selectedId: _controller.selectedRegionName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectRegion(selected);
    }
  }

  Future<void> _pickBranch() async {
    final selected = await _showOptionPicker<CompanyDirectoryItem>(
      title: 'Chi nhánh',
      items: _controller.branches,
      selectedId: _controller.selectedBranchName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectBranch(selected);
    }
  }

  Future<void> _pickDepartment() async {
    final selected = await _showOptionPicker<CompanyDirectoryItem>(
      title: 'Phòng ban',
      items: _controller.departments,
      selectedId: _controller.selectedDepartmentName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectDepartment(selected);
    }
  }

  Future<void> _pickJobTitle() async {
    final selected = await _showOptionPicker<CompanyDirectoryItem>(
      title: 'Chức vụ',
      items: _controller.jobTitles,
      selectedId: _controller.selectedJobTitleName,
      itemLabel: (item) => item.name,
      itemId: (item) => item.id,
    );
    if (selected != null) {
      _controller.selectJobTitle(selected);
    }
  }

  Future<void> _pickBirthDate() async {
    final initialDate = _parseBirthDate(_controller.birthDateController.text) ??
        DateTime(1990, 1, 1);
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );

    if (selected != null) {
      _controller.setBirthDate(selected);
    }
  }

  DateTime? _parseBirthDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parts = trimmed.split('-');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  Future<T?> _showOptionPicker<T>({
    required String title,
    required List<T> items,
    required String selectedId,
    required String Function(T item) itemLabel,
    required String Function(T item) itemId,
  }) async {
    if (items.isEmpty) {
      AppNotice.showInfo(context, 'Chưa có dữ liệu để chọn.');
      return null;
    }

    return showModalBottomSheet<T>(
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
                      final label = itemLabel(item);
                      final isSelected =
                          selectedId == label || selectedId == itemId(item);

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(item),
                        title: Text(
                          label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Thông tin',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _controller.isSubmitting ? null : _submit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
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
                  : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _EmployeeTabBar(
                  currentIndex: _currentTabIndex,
                  onChanged: (index) =>
                      setState(() => _currentTabIndex = index),
                ),
                Expanded(
                  child: _currentTabIndex == 0
                      ? _EmployeeInformationTab(
                          controller: _controller,
                          onPickBirthDate: _pickBirthDate,
                          onPickAccessRole: _pickAccessRole,
                          onPickStatus: _pickStatus,
                          onPickRegion: _pickRegion,
                          onPickBranch: _pickBranch,
                          onPickDepartment: _pickDepartment,
                          onPickJobTitle: _pickJobTitle,
                        )
                      : const _EmployeeDeviceTab(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmployeeTabBar extends StatelessWidget {
  const _EmployeeTabBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EmployeeTabItem(
            label: 'Thông tin',
            isSelected: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        Expanded(
          child: _EmployeeTabItem(
            label: 'Thiết bị',
            isSelected: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _EmployeeTabItem extends StatelessWidget {
  const _EmployeeTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF26D38E) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? const Color(0xFF26D38E) : const Color(0xFFC8CFDE),
          ),
        ),
      ),
    );
  }
}

class _EmployeeInformationTab extends StatelessWidget {
  const _EmployeeInformationTab({
    required this.controller,
    required this.onPickBirthDate,
    required this.onPickAccessRole,
    required this.onPickStatus,
    required this.onPickRegion,
    required this.onPickBranch,
    required this.onPickDepartment,
    required this.onPickJobTitle,
  });

  final EmployeeFormController controller;
  final VoidCallback onPickBirthDate;
  final VoidCallback onPickAccessRole;
  final VoidCallback onPickStatus;
  final VoidCallback onPickRegion;
  final VoidCallback onPickBranch;
  final VoidCallback onPickDepartment;
  final VoidCallback onPickJobTitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _EmployeeSectionHeader(title: 'THÔNG TIN CÁ NHÂN'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            children: [
              _EmployeeFieldBlock(
                label: 'Họ và tên',
                isRequired: true,
                child: _EmployeeInputField(
                  controller: controller.nameController,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Số điện thoại',
                child: _EmployeeInputField(
                  controller: controller.phoneController,
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2F7DF7),
                  ),
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Email',
                child: _EmployeeInputField(
                  controller: controller.emailController,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Ngày sinh',
                child: _EmployeeSelectorField(
                  value: controller.birthDateController.text,
                  placeholder: 'VD: 15-09-1982',
                  onTap: onPickBirthDate,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Địa chỉ',
                child: _EmployeeInputField(
                  controller: controller.addressController,
                  hintText: 'Địa chỉ',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _EmployeeSectionHeader(title: 'HỒ SƠ CÔNG TY'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            children: [
              _EmployeeFieldBlock(
                label: 'Quyền truy cập',
                child: _EmployeeSelectorField(
                  value: controller.selectedAccessRoleName,
                  placeholder: 'Quyền truy cập',
                  onTap: onPickAccessRole,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Trạng thái',
                child: _EmployeeSelectorField(
                  value: controller.selectedStatusName,
                  placeholder: 'Trạng thái',
                  onTap: onPickStatus,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Vùng',
                child: _EmployeeSelectorField(
                  value: controller.selectedRegionName,
                  placeholder: 'Vùng',
                  onTap: onPickRegion,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Chi nhánh',
                child: _EmployeeSelectorField(
                  value: controller.selectedBranchName,
                  placeholder: 'Chi nhánh',
                  onTap: onPickBranch,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Phòng ban',
                child: _EmployeeSelectorField(
                  value: controller.selectedDepartmentName,
                  placeholder: 'Phòng ban',
                  onTap: onPickDepartment,
                ),
              ),
              _EmployeeFieldBlock(
                label: 'Chức vụ',
                child: _EmployeeSelectorField(
                  value: controller.selectedJobTitleName,
                  placeholder: 'Chức vụ',
                  onTap: onPickJobTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeeDeviceTab extends StatelessWidget {
  const _EmployeeDeviceTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Tab thiết bị sẽ được bổ sung ở bước tiếp theo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _EmployeeSectionHeader extends StatelessWidget {
  const _EmployeeSectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      color: const Color(0xFFF1FBFF),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          letterSpacing: 0.4,
          color: Color(0xFF7987A8),
        ),
      ),
    );
  }
}

class _EmployeeFieldBlock extends StatelessWidget {
  const _EmployeeFieldBlock({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF8E96AF),
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFFF4D5E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmployeeSelectorField extends StatelessWidget {
  const _EmployeeSelectorField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return SizedBox(
      height: 56,
      child: Material(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD5DBE8),
              width: 1.1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value : placeholder,
                      style: TextStyle(
                        fontSize: 16,
                        color: hasValue
                            ? AppColors.textPrimary
                            : const Color(0xFFAAB4D3),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF95A2C8),
                    size: 34,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeInputField extends StatelessWidget {
  const _EmployeeInputField({
    required this.controller,
    this.hintText,
    this.trailing,
  });

  final TextEditingController controller;
  final String? hintText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFAAB4D3),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD5DBE8),
            width: 1.1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD5DBE8),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD5DBE8),
            width: 1.1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFFF8B94),
            width: 1.1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFFF4D5E),
            width: 1.5,
          ),
        ),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14),
                child: trailing,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
      ),
    );
  }
}
