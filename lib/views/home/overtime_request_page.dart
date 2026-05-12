import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../core/widgets/request_picker_sheet.dart';
import '../../models/company_directory_item.dart';
import '../../models/employee_list_item.dart';
import '../../services/auth_service.dart';
import '../../services/company_directory_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/request_employee_access.dart';

class OvertimeRequestPage extends StatefulWidget {
  const OvertimeRequestPage({super.key});

  @override
  State<OvertimeRequestPage> createState() => OvertimeRequestPageState();
}

class OvertimeRequestPageState extends State<OvertimeRequestPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _ratioController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final AuthService _authService = AuthService();
  final CompanyDirectoryService _companyDirectoryService =
      CompanyDirectoryService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;
  Future<void>? _branchLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  String _selectedOvertimeType = 'Chọn loại';
  String _selectedBranchId = '';
  String _selectedBranchName = 'Chọn chi nhánh';
  DateTime? _startTime;
  DateTime? _endTime;

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _canSelectEmployee = false;
  bool _isLoadingBranches = false;
  List<EmployeeListItem> _employees = [];
  List<CompanyDirectoryItem> _branches = [];

  List<String> get _overtimeTypes => const [
        'Ngày thường',
        'Ngày Chủ nhật',
        'Ngày lễ',
      ];

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
    _loadBranches();
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

  Future<void> _loadBranches() async {
    final currentTask = _branchLoadTask;
    if (currentTask != null) return currentTask;

    final task = () async {
      setState(() => _isLoadingBranches = true);
      try {
        final branches =
            await _companyDirectoryService.listItems('/company/branches');
        if (mounted) setState(() => _branches = branches);
      } catch (e) {
        if (mounted) {
          AppNotice.showError(context, 'Lỗi tải danh sách chi nhánh: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoadingBranches = false);
      }
    }();

    _branchLoadTask = task;
    try {
      await task;
    } finally {
      if (_branchLoadTask == task) _branchLoadTask = null;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _ratioController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_selectedOvertimeType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại làm thêm giờ');
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
    if (_endTime!.isBefore(_startTime!)) {
      AppNotice.showError(context, 'Giờ kết thúc phải sau giờ bắt đầu');
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
        requestType: 'Làm thêm giờ',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Loại': _selectedOvertimeType,
          'Giờ bắt đầu':
              '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          'Giờ kết thúc':
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
          if (_quantityController.text.trim().isNotEmpty)
            'Số giờ': _quantityController.text.trim(),
          if (_ratioController.text.trim().isNotEmpty)
            'Tỷ lệ': _ratioController.text.trim(),
          if (_selectedBranchId.isNotEmpty) 'Chi nhánh': _selectedBranchName,
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

  Future<void> _pickOvertimeType() async {
    final selected = await _showPicker<String>(
      title: 'Chọn loại làm thêm giờ',
      items: _overtimeTypes,
      labelOf: (item) => item,
      subtitleOf: (item) => '',
      isSelected: (item) => item == _selectedOvertimeType,
    );
    if (selected != null) {
      setState(() => _selectedOvertimeType = selected);
    }
  }

  Future<void> _pickBranch() async {
    if (_isLoadingBranches || _branches.isEmpty) {
      await _loadBranches();
      if (!mounted) return;
    }
    if (_branches.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu chi nhánh để chọn.');
      return;
    }

    final selected = await _showPicker<CompanyDirectoryItem>(
      title: 'Chọn chi nhánh',
      items: _branches,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.description,
      isSelected: (item) => item.id == _selectedBranchId,
    );
    if (selected != null) {
      setState(() {
        _selectedBranchId = selected.id;
        _selectedBranchName = selected.name;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await _pickTime(_startTime ?? DateTime.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await _pickTime(_endTime ?? _startTime ?? DateTime.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<DateTime?> _pickTime(DateTime initialDateTime) {
    var selectedHour = initialDateTime.hour;
    var selectedMinute = initialDateTime.minute;

    final hourController = FixedExtentScrollController(
      initialItem: selectedHour,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
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
            height: 350,
            child: Column(
              children: [
                const SizedBox(height: 28),
                const Text(
                  'Chọn giờ',
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
                                borderRadius: BorderRadius.circular(
                                    RequestFormStyle.fieldRadius),
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
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
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
                                borderRadius: BorderRadius.circular(
                                    RequestFormStyle.fieldRadius),
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
    required String Function(T) labelOf,
    required String Function(T) subtitleOf,
    required bool Function(T) isSelected,
  }) async {
    return showRequestPickerSheet<T>(
      context: context,
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      isSelected: isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Làm thêm giờ',
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
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.category_outlined,
              value: _selectedOvertimeType,
              onTap: _pickOvertimeType,
              requiredMark: true,
              isPlaceholder: _selectedOvertimeType == 'Chọn loại',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.access_time_outlined,
              value: _startTime == null
                  ? 'Giờ bắt đầu'
                  : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
              onTap: _pickStartTime,
              requiredMark: true,
              isPlaceholder: _startTime == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.access_time_outlined,
              value: _endTime == null
                  ? 'Giờ kết thúc'
                  : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
              onTap: _pickEndTime,
              requiredMark: true,
              isPlaceholder: _endTime == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.numbers,
              hintText: 'Nhập số giờ',
              controller: _quantityController,
              maxLines: 1,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.info_outline,
              hintText: 'Nhập tỉ lệ',
              controller: _ratioController,
              maxLines: 1,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.business_outlined,
              value: _selectedBranchName,
              onTap: _pickBranch,
              isPlaceholder: _selectedBranchName == 'Chọn chi nhánh',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Nhập vào lý do',
              controller: _reasonController,
              maxLines: 4,
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
      constraints: BoxConstraints(
          minHeight: maxLines > 1
              ? RequestFormStyle.multilineMinHeight
              : RequestFormStyle.fieldMinHeight),
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
            child: Icon(icon,
                size: RequestFormStyle.iconSize, color: AppColors.muted),
          ),
          const SizedBox(width: RequestFormStyle.iconTextGap),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: maxLines > 1 ? maxLines : 1,
              textAlignVertical: maxLines > 1
                  ? TextAlignVertical.top
                  : TextAlignVertical.center,
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
