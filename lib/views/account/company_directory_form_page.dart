import 'package:flutter/material.dart';

import '../../controllers/company_directory_form_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../models/company_directory_item.dart';

class CompanyDirectoryFormPage extends StatefulWidget {
  const CompanyDirectoryFormPage({
    super.key,
    required this.title,
    required this.endpoint,
    this.requiresRegionId = false,
    this.initialItem,
  });

  final String title;
  final String endpoint;
  final bool requiresRegionId;
  final CompanyDirectoryItem? initialItem;

  @override
  State<CompanyDirectoryFormPage> createState() =>
      _CompanyDirectoryFormPageState();
}

class _CompanyDirectoryFormPageState extends State<CompanyDirectoryFormPage> {
  late final CompanyDirectoryFormController _controller;

  bool get _isAttendanceLocationForm =>
      widget.endpoint == '/company/attendance-location';

  String get _pageTitle {
    if (_isAttendanceLocationForm) {
      return _controller.isEditing ? 'Chi tiết vị trí' : 'Tạo vị trí';
    }

    return _controller.isEditing
        ? 'Chi tiết ${widget.title}'
        : 'Tạo ${widget.title}';
  }

  String get _submitLabel {
    if (_controller.isEditing) {
      return 'Lưu';
    }

    return _isAttendanceLocationForm ? 'Thêm' : 'Tạo';
  }

  @override
  void initState() {
    super.initState();
    _controller = CompanyDirectoryFormController(
      endpoint: widget.endpoint,
      requiresRegionId: widget.requiresRegionId,
      initialItem: widget.initialItem,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showRegionPicker() async {
    if (_controller.isLoadingRegions) {
      return;
    }

    if (_controller.regions.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu vùng để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn vùng',
      items: _controller.regions,
      selectedId: _controller.selectedRegionId,
    );

    if (selected != null) {
      _controller.selectRegion(selected);
    }
  }

  Future<void> _showBranchPicker() async {
    if (_controller.isLoadingBranches) {
      return;
    }

    if (_controller.branches.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu chi nhánh để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn chi nhánh',
      items: _controller.branches,
      selectedId: _controller.selectedBranchId,
    );

    if (selected != null) {
      _controller.selectBranch(selected);
    }
  }

  Future<void> _showDepartmentPicker() async {
    if (_controller.isLoadingDepartments) {
      return;
    }

    if (_controller.departments.isEmpty) {
      AppNotice.showError(context, 'Chưa có dữ liệu phòng ban để chọn.');
      return;
    }

    final selected = await _showItemPicker(
      title: 'Chọn phòng ban',
      items: _controller.departments,
      selectedId: _controller.selectedDepartmentId,
    );

    if (selected != null) {
      _controller.selectDepartment(selected);
    }
  }

  Future<CompanyDirectoryItem?> _showItemPicker({
    required String title,
    required List<CompanyDirectoryItem> items,
    required String? selectedId,
  }) async {
    return showModalBottomSheet<CompanyDirectoryItem>(
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
                      final isSelected = selectedId == item.id;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: item.description.trim().isEmpty
                            ? null
                            : Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: _isAttendanceLocationForm ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
            size: 28,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
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
                        color: Colors.black,
                      ),
                    )
                  : Text(_submitLabel),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_isAttendanceLocationForm) {
              return _AttendanceLocationForm(
                controller: _controller,
                onSelectBranch: _showBranchPicker,
                onSelectDepartment: _showDepartmentPicker,
              );
            }

            return _DefaultDirectoryForm(
              controller: _controller,
              title: widget.title,
              requiresRegionId: widget.requiresRegionId,
              onSelectRegion: _showRegionPicker,
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceLocationForm extends StatelessWidget {
  const _AttendanceLocationForm({
    required this.controller,
    required this.onSelectBranch,
    required this.onSelectDepartment,
  });

  final CompanyDirectoryFormController controller;
  final VoidCallback onSelectBranch;
  final VoidCallback onSelectDepartment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      children: [
        const _FieldLabel(
          title: 'Vị trí',
          isRequired: true,
        ),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.nameController,
          minLines: 1,
          maxLines: 1,
          hintText: 'Nhập chữ',
        ),
        const SizedBox(height: 34),
        const _FieldLabel(
          title: 'Địa chỉ',
          isRequired: true,
        ),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.descriptionController,
          minLines: 1,
          maxLines: 1,
          hintText: 'Nhập chữ',
        ),
        const SizedBox(height: 34),
        const _FieldLabel(
          title: 'Chi nhánh',
          isRequired: true,
        ),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.selectedBranchName.isEmpty
              ? 'Chọn chi nhánh'
              : controller.selectedBranchName,
          isLoading: controller.isLoadingBranches,
          onTap: onSelectBranch,
        ),
        const SizedBox(height: 34),
        const _FieldLabel(title: 'Chi nhánh phụ'),
        const SizedBox(height: 18),
        const _SelectorField(label: 'Chọn chi nhánh phụ'),
        const SizedBox(height: 34),
        const _FieldLabel(title: 'Phòng ban'),
        const SizedBox(height: 18),
        _SelectorField(
          label: controller.selectedDepartmentName.isEmpty
              ? 'Chọn phòng ban'
              : controller.selectedDepartmentName,
          isLoading: controller.isLoadingDepartments,
          onTap: onSelectDepartment,
        ),
        const SizedBox(height: 34),
        const _FieldLabel(title: 'Nhân viên'),
        const SizedBox(height: 18),
        const _SelectorField(label: 'Chọn nhân viên'),
        const SizedBox(height: 34),
        const _FieldLabel(title: 'Bán kính (m)'),
        const SizedBox(height: 18),
        _AppTextField(
          controller: controller.radiusController,
          minLines: 1,
          maxLines: 1,
          hintText: '150',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        const _MapPreviewCard(),
      ],
    );
  }
}

class _DefaultDirectoryForm extends StatelessWidget {
  const _DefaultDirectoryForm({
    required this.controller,
    required this.title,
    required this.requiresRegionId,
    required this.onSelectRegion,
  });

  final CompanyDirectoryFormController controller;
  final String title;
  final bool requiresRegionId;
  final VoidCallback onSelectRegion;

  bool get _isRegionForm => title == 'vùng';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _LegacyFieldSection(
          label: _isRegionForm ? 'Tên vùng' : 'Tên $title',
          isRequired: true,
          child: _LegacyTextField(
            controller: controller.nameController,
            hintText: 'Nhập tên $title',
          ),
        ),
        const SizedBox(height: 16),
        _LegacyFieldSection(
          label: _isRegionForm ? 'Mô tả' : 'Địa chỉ',
          child: _LegacyTextField(
            controller: controller.descriptionController,
            hintText: _isRegionForm ? 'Nhập mô tả' : 'Nhập địa chỉ',
            minLines: _isRegionForm ? 6 : 1,
            maxLines: _isRegionForm ? 6 : 1,
          ),
        ),
        if (requiresRegionId) ...[
          const SizedBox(height: 16),
          _LegacyFieldSection(
            label: 'Vùng',
            isRequired: true,
            child: _LegacySelectorField(
              label: controller.selectedRegionName.isEmpty
                  ? 'Chọn vùng'
                  : controller.selectedRegionName,
              isLoading: controller.isLoadingRegions,
              onTap: onSelectRegion,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegacyFieldSection extends StatelessWidget {
  const _LegacyFieldSection({
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

class _LegacyTextField extends StatelessWidget {
  const _LegacyTextField({
    required this.controller,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
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
          borderSide: const BorderSide(
            color: AppColors.divider,
          ),
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

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.minLines,
    required this.maxLines,
    this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 17,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 17,
          color: Color(0xFFD3D3D3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFDCDCDC),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _LegacySelectorField extends StatelessWidget {
  const _LegacySelectorField({
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final bool isLoading;
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
                  isLoading ? 'Đang tải danh sách vùng...' : label,
                  style: TextStyle(
                    fontSize: 16,
                    color: label == 'Chọn vùng' || isLoading
                        ? AppColors.muted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
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

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDCDCDC),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isLoading ? 'Đang tải dữ liệu...' : label,
                  style: TextStyle(
                    fontSize: 17,
                    color: isLoading || label.startsWith('Chọn')
                        ? const Color(0xFFD3D3D3)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA9A9A9),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 255,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF3EEDC)),
            CustomPaint(
              painter: _MapPainter(),
            ),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9FFF5A).withValues(alpha: 0.32),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 44,
                color: Color(0xFFC61C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD6D6D6)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lanePaint = Paint()
      ..color = const Color(0xFFC9C9C9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = const Color(0xFFDDF2C5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.13, size.height * 0.12, 120, 90),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.56, size.height * 0.41, 96, 72),
      blockPaint,
    );

    canvas.drawLine(
      Offset(-20, size.height * 0.16),
      Offset(size.width * 0.5, size.height * 0.73),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, -20),
      Offset(size.width * 0.25, size.height + 20),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );

    for (double x = 16; x < size.width; x += 72) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 16, size.height),
        lanePaint,
      );
    }

    for (double y = 24; y < size.height; y += 60) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 12),
        lanePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
