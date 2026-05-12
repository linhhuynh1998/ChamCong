import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/currency_input_formatter.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../core/widgets/request_form_style.dart';
import '../../core/widgets/request_picker_sheet.dart';
import '../../models/employee_list_item.dart';
import '../../models/location_option.dart';
import '../../services/auth_service.dart';
import '../../services/employee_directory_service.dart';
import '../../services/requests_service.dart';
import '../../services/request_employee_access.dart';

class PurchaseRequestPage extends StatefulWidget {
  const PurchaseRequestPage({super.key});

  @override
  State<PurchaseRequestPage> createState() => _PurchaseRequestPageState();
}

class _PurchaseRequestPageState extends State<PurchaseRequestPage> {
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestsService _requestsService = RequestsService();

  final TextEditingController _noteController = TextEditingController();

  Future<void>? _employeeLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  DateTime? _selectedDate;
  String _selectedType = 'Chọn loại';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _canSelectEmployee = false;
  List<EmployeeListItem> _employees = [];
  final List<_PurchaseDetailControllers> _details = [
    _PurchaseDetailControllers()
  ];

  final List<LocationOption> _purchaseTypes = const [
    LocationOption(id: 'van_phong_pham', name: 'Văn phòng phẩm'),
    LocationOption(id: 'trang_thiet_bi', name: 'Trang thiết bị'),
    LocationOption(id: 'khac', name: 'Khác'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadCurrentEmployee();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final d in _details) {
      d.dispose();
    }
    super.dispose();
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
        if (mounted)
          AppNotice.showError(context, 'Lỗi tải danh sách nhân viên: $e');
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
      title: 'Chọn loại',
      items: _purchaseTypes,
      labelOf: (item) => item.name,
      subtitleOf: (_) => '',
      isSelected: (item) => item.name == _selectedType,
    );

    if (selected != null) {
      setState(() => _selectedType = selected.name);
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

  void _addDetail() {
    setState(() => _details.add(_PurchaseDetailControllers()));
  }

  List<Map<String, dynamic>> _buildDetails() {
    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < _details.length; i++) {
      final d = _details[i];
      final name = d.nameController.text.trim();
      final qty = d.quantity;
      final price = d.price;
      if (name.isEmpty && qty == 0 && price == 0) {
        continue;
      }
      if (name.isEmpty || qty <= 0 || price <= 0) {
        continue;
      }

      payload.add(<String, dynamic>{
        'Mục': i + 1,
        'Tên sản phẩm': name,
        'Số lượng': qty,
        'Giá thành': price,
        'Thành tiền': qty * price,
      });
    }
    return payload;
  }

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_selectedDate == null) {
      AppNotice.showError(context, 'Vui lòng chọn ngày');
      return;
    }
    if (_selectedType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại');
      return;
    }

    final details = _buildDetails();
    if (details.isEmpty) {
      AppNotice.showError(
          context, 'Vui lòng nhập ít nhất một mục chi tiết hợp lệ');
      return;
    }

    setState(() => _isSubmitting = true);
    AppLoading.show(message: 'Đang gửi yêu cầu...');
    try {
      final profile = await _authService.me();
      final total = details.fold<num>(
          0, (sum, d) => sum + ((d['Thành tiền'] as num?) ?? 0));
      final message = await _requestsService.createRequest(
        companyId: profile.companyId,
        requestType: 'Mua hàng',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Ngày': _apiDateFromDisplayDate(_formatDate(_selectedDate!)),
          'Loại': _selectedType,
          if (_noteController.text.trim().isNotEmpty)
            'Ghi chú': _noteController.text.trim(),
          'Tổng số tiền': total,
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
        title: 'Mua hàng',
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
                          strokeWidth: 2, color: Colors.white),
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
              icon: Icons.calendar_today_outlined,
              value: _selectedDate == null
                  ? 'Chọn ngày'
                  : _formatDate(_selectedDate!),
              onTap: _pickDate,
              requiredMark: true,
              isPlaceholder: _selectedDate == null,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.wallet_outlined,
              value: _selectedType,
              onTap: _pickType,
              isPlaceholder: _selectedType == 'Chọn loại',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.chat_bubble_outline_rounded,
              hintText: 'Ghi chú',
              controller: _noteController,
              maxLines: 4,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                IconButton(
                  onPressed: _addDetail,
                  icon:
                      const Icon(Icons.add, color: Color(0xFF16C879), size: 34),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < _details.length; i++) ...[
              _PurchaseDetailCard(index: i + 1, controllers: _details[i]),
              const SizedBox(height: RequestFormStyle.compactGap),
            ],
            _FileButtonCard(onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _PurchaseDetailControllers {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  num get quantity =>
      num.tryParse(quantityController.text.replaceAll(',', '').trim()) ?? 0;
  num get price =>
      num.tryParse(priceController.text.replaceAll(',', '').trim()) ?? 0;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class _PurchaseDetailCard extends StatelessWidget {
  const _PurchaseDetailCard({required this.index, required this.controllers});

  final int index;
  final _PurchaseDetailControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: const Color(0xFFF0F2F6)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mục $index',
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: RequestFormStyle.compactGap),
          _InputCard(
            icon: Icons.chat_bubble_outline_rounded,
            hintText: 'Tên sản phẩm',
            controller: controllers.nameController,
            requiredMark: true,
          ),
          const SizedBox(height: RequestFormStyle.compactGap),
          Row(
            children: [
              Expanded(
                child: _InputCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  hintText: 'Số lượng',
                  controller: controllers.quantityController,
                  requiredMark: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InputCard(
                  icon: Icons.receipt_long_outlined,
                  hintText: 'Giá thành',
                  controller: controllers.priceController,
                  requiredMark: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const CurrencyInputFormatter(),
                  ],
                ),
              ),
            ],
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
                              fontSize: 16),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: RequestFormStyle.iconSize),
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
    this.keyboardType,
    this.inputFormatters,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final bool requiredMark;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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

class _FileButtonCard extends StatelessWidget {
  const _FileButtonCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RequestFormStyle.fieldPadding,
      decoration: BoxDecoration(
        color: RequestFormStyle.fieldBackground,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open_rounded,
              size: RequestFormStyle.iconSize, color: AppColors.muted),
          const SizedBox(width: RequestFormStyle.iconTextGap),
          const Expanded(
            child: Text('Tài liệu',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16C879),
              side: const BorderSide(color: Color(0xFF16C879)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
