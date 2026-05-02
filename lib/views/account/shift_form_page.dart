import 'package:flutter/material.dart';

import '../../controllers/shift_form_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/company_directory_item.dart';
import '../../models/shift_item.dart';

class ShiftFormPage extends StatefulWidget {
  const ShiftFormPage({
    super.key,
    this.initialItem,
  });

  final ShiftItem? initialItem;

  @override
  State<ShiftFormPage> createState() => _ShiftFormPageState();
}

class _ShiftFormPageState extends State<ShiftFormPage> {
  late final ShiftFormController _controller;
  static const List<String> _hourOptions = <String>[
    '00',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
  ];
  static const List<String> _minuteOptions = <String>[
    '00',
    '05',
    '10',
    '15',
    '20',
    '25',
    '30',
    '35',
    '40',
    '45',
    '50',
    '55',
  ];

  static const List<_WeekdayOption> _weekdayOptions = <_WeekdayOption>[
    _WeekdayOption(value: 1, label: 'T2'),
    _WeekdayOption(value: 2, label: 'T3'),
    _WeekdayOption(value: 3, label: 'T4'),
    _WeekdayOption(value: 4, label: 'T5'),
    _WeekdayOption(value: 5, label: 'T6'),
    _WeekdayOption(value: 6, label: 'T7'),
    _WeekdayOption(value: 7, label: 'CN'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = ShiftFormController(initialItem: widget.initialItem);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _pageTitle =>
      _controller.isEditing ? 'Chi tiết xếp ca' : 'Tạo xếp ca';

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

  Future<List<CompanyDirectoryItem>?> _showMultiPicker({
    required String title,
    required List<CompanyDirectoryItem> items,
    required List<String> selectedIds,
  }) async {
    final draft = {...selectedIds};

    return showModalBottomSheet<List<CompanyDirectoryItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = draft.contains(item.id);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) {
                                setModalState(() {
                                  if (isSelected) {
                                    draft.remove(item.id);
                                  } else {
                                    draft.add(item.id);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final selected = items
                                .where((item) => draft.contains(item.id))
                                .toList();
                            Navigator.of(context).pop(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Xác nhận'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickRegion() async {
    final selected = await _showMultiPicker(
      title: 'Chọn vùng',
      items: _controller.regions,
      selectedIds: _controller.selectedRegionIds,
    );
    if (selected != null) {
      _controller.replaceSelectedRegions(selected);
    }
  }

  Future<void> _pickBranch() async {
    final selected = await _showMultiPicker(
      title: 'Chọn chi nhánh',
      items: _controller.branches,
      selectedIds: _controller.selectedBranchIds,
    );
    if (selected != null) {
      _controller.replaceSelectedBranches(selected);
    }
  }

  Future<void> _pickDepartments() async {
    final selected = await _showMultiPicker(
      title: 'Chọn phòng ban',
      items: _controller.departments,
      selectedIds: _controller.selectedDepartmentIds,
    );
    if (selected != null) {
      _controller.replaceSelectedDepartments(selected);
    }
  }

  Future<void> _pickJobTitles() async {
    final selected = await _showMultiPicker(
      title: 'Chọn chức vụ',
      items: _controller.jobTitles,
      selectedIds: _controller.selectedJobTitleIds,
    );
    if (selected != null) {
      _controller.replaceSelectedJobTitles(selected);
    }
  }

  Future<void> _pickTimeValue({
    required String title,
    required TextEditingController controller,
    required List<String> options,
    required String suffix,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final currentValue = controller.text.trim();
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
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option == currentValue;
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(option),
                        title: Text('$option $suffix'),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
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

    if (selected != null) {
      controller.text = selected;
      if (mounted) {
        setState(() {});
      }
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
                  : Text(_controller.isEditing ? 'Lưu' : 'Tạo'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _FieldSection(
                  label: 'Tên ca',
                  isRequired: true,
                  child: _TextFieldBox(
                    controller: _controller.nameController,
                    hintText: 'Nhập tên ca',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel(title: 'Giờ làm', isRequired: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelectorField(
                        controller: _controller.startHourController,
                        hintText: 'Giờ bắt đầu',
                        suffix: 'giờ',
                        onTap: () => _pickTimeValue(
                          title: 'Chọn giờ bắt đầu',
                          controller: _controller.startHourController,
                          options: _hourOptions,
                          suffix: 'giờ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeSelectorField(
                        controller: _controller.startMinuteController,
                        hintText: 'Phút bắt đầu',
                        suffix: 'phút',
                        onTap: () => _pickTimeValue(
                          title: 'Chọn phút bắt đầu',
                          controller: _controller.startMinuteController,
                          options: _minuteOptions,
                          suffix: 'phút',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelectorField(
                        controller: _controller.endHourController,
                        hintText: 'Giờ kết thúc',
                        suffix: 'giờ',
                        onTap: () => _pickTimeValue(
                          title: 'Chọn giờ kết thúc',
                          controller: _controller.endHourController,
                          options: _hourOptions,
                          suffix: 'giờ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeSelectorField(
                        controller: _controller.endMinuteController,
                        hintText: 'Phút kết thúc',
                        suffix: 'phút',
                        onTap: () => _pickTimeValue(
                          title: 'Chọn phút kết thúc',
                          controller: _controller.endMinuteController,
                          options: _minuteOptions,
                          suffix: 'phút',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FieldSection(
                  label: 'Vùng',
                  isRequired: true,
                  child: _SelectorField(
                    label: _controller.selectedRegionNames.isEmpty
                        ? 'Chọn vùng'
                        : _controller.selectedRegionNames.join(', '),
                    onTap: _pickRegion,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldSection(
                  label: 'Chi nhánh',
                  isRequired: true,
                  child: _SelectorField(
                    label: _controller.selectedBranchNames.isEmpty
                        ? 'Chọn chi nhánh'
                        : _controller.selectedBranchNames.join(', '),
                    onTap: _pickBranch,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldSection(
                  label: 'Phòng ban',
                  isRequired: true,
                  child: _SelectorField(
                    label: _controller.selectedDepartmentNames.isEmpty
                        ? 'Chọn phòng ban'
                        : _controller.selectedDepartmentNames.join(', '),
                    onTap: _pickDepartments,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldSection(
                  label: 'Chức vụ',
                  isRequired: true,
                  child: _SelectorField(
                    label: _controller.selectedJobTitleNames.isEmpty
                        ? 'Chọn chức vụ'
                        : _controller.selectedJobTitleNames.join(', '),
                    onTap: _pickJobTitles,
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel(title: 'Ngày làm việc', isRequired: true),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _weekdayOptions.map((option) {
                    final isSelected =
                        _controller.selectedWeekdays.contains(option.value);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (_) =>
                          _controller.toggleWeekday(option.value),
                      label: Text(option.label),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeekdayOption {
  const _WeekdayOption({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;
}

class _FieldSection extends StatelessWidget {
  const _FieldSection({
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

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

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
          borderSide: const BorderSide(color: AppColors.divider),
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

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    this.onTap,
  });

  final String label;
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
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: label.startsWith('Chọn')
                        ? AppColors.muted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelectorField extends StatelessWidget {
  const _TimeSelectorField({
    required this.controller,
    required this.hintText,
    required this.suffix,
    required this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final String suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = controller.text.trim();
    final label = value.isEmpty ? hintText : '$value $suffix';

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
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        value.isEmpty ? AppColors.muted : AppColors.textPrimary,
                  ),
                ),
              ),
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
