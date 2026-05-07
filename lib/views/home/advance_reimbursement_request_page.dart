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
import '../../services/request_type_service.dart';
import '../../services/requests_service.dart';

class AdvanceReimbursementRequestPage extends StatefulWidget {
  const AdvanceReimbursementRequestPage({super.key});

  @override
  State<AdvanceReimbursementRequestPage> createState() =>
      _AdvanceReimbursementRequestPageState();
}

class _AdvanceReimbursementRequestPageState
    extends State<AdvanceReimbursementRequestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _accountOwnerController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestTypeService _requestTypeService = RequestTypeService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;
  Future<void>? _advanceTypeLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  String _selectedDate = '05/05/2026';
  String _selectedGroup = 'Nhóm';
  String _selectedAdvanceTypeId = '';
  String _selectedAdvanceType = 'Chọn loại';
  String _selectedPaymentType = 'Chọn loại';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingAdvanceTypes = false;
  List<EmployeeListItem> _employees = [];
  List<LocationOption> _advanceTypes = [];
  final List<_AdvanceDetailControllers> _details = [
    _AdvanceDetailControllers(),
  ];

  static const List<LocationOption> _paymentTypes = <LocationOption>[
    LocationOption(id: 'cash', name: 'Tiền mặt'),
    LocationOption(id: 'transfer', name: 'Chuyển khoản'),
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadAdvanceTypes();
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

  Future<void> _loadAdvanceTypes() async {
    final currentTask = _advanceTypeLoadTask;
    if (currentTask != null) return currentTask;

    final task = () async {
      setState(() => _isLoadingAdvanceTypes = true);
      try {
        final types = await _requestTypeService.fetchAdvanceTypes();
        if (mounted) setState(() => _advanceTypes = types);
      } catch (e) {
        if (mounted) {
          AppNotice.showError(context, 'Lỗi tải danh sách loại tạm ứng: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoadingAdvanceTypes = false);
      }
    }();

    _advanceTypeLoadTask = task;
    try {
      await task;
    } finally {
      if (_advanceTypeLoadTask == task) _advanceTypeLoadTask = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _accountOwnerController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    for (final detail in _details) {
      detail.dispose();
    }
    super.dispose();
  }

  bool get _isTransferPaymentSelected => _selectedPaymentType == 'Chuyển khoản';

  Future<void> _onSubmit() async {
    if (_selectedEmployeeId.isEmpty) {
      AppNotice.showError(context, 'Vui lòng chọn nhân viên');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập tiêu đề');
      return;
    }
    if (_selectedAdvanceType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại tạm ứng');
      return;
    }
    if (_selectedPaymentType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại thanh toán');
      return;
    }
    if (_isTransferPaymentSelected) {
      if (_accountOwnerController.text.trim().isEmpty) {
        AppNotice.showError(context, 'Vui lòng nhập chủ tài khoản');
        return;
      }
      if (_accountNumberController.text.trim().isEmpty) {
        AppNotice.showError(context, 'Vui lòng nhập số tài khoản');
        return;
      }
      if (_bankNameController.text.trim().isEmpty) {
        AppNotice.showError(context, 'Vui lòng nhập tên ngân hàng');
        return;
      }
    }
    if (_purposeController.text.trim().isEmpty) {
      AppNotice.showError(context, 'Vui lòng nhập mục đích thanh toán');
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
        requestType: 'Tạm ứng - Hoàn ứng',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Tiêu đề': _titleController.text.trim(),
          'Ngày': _apiDateFromDisplayDate(_selectedDate),
          if (_selectedGroup != 'Nhóm') 'Nhóm': _selectedGroup,
          'Loại': _selectedAdvanceType,
          'Loại thanh toán': _selectedPaymentType,
          if (_isTransferPaymentSelected) ...<String, dynamic>{
            'Chủ tài khoản': _accountOwnerController.text.trim(),
            'Số tài khoản': _accountNumberController.text.trim(),
            'Tên ngân hàng': _bankNameController.text.trim(),
          },
          'Mục đích thanh toán': _purposeController.text.trim(),
          'Tổng tiền': _totalAmount,
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
      final price = _numberValue(detail.priceController);
      final amount = detail.amount;
      final note = detail.noteController.text.trim();

      if (content.isEmpty && quantity == 0 && price == 0 && note.isEmpty) {
        continue;
      }
      if (content.isEmpty || quantity <= 0 || price <= 0) {
        continue;
      }

      payload.add(<String, dynamic>{
        'Mục': index + 1,
        'Nội dung': content,
        'Số lượng': quantity,
        'Giá thành': price,
        'Thành tiền': amount,
        if (note.isNotEmpty) 'Ghi chú': note,
      });
    }
    return payload;
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
      isSelected: (item) => item.id == _selectedEmployeeId,
    );
    if (selected != null) {
      setState(() {
        _selectedEmployeeId = selected.id;
        _selectedEmployeeName = selected.name;
      });
    }
  }

  Future<void> _pickAdvanceType() async {
    if (_isLoadingAdvanceTypes || _advanceTypes.isEmpty) {
      await _loadAdvanceTypes();
      if (!mounted) return;
    }
    if (_advanceTypes.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu loại tạm ứng để chọn.');
      return;
    }

    final selected = await _showPicker<LocationOption>(
      title: 'Chọn loại',
      items: _advanceTypes,
      labelOf: (item) => item.name,
      isSelected: (item) =>
          item.id == _selectedAdvanceTypeId ||
          item.name == _selectedAdvanceType,
    );
    if (selected != null) {
      setState(() {
        _selectedAdvanceTypeId = selected.id;
        _selectedAdvanceType = selected.name;
      });
    }
  }

  Future<void> _pickPaymentType() async {
    final selected = await _showPicker<LocationOption>(
      title: 'Chọn loại thanh toán',
      items: _paymentTypes,
      labelOf: (item) => item.name,
      isSelected: (item) => item.name == _selectedPaymentType,
    );
    if (selected != null) {
      setState(() {
        _selectedPaymentType = selected.name;
        if (!_isTransferPaymentSelected) {
          _accountOwnerController.clear();
          _accountNumberController.clear();
          _bankNameController.clear();
        }
      });
    }
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
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textPrimary),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 5),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _selectedDate = _formatDate(picked));
  }

  void _addDetail() {
    setState(() => _details.add(_AdvanceDetailControllers()));
  }

  void _removeDetail(int index) {
    if (_details.length == 1) return;
    final removed = _details.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _apiDateFromDisplayDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return value;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  int _numberValue(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int get _totalAmount => _details.fold<int>(
        0,
        (total, detail) => total + detail.amount,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Tạm ứng - Hoàn ứng',
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
              value: _selectedDate,
              onTap: _pickDate,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.edit_note_rounded,
              value: _selectedAdvanceType,
              onTap: _pickAdvanceType,
              requiredMark: true,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.account_balance_wallet_outlined,
              value: _selectedPaymentType,
              onTap: _pickPaymentType,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _InputCard(
              icon: Icons.edit_note_rounded,
              hintText: 'Mục đích thanh toán',
              controller: _purposeController,
              requiredMark: true,
            ),
            const SizedBox(height: 34),
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
            _ReadOnlyAmountCard(amount: _totalAmount),
            const SizedBox(height: RequestFormStyle.itemGap),
            _AttachmentCard(),
          ],
        ),
      ),
    );
  }
}

class _AdvanceDetailControllers {
  final TextEditingController contentController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  int get quantity => _numberValue(quantityController.text);
  int get price => _numberValue(priceController.text);
  int get amount => quantity * price;

  static int _numberValue(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void dispose() {
    contentController.dispose();
    quantityController.dispose();
    priceController.dispose();
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
  final _AdvanceDetailControllers detail;
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
          Row(
            children: [
              Expanded(
                child: _InputCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  hintText: 'Số lượng',
                  controller: detail.quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_ThousandsSeparatorInputFormatter()],
                  onChanged: (_) => onChanged(),
                  requiredMark: true,
                ),
              ),
              const SizedBox(width: RequestFormStyle.iconTextGap),
              Expanded(
                child: _InputCard(
                  icon: Icons.payments_outlined,
                  hintText: 'Giá thành',
                  controller: detail.priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_ThousandsSeparatorInputFormatter()],
                  onChanged: (_) => onChanged(),
                  requiredMark: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ValueCard(
            icon: Icons.payments_outlined,
            value: detail.amount == 0
                ? 'Giá thành'
                : _ThousandsSeparatorInputFormatter.formatNumber(detail.amount),
          ),
          const SizedBox(height: 18),
          _InputCard(
            icon: Icons.chat_bubble_outline_rounded,
            hintText: 'Ghi chú',
            controller: detail.noteController,
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
    this.requiredMark = false,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
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
              onChanged: onChanged,
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

class _LabeledInputCard extends StatelessWidget {
  const _LabeledInputCard({
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.requiredMark = false,
  });

  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
      padding: RequestFormStyle.fieldPadding,
      decoration: BoxDecoration(
        color: RequestFormStyle.fieldBackground,
        borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
        border: Border.all(color: AppColors.divider),
      ),
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
          hintText: requiredMark ? '* $hintText' : hintText,
          hintStyle: RequestFormStyle.hintTextStyle,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: RequestFormStyle.fieldMinHeight),
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: value == 'Giá thành'
                    ? AppColors.muted
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyAmountCard extends StatelessWidget {
  const _ReadOnlyAmountCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return _ValueCard(
      icon: Icons.payments_outlined,
      value: amount == 0
          ? 'Giá thành'
          : _ThousandsSeparatorInputFormatter.formatNumber(amount),
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
                borderRadius: BorderRadius.circular(RequestFormStyle.fieldRadius),
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