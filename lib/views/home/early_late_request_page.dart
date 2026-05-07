import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../models/employee_list_item.dart';
import '../../models/shift_item.dart';
import '../../services/auth_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/shift_service.dart';

class EarlyLateRequestPage extends StatefulWidget {
  const EarlyLateRequestPage({super.key});

  @override
  State<EarlyLateRequestPage> createState() => _EarlyLateRequestPageState();
}

class _EarlyLateRequestPageState extends State<EarlyLateRequestPage> {
  final TextEditingController _reasonController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final ShiftService _shiftService = ShiftService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;
  Future<void>? _shiftLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  DateTime? _startTime;
  DateTime? _endTime;
  String _selectedShiftId = '';
  String _selectedShiftName = 'Chọn ca làm';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingShifts = false;
  List<EmployeeListItem> _employees = [];
  List<ShiftItem> _shifts = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadShifts();
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

  Future<void> _loadShifts() async {
    final currentTask = _shiftLoadTask;
    if (currentTask != null) return currentTask;

    final task = () async {
      setState(() => _isLoadingShifts = true);
      try {
        final shifts = await _shiftService.listShifts();
        if (mounted) setState(() => _shifts = shifts);
      } catch (e) {
        if (mounted) {
          AppNotice.showError(context, 'Lỗi tải danh sách ca làm: $e');
        }
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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_startTime == null) {
      AppNotice.showError(context, 'Vui lòng chọn giờ bắt đầu');
      return;
    }
    if (_endTime == null) {
      AppNotice.showError(context, 'Vui lòng chọn giờ kết thúc');
      return;
    }
    if (!_endTime!.isAfter(_startTime!)) {
      AppNotice.showError(context, 'Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }
    if (_selectedShiftName == 'Chọn ca làm') {
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
        requestType: 'Đi sớm, về muộn',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Giờ bắt đầu': _formatDateTime(_startTime!),
          'Giờ kết thúc': _formatDateTime(_endTime!),
          'Ca làm': _selectedShiftName,
          if (_selectedShiftId.isNotEmpty) 'Mã ca làm': _selectedShiftId,
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

  Future<void> _pickStartTime() async {
    final picked = await _pickDateTime(_startTime ?? DateTime.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await _pickDateTime(_endTime ?? _startTime ?? DateTime.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initialDateTime) {
    final today = DateTime.now();
    final dates = _dateOptions(today);
    final initialDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );
    final initialDateIndex = dates.indexWhere((item) => _sameDay(item, initialDate));
    var selectedHour = initialDateTime.hour;
    var selectedMinute = initialDateTime.minute;
    var selectedDate = initialDateIndex >= 0 ? dates[initialDateIndex] : initialDate;

    final hourController = FixedExtentScrollController(
      initialItem: selectedHour,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );
    final dateController = FixedExtentScrollController(
      initialItem: initialDateIndex >= 0 ? initialDateIndex : 90,
    );

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
          ),
          child: SizedBox(
            height: 455,
            child: Column(
              children: [
                const SizedBox(height: 28),
                const Text(
                  'Chọn',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: hourController,
                            itemExtent: 54,
                            magnification: 1.08,
                            useMagnifier: true,
                            onSelectedItemChanged: (index) {
                              selectedHour = index;
                            },
                            children: [
                              for (var hour = 0; hour < 24; hour++)
                                Center(
                                  child: Text(hour.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: minuteController,
                            itemExtent: 54,
                            magnification: 1.08,
                            useMagnifier: true,
                            onSelectedItemChanged: (index) {
                              selectedMinute = index;
                            },
                            children: [
                              for (var minute = 0; minute < 60; minute++)
                                Center(
                                  child:
                                      Text(minute.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker.builder(
                            scrollController: dateController,
                            itemExtent: 54,
                            magnification: 1.08,
                            useMagnifier: true,
                            childCount: dates.length,
                            onSelectedItemChanged: (index) {
                              selectedDate = dates[index];
                            },
                            itemBuilder: (context, index) {
                              return Center(
                                child: Text(_dateLabel(dates[index], today)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 68,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16C879),
                              side: const BorderSide(
                                color: Color(0xFF16C879),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('HỦY'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 68,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedHour,
                                  selectedMinute,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16C879),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('XONG'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/${dateTime.year}';
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final today = DateTime.now();
    final isToday = dateTime.year == today.year &&
        dateTime.month == today.month &&
        dateTime.day == today.day;
    if (isToday) {
      return '$hour:$minute';
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/${dateTime.year}';
  }

  List<DateTime> _dateOptions(DateTime today) {
    final base = DateTime(today.year, today.month, today.day);
    return [
      for (var offset = -90; offset <= 365; offset++)
        base.add(Duration(days: offset)),
    ];
  }

  String _dateLabel(DateTime date, DateTime today) {
    if (_sameDay(date, today)) {
      return 'Hôm nay';
    }

    const weekdays = <int, String>{
      DateTime.monday: 'Th 2',
      DateTime.tuesday: 'Th 3',
      DateTime.wednesday: 'Th 4',
      DateTime.thursday: 'Th 5',
      DateTime.friday: 'Th 6',
      DateTime.saturday: 'Th 7',
      DateTime.sunday: 'CN',
    };
    return '${weekdays[date.weekday]} ${date.day} thg ${date.month}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Đi sớm, về muộn',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
            _SelectorCard(
              icon: Icons.people_outline_rounded,
              value: _selectedEmployeeName,
              onTap: _pickEmployee,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_today_outlined,
              value: _startTime == null
                  ? 'Giờ bắt đầu'
                  : _formatTimeLabel(_startTime!),
              onTap: _pickStartTime,
              requiredMark: true,
              isPlaceholder: _startTime == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_today_outlined,
              value:
                  _endTime == null ? 'Giờ kết thúc' : _formatTimeLabel(_endTime!),
              onTap: _pickEndTime,
              requiredMark: true,
              isPlaceholder: _endTime == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.grid_view_rounded,
              value: _selectedShiftName,
              onTap: _pickShift,
              requiredMark: true,
              isPlaceholder: _selectedShiftName == 'Chọn ca làm',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Nhập vào lý do',
              controller: _reasonController,
              maxLines: 5,
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
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
              textAlignVertical:
                  maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
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