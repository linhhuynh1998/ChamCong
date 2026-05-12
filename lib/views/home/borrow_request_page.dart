import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../models/employee_list_item.dart';
import '../../services/auth_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/request_employee_access.dart';

class BorrowRequestPage extends StatefulWidget {
  const BorrowRequestPage({super.key});

  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  final TextEditingController _noteController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  String _selectedBorrowDate = '05/05/2026';
  String _selectedReturnDate = '05/05/2026';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _canSelectEmployee = false;
  List<EmployeeListItem> _employees = [];
  final List<_BorrowDetailControllers> _details = [
    _BorrowDetailControllers(),
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
    _noteController.dispose();
    for (final detail in _details) {
      detail.dispose();
    }
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập ghi chú');
      return;
    }

    final details = _buildDetailsPayload();
    if (details.isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập ít nhất một dòng chi tiết');
      return;
    }

    setState(() => _isSubmitting = true);
    AppLoading.show(message: 'Đang gửi yêu cầu...');
    try {
      final profile = await _authService.me();
      final message = await _requestsService.createRequest(
        companyId: profile.companyId,
        requestType: 'Mượn',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Ngày mượn': _apiDateFromDisplayDate(_selectedBorrowDate),
          'Ngày trả': _apiDateFromDisplayDate(_selectedReturnDate),
          'Ghi chú': _noteController.text.trim(),
        },
        details: details,
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

  List<Map<String, dynamic>> _buildDetailsPayload() {
    final payload = <Map<String, dynamic>>[];
    for (var index = 0; index < _details.length; index++) {
      final detail = _details[index];
      final content = detail.contentController.text.trim();
      final quantity = _numberValue(detail.quantityController);
      final note = detail.noteController.text.trim();

      if (content.isEmpty && quantity == 0 && note.isEmpty) {
        continue;
      }
      if (content.isEmpty || quantity <= 0) {
        continue;
      }

      payload.add(<String, dynamic>{
        'Mục': index + 1,
        'Nội dung': content,
        'Số lượng': quantity,
        if (note.isNotEmpty) 'Ghi chú': note,
      });
    }
    return payload;
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
      isSelected: (item) => item.id == _selectedEmployeeId,
    );
    if (selected != null) {
      setState(() {
        _selectedEmployeeId = selected.id;
        _selectedEmployeeName = selected.name;
      });
    }
  }

  Future<void> _pickBorrowDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 5),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _selectedBorrowDate = _formatDate(picked));
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 5),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _selectedReturnDate = _formatDate(picked));
  }

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelOf,
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

  int _numberValue(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _addDetail() {
    setState(() => _details.add(_BorrowDetailControllers()));
  }

  void _removeDetail(int index) {
    if (_details.length == 1) return;
    final removed = _details.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Mượn',
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
              icon: Icons.person_outline_rounded,
              value: _selectedEmployeeName,
              onTap: _pickEmployee,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_month_outlined,
              value: _selectedBorrowDate,
              onTap: _pickBorrowDate,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.calendar_month_outlined,
              value: _selectedReturnDate,
              onTap: _pickReturnDate,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Ghi chú',
              controller: _noteController,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            _DetailHeader(onAdd: _addDetail),
            const SizedBox(height: RequestFormStyle.compactGap),
            for (var index = 0; index < _details.length; index++) ...[
              _DetailCard(
                index: index,
                detail: _details[index],
                canRemove: _details.length > 1,
                onChanged: () => setState(() {}),
                onRemove: () => _removeDetail(index),
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 8),
            _AttachmentCard(),
          ],
        ),
      ),
    );
  }
}

class _BorrowDetailControllers {
  final TextEditingController contentController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  void dispose() {
    contentController.dispose();
    quantityController.dispose();
    noteController.dispose();
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 34),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.index,
    required this.detail,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _BorrowDetailControllers detail;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF223B63).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mục ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.sectionHeader,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.muted,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _InputCard(
            icon: Icons.chat_bubble_outline_rounded,
            hintText: 'Nội dung',
            controller: detail.contentController,
            requiredMark: true,
          ),
          const SizedBox(height: 18),
          _InputCard(
            icon: Icons.confirmation_number_outlined,
            hintText: 'Số lượng',
            controller: detail.quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: const [_ThousandsSeparatorInputFormatter()],
            onChanged: (_) => onChanged(),
            requiredMark: true,
          ),
        ],
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
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool requiredMark;

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
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
    this.onChanged,
    this.maxLines = 1,
    this.requiredMark = false,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
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
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
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

class _AttachmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RequestFormStyle.fieldBackground,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.create_new_folder_outlined,
              size: RequestFormStyle.iconSize, color: AppColors.muted),
          const SizedBox(width: RequestFormStyle.iconTextGap),
          const Expanded(
            child: Text(
              'Tài liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => AppNotice.showInfo(
              context,
              'Chức năng thêm tài liệu sẽ được cập nhật thêm.',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(RequestFormStyle.fieldRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Thêm'),
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
