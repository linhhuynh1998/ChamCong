import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../models/employee_list_item.dart';
import '../../models/location_option.dart';
import '../../services/auth_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/request_employee_access.dart';

class DisciplineRequestPage extends StatefulWidget {
  const DisciplineRequestPage({super.key});

  @override
  State<DisciplineRequestPage> createState() => _DisciplineRequestPageState();
}

class _DisciplineRequestPageState extends State<DisciplineRequestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _fineController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  String _selectedDate = '05/05/2026';
  String _selectedTypeId = '';
  String _selectedType = 'Chọn loại';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _canSelectEmployee = false;
  List<EmployeeListItem> _employees = [];

  final List<LocationOption> _disciplineTypes = const [
    LocationOption(id: 'cach_chuc', name: 'Cách chức'),
    LocationOption(id: 'sa_thai', name: 'Sa thải'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final profile = await _authService.me();
      if (!mounted) return;

      final canSelectEmployee =
          RequestEmployeeAccess.canSelectEmployee(profile);
      setState(() {
        _canSelectEmployee = canSelectEmployee;
        if (!canSelectEmployee) {
          _selectedEmployeeId = profile.id;
          _selectedEmployeeName = RequestEmployeeAccess.employeeName(profile);
        }
      });

      if (canSelectEmployee) {
        await _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        AppNotice.showError(context, 'Lỗi tải thông tin nhân viên: $e');
      }
    } finally {
      if (mounted && !_canSelectEmployee) {
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    final currentTask = _employeeLoadTask;
    if (currentTask != null) return currentTask;

    final task = () async {
      setState(() => _isLoadingEmployees = true);
      try {
        final employees = await _employeeService.listEmployees();
        if (mounted) setState(() => _employees = employees);
      } catch (e) {
        if (mounted) {
          AppNotice.showError(context, 'Lỗi tải danh sách nhân viên: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoadingEmployees = false);
      }
    }();

    _employeeLoadTask = task;
    try {
      await task;
    } finally {
      if (_employeeLoadTask == task) _employeeLoadTask = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fineController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập tiêu đề');
      return;
    }
    if (_selectedType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại kỷ luật');
      return;
    }
    if (_fineController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập tiền phạt');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập lý do');
      return;
    }

    setState(() => _isSubmitting = true);
    AppLoading.show(message: 'Đang gửi yêu cầu...');
    try {
      final profile = await _authService.me();
      final message = await _requestsService.createRequest(
        companyId: profile.companyId,
        requestType: 'Kỷ luật',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Ngày': _apiDateFromDisplayDate(_selectedDate),
          'Tiêu đề': _titleController.text.trim(),
          'Loại': _selectedType,
          'Tiền phạt': _fineValue,
          'Lý do': _reasonController.text.trim(),
        },
      );
      AppLoading.hide();
      if (!mounted) return;

      AppNotice.showSuccess(context, message);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.requestManagement,
        (route) => route.isFirst,
      );
    } catch (e) {
      AppLoading.hide();
      if (!mounted) return;
      AppNotice.showError(context, 'Lỗi: $e');
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickEmployee() async {
    if (!_canSelectEmployee) {
      return;
    }

    if (_isLoadingEmployees || _employees.isEmpty) {
      await _loadEmployees();
      if (!mounted) return;
    }
    if (_employees.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu nhân viên để chọn.');
      return;
    }

    final selected = await _showPicker<EmployeeListItem>(
      title: 'Chọn nhân viên',
      items: _employees,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.employeeCode,
      isSelected: (item) => item.id == _selectedEmployeeId,
    );
    if (selected != null) {
      setState(() {
        _selectedEmployeeId = selected.id;
        _selectedEmployeeName = selected.name;
      });
    }
  }

  Future<void> _pickType() async {
    final selected = await _showPicker<LocationOption>(
      title: 'Chọn loại kỷ luật',
      items: _disciplineTypes,
      labelOf: (item) => item.name,
      subtitleOf: (_) => '',
      isSelected: (item) => item.id == _selectedTypeId,
    );
    if (selected != null) {
      setState(() {
        _selectedTypeId = selected.id;
        _selectedType = selected.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 5),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = _formatDate(picked);
    });
  }

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelOf,
    required String Function(T item) subtitleOf,
    required bool Function(T item) isSelected,
  }) {
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
                    fontSize: 16,
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
                      final subtitle = subtitleOf(item);

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          labelOf(item),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        trailing: isSelected(item)
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _apiDateFromDisplayDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return value;

    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  int get _fineValue {
    final digits = _fineController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Kỷ luật',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              style: PrimarySectionAppBar.actionButtonStyle,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi',
                      style: PrimarySectionAppBar.actionTextStyle),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: RequestFormStyle.pagePadding,
          children: [
            _SelectorCard(
              icon: Icons.people_outline_rounded,
              value: _selectedEmployeeName,
              onTap: _pickEmployee,
              isPlaceholder: _selectedEmployeeId.isEmpty,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_today_outlined,
              value: _selectedDate,
              onTap: _pickDate,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Tiêu đề',
              controller: _titleController,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.grid_view_rounded,
              value: _selectedType,
              onTap: _pickType,
              requiredMark: true,
              isPlaceholder: _selectedType == 'Chọn loại',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.request_quote_outlined,
              hintText: 'Tiền phạt',
              controller: _fineController,
              keyboardType: TextInputType.number,
              inputFormatters: const [_ThousandsSeparatorInputFormatter()],
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Lý do',
              controller: _reasonController,
              requiredMark: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.icon,
    required this.value,
    required this.onTap,
    this.requiredMark = false,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool requiredMark;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RequestFormStyle.fieldBackground,
      borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        onTap: onTap,
        child: Container(
          constraints:
              const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
          padding: RequestFormStyle.fieldPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: RequestFormStyle.iconSize, color: AppColors.muted),
              const SizedBox(width: RequestFormStyle.iconTextGap),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (requiredMark)
                        const TextSpan(
                          text: '* ',
                          style: TextStyle(
                            color: RequestFormStyle.requiredColor,
                            fontSize: 16,
                          ),
                        ),
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isPlaceholder
                              ? AppColors.muted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: RequestFormStyle.iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.icon,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.requiredMark = false,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
      padding: RequestFormStyle.fieldPadding,
      decoration: BoxDecoration(
        color: RequestFormStyle.fieldBackground,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: RequestFormStyle.iconSize, color: AppColors.muted),
          const SizedBox(width: RequestFormStyle.iconTextGap),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                hintText: requiredMark ? '* $hintText' : hintText,
                hintStyle: RequestFormStyle.hintTextStyle,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const _ThousandsSeparatorInputFormatter();

  static String formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final formatted = formatNumber(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
