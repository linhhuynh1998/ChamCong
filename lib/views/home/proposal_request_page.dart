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

class ProposalRequestPage extends StatefulWidget {
  const ProposalRequestPage({super.key});

  @override
  State<ProposalRequestPage> createState() => _ProposalRequestPageState();
}

class _ProposalRequestPageState extends State<ProposalRequestPage> {
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _accountOwnerController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmployeeDirectoryService _employeeService = EmployeeDirectoryService();
  final RequestsService _requestsService = RequestsService();

  Future<void>? _employeeLoadTask;

  String _selectedEmployeeId = '';
  String _selectedEmployeeName = 'Chọn nhân viên';
  String _selectedDate = '06/05/2026';
  String _selectedRequestTypeId = '';
  String _selectedRequestType = 'Chọn loại';
  String _selectedPaymentTypeId = '';
  String _selectedPaymentType = 'Chọn loại';

  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;
  List<EmployeeListItem> _employees = [];
  final List<_ProposalDetailControllers> _details = [
    _ProposalDetailControllers(),
  ];

  final List<LocationOption> _requestTypes = const [
    LocationOption(id: 'thanh_toan', name: 'Thanh toán'),
    LocationOption(id: 'mua_hang', name: 'Mua hàng'),
    LocationOption(id: 'tam_ung', name: 'Tạm ứng'),
    LocationOption(id: 'khac', name: 'Khác'),
  ];
  final List<LocationOption> _paymentTypes = const [
    LocationOption(id: 'tien_mat', name: 'Tiền mặt'),
    LocationOption(id: 'chuyen_khoan', name: 'Chuyển khoản'),
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
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
    if (_selectedRequestType == 'Chọn loại') {
      AppNotice.showError(context, 'Vui lòng chọn loại phiếu đề nghị');
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
    AppLoading.show(message: 'Đang gửi yêu cầu..');
    try {
      final profile = await _authService.me();
      final message = await _requestsService.createRequest(
        companyId: profile.companyId,
        requestType: 'Phiếu đề nghị',
        employeeId: _selectedEmployeeId,
        fields: <String, dynamic>{
          'Nhân viên': _selectedEmployeeName,
          'Ngày': _apiDateFromDisplayDate(_selectedDate),
          'Loại đề nghị': _selectedRequestType,
          if (_selectedPaymentType != 'Chọn loại')
            'Loại thanh toán': _selectedPaymentType,
          if (_isTransferPaymentSelected) ...<String, dynamic>{
            'Chủ tài khoản': _accountOwnerController.text.trim(),
            'Số tài khoản': _accountNumberController.text.trim(),
            'Tên ngân hàng': _bankNameController.text.trim(),
          },
          'Mục đích thanh toán': _purposeController.text.trim(),
          'Tổng số tiền': _totalAmount,
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
      final quantity = detail.quantity;
      final price = detail.price;
      final note = detail.noteController.text.trim();

      if (content.isEmpty && quantity == 0 && price == 0 && note.isEmpty) {
        continue;
      }
      if (content.isEmpty || quantity <= 0 || price <= 0) {
        continue;
      }
      payload.add(<String, dynamic>{
        'M\u{1EE5}c': index + 1,
        'N\u{1ED9}i dung': content,
        'S\u{1ED1} l\u{01B0}\u{1EE3}ng': quantity,
        'Gi\u{00E1} th\u{00E0}nh': price,
        'Th\u{00E0}nh ti\u{1EC1}n': detail.amount,
        if (note.isNotEmpty) 'Ghi ch\u{00FA}': note,
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
      AppNotice.showError(context, 'Ch\u{01B0}a c\u{00F3} d\u{1EEF} li\u{1EC7}u nh\u{00E2}n vi\u{00EA}n \u{0111}\u{1EC3} ch\u{1ECD}n.');
      return;
    }

    final selected = await _showPicker<EmployeeListItem>(
      title: 'Ch\u{1ECD}n nh\u{00E2}n vi\u{00EA}n',
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

  Future<void> _pickRequestType() async {
    final selected = await _showPicker<LocationOption>(
      title: 'Ch\u{1ECD}n lo\u{1EA1}i',
      items: _requestTypes,
      labelOf: (item) => item.name,
      subtitleOf: (_) => '',
      isSelected: (item) => item.id == _selectedRequestTypeId,
    );
    if (selected != null) {
      setState(() {
        _selectedRequestTypeId = selected.id;
        _selectedRequestType = selected.name;
      });
    }
  }

  Future<void> _pickPaymentType() async {
    final selected = await _showPicker<LocationOption>(
      title: 'Ch\u{1ECD}n lo\u{1EA1}i thanh to\u{00E1}n',
      items: _paymentTypes,
      labelOf: (item) => item.name,
      subtitleOf: (_) => '',
      isSelected: (item) => item.id == _selectedPaymentTypeId,
    );
    if (selected != null) {
      setState(() {
        _selectedPaymentTypeId = selected.id;
        _selectedPaymentType = selected.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 5, 6),
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

  void _addDetail() {
    setState(() => _details.add(_ProposalDetailControllers()));
  }

  void _removeDetail(int index) {
    if (_details.length <= 1) return;
    setState(() {
      final removed = _details.removeAt(index);
      removed.dispose();
    });
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

  int get _totalAmount => _details.fold<int>(
        0,
        (total, detail) => total + detail.amount,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Phiếu đề nghị',
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
            _SelectorCard(
              icon: Icons.edit_note_rounded,
              value: _selectedRequestType,
              onTap: _pickRequestType,
              requiredMark: true,
              isPlaceholder: _selectedRequestType == 'Chọn loại',
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _SelectorCard(
              icon: Icons.account_balance_wallet_outlined,
              value: _selectedPaymentType,
              onTap: _pickPaymentType,
              isPlaceholder: _selectedPaymentType == 'Chọn loại',
            ),
            if (_isTransferPaymentSelected) ...[
              const SizedBox(height: RequestFormStyle.itemGap),
              _InputCard(
                icon: Icons.person_outline_rounded,
                hintText: 'Chủ tài khoản',
                controller: _accountOwnerController,
                requiredMark: true,
              ),
              const SizedBox(height: RequestFormStyle.itemGap),
              _InputCard(
                icon: Icons.credit_card_outlined,
                hintText: 'Số tài khoản',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                requiredMark: true,
              ),
              const SizedBox(height: RequestFormStyle.itemGap),
              _InputCard(
                icon: Icons.account_balance_outlined,
                hintText: 'Tên ngân hàng',
                controller: _bankNameController,
                requiredMark: true,
              ),
            ],
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
            _ReadOnlyAmountCard(
              icon: Icons.request_quote_outlined,
              value: _totalAmount == 0
                  ? 'Tổng số tiền'
                  : _ThousandsSeparatorInputFormatter.formatNumber(
                      _totalAmount,
                    ),
              isPlaceholder: _totalAmount == 0,
            ),
            const SizedBox(height: RequestFormStyle.itemGap),
            _AttachmentCard(),
          ],
        ),
      ),
    );
  }
}

class _ProposalDetailControllers {
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
            'Chi ti\u{1EBF}t',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 38),
          color: const Color(0xFF16C879),
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
  final _ProposalDetailControllers detail;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF223B63).withOpacity(0.08),
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
                    color: AppColors.muted,
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
          const SizedBox(height: RequestFormStyle.compactGap),
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
                  icon: Icons.request_quote_outlined,
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
          _ReadOnlyAmountCard(
            icon: Icons.request_quote_outlined,
            value: detail.amount == 0
                ? 'Thành tiền'
                : _ThousandsSeparatorInputFormatter.formatNumber(
                    detail.amount,
                  ),
            isPlaceholder: detail.amount == 0,
          ),
          const SizedBox(height: 18),
          _InputCard(
            icon: Icons.chat_bubble_outline_rounded,
            hintText: 'Ghi chú',
            controller: detail.noteController,
            maxLines: 4,
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
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 110 : 62),
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
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
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

class _ReadOnlyAmountCard extends StatelessWidget {
  const _ReadOnlyAmountCard({
    required this.icon,
    required this.value,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String value;
  final bool isPlaceholder;

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
                color: isPlaceholder
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
          const Icon(
            Icons.create_new_folder_outlined,
            size: 28,
            color: AppColors.muted,
          ),
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
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => AppNotice.showInfo(
                context,
                'Chức năng thêm tài liệu sẽ được cập nhật thêm.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16C879),
                side: const BorderSide(color: Color(0xFF16C879)),
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