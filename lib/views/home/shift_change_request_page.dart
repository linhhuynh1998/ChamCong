import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../core/widgets/request_picker_sheet.dart';
import '../../models/employee_list_item.dart';
import '../../models/shift_item.dart';
import '../../services/auth_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/shift_service.dart';

class ShiftChangeRequestPage extends StatefulWidget {
  const ShiftChangeRequestPage({super.key});

  @override
  State<ShiftChangeRequestPage> createState() => _ShiftChangeRequestPageState();
}

class _ShiftChangeRequestPageState extends State<ShiftChangeRequestPage> {
  final TextEditingController _reasonController = TextEditingController();

  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final ShiftService _shiftService = ShiftService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;
  Future<void>? _shiftLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  DateTime? _selectedDate;
  String _selectedShiftId = '';
  String _selectedShiftName = 'Chọn ca làm';
  String _selectedReceiverId = '';
  String _selectedReceiverName = 'Chọn nhân viên';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingShifts = false;
  List<EmployeeListItem> _employees = [];
  List<ShiftItem> _shifts = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadEmployees();
    _loadShifts();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
        if (mounted) AppNotice.showError(context, 'Lỗi tải danh sách nhân viên: $e');
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

  Future<void> _loadShifts() async {
    final currentTask = _shiftLoadTask;
    if (currentTask != null) return currentTask;

    final task = () async {
      setState(() => _isLoadingShifts = true);
      try {
        final shifts = await _shiftService.listShifts();
        if (mounted) setState(() => _shifts = shifts);
      } catch (e) {
        if (mounted) AppNotice.showError(context, 'Lỗi tải danh sách ca làm: $e');
      } finally {
        if (mounted) setState(() => _isLoadingShifts = false);
      }
    }();

    _shiftLoadTask = task;
    try {
      await task;
    } finally {
      if (_shiftLoadTask == task) _shiftLoadTask = null;
    }
  }

  Future<void> _pickEmployee() async {
    if (_isLoadingEmployees || _employees.isEmpty) {
      await _loadEmployees();
      if (!mounted) return;
    }
    if (_employees.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu nhân viên để chọn.');
      return;
    }

    final selected = await _showPicker<EmployeeListItem>(
      title: 'Chọn nhân viên thay đổi',
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

  Future<void> _pickReceiver() async {
    if (_isLoadingEmployees || _employees.isEmpty) {
      await _loadEmployees();
      if (!mounted) return;
    }
    if (_employees.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu nhân viên để chọn.');
      return;
    }

    final selected = await _showPicker<EmployeeListItem>(
      title: 'Chọn nhân viên nhận thay đổi',
      items: _employees,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.employeeCode,
      isSelected: (item) => item.id == _selectedReceiverId,
    );

    if (selected != null) {
      setState(() {
        _selectedReceiverId = selected.id;
        _selectedReceiverName = selected.name;
      });
    }
  }

  Future<void> _pickShift() async {
    if (_isLoadingShifts || _shifts.isEmpty) {
      await _loadShifts();
      if (!mounted) return;
    }
    if (_shifts.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu ca làm để chọn.');
      return;
    }

    final selected = await _showPicker<ShiftItem>(
      title: 'Chọn ca làm',
      items: _shifts,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.timeRange,
      isSelected: (item) => item.id == _selectedShiftId,
    );

    if (selected != null) {
      setState(() {
        _selectedShiftId = selected.id;
        _selectedShiftName = selected.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên thay đổi');
      return;
    }
    if (_selectedDate == null) {
      AppNotice.showError(context, 'Vui lòng chọn ngày');
      return;
    }
    if (_selectedShiftId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn ca làm');
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
        requestType: 'Đổi ca làm',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên thay đổi': _selectedEmployeeName,
          'Ngày': _apiDateFromDisplayDate(_formatDate(_selectedDate!)),
          'Ca làm': _selectedShiftName,
          if (_selectedShiftId.isNotEmpty) 'Mã ca làm': _selectedShiftId,
          'Lý do': _reasonController.text.trim(),
          if (_selectedReceiverId.isNotEmpty) 'Nhân viên nhận thay đổi': _selectedReceiverName,
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

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required String Function(T) subtitleOf,
    required bool Function(T) isSelected,
  }) {
    return showRequestPickerSheet<T>(
      context: context,
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      isSelected: isSelected,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Đổi ca làm',
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi', style: PrimarySectionAppBar.actionTextStyle),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: RequestFormStyle.pagePadding,
          children: [
            const Text(
              'Nhân viên thay đổi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: RequestFormStyle.compactGap),
            _SelectorCard(
              icon: Icons.people_outline_rounded,
              value: _selectedEmployeeName,
              onTap: _pickEmployee,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_today_outlined,
              value: _selectedDate == null ? 'Chọn ngày' : _formatDate(_selectedDate!),
              onTap: _pickDate,
              requiredMark: true,
              isPlaceholder: _selectedDate == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.grid_view_rounded,
              value: _selectedShiftName,
              onTap: _pickShift,
              requiredMark: true,
              isPlaceholder: _selectedShiftId.isEmpty,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Lý do',
              controller: _reasonController,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            const Text(
              'Nhận thay đổi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: RequestFormStyle.compactGap),
            _SelectorCard(
              icon: Icons.people_outline_rounded,
              value: _selectedReceiverName,
              onTap: _pickReceiver,
              isPlaceholder: _selectedReceiverId.isEmpty,
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
          constraints: const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
          padding: RequestFormStyle.fieldPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: RequestFormStyle.iconSize, color: AppColors.muted),
              const SizedBox(width: RequestFormStyle.iconTextGap),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (requiredMark)
                        const TextSpan(
                          text: '* ',
                          style: TextStyle(color: RequestFormStyle.requiredColor, fontSize: 16),
                        ),
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isPlaceholder ? AppColors.muted : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: RequestFormStyle.iconSize),
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
    this.maxLines = 1,
    this.requiredMark = false,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: maxLines > 1 ? RequestFormStyle.multilineMinHeight : RequestFormStyle.fieldMinHeight),
      padding: RequestFormStyle.fieldPadding,
      decoration: BoxDecoration(
        color: RequestFormStyle.fieldBackground,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 3 : 0),
            child: Icon(icon, size: RequestFormStyle.iconSize, color: AppColors.muted),
          ),
          const SizedBox(width: RequestFormStyle.iconTextGap),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: maxLines > 1 ? maxLines : 1,
              textAlignVertical: maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
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
