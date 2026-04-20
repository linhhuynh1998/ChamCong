import 'package:flutter/material.dart';

import '../../controllers/employee_list_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/employee_list_item.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  late final EmployeeListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAddEmployee() async {
    AppNotice.showInfo(
        context, 'Màn tạo nhân viên sẽ được nối ở bước tiếp theo.');
  }

  Future<void> _handleFilter() async {
    AppNotice.showInfo(context, 'Bộ lọc nhân viên sẽ được cập nhật thêm sau.');
  }

  Future<void> _callEmployee(String phone) async {
    final cleanedPhone = phone.trim();
    if (cleanedPhone.isEmpty) {
      AppNotice.showInfo(context, 'Nhân viên này chưa có số điện thoại.');
      return;
    }

    AppNotice.showInfo(context, 'Số điện thoại: $cleanedPhone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Danh sách nhân viên',
        actions: [
          IconButton(
            onPressed: _handleAddEmployee,
            icon: const Icon(
              Icons.add_rounded,
              size: 30,
              color: AppColors.sectionHeader,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!_controller.lastActionSucceeded) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _controller.statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EmployeeSearchField(
                          controller: _controller.searchController,
                        ),
                      ),
                      const SizedBox(width: 14),
                      _FilterButton(onTap: _handleFilter),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _controller.visibleEmployees.isEmpty
                      ? _EmployeeEmptyState(
                          hasQuery: _controller.searchController.text
                              .trim()
                              .isNotEmpty,
                        )
                      : RefreshIndicator(
                          onRefresh: _controller.loadEmployees,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _controller.visibleEmployees.length,
                            separatorBuilder: (_, __) => const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF1F2F6),
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final employee =
                                  _controller.visibleEmployees[index];
                              return _EmployeeTile(
                                item: employee,
                                onCall: () => _callEmployee(employee.phone),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmployeeSearchField extends StatelessWidget {
  const _EmployeeSearchField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 34,
          color: Color(0xFFC1C9E5),
        ),
        filled: true,
        fillColor: AppColors.fieldSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFDCE4FF),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(
          width: 76,
          height: 76,
          child: Icon(
            Icons.tune_rounded,
            size: 34,
            color: AppColors.sectionHeader,
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.item,
    required this.onCall,
  });

  final EmployeeListItem item;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (item.jobTitle.trim().isNotEmpty) item.jobTitle.trim(),
      if (item.department.trim().isNotEmpty) item.department.trim(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFB8C7F0),
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: Text(
              item.initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitleParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onCall,
            icon: const Icon(
              Icons.call_rounded,
              size: 34,
              color: Color(0xFF19D96A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeEmptyState extends StatelessWidget {
  const _EmployeeEmptyState({
    required this.hasQuery,
  });

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                hasQuery
                    ? 'Không tìm thấy nhân viên phù hợp.'
                    : 'Chưa có nhân viên nào trong danh sách.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
