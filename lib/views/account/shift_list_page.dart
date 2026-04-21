import 'package:flutter/material.dart';

import '../../controllers/shift_list_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/shift_item.dart';
import 'shift_form_page.dart';

class ShiftListPage extends StatefulWidget {
  const ShiftListPage({super.key});

  @override
  State<ShiftListPage> createState() => _ShiftListPageState();
}

class _ShiftListPageState extends State<ShiftListPage> {
  late final ShiftListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShiftListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm({ShiftItem? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ShiftFormPage(initialItem: item),
      ),
    );

    if (changed == true) {
      await _controller.loadShifts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: 'Xếp ca',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: SafeArea(
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

            if (_controller.items.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có xếp ca nào.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.muted,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.loadShifts,
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final item = _controller.items[index];
                  return _ShiftTile(
                    item: item,
                    onTap: () => _openForm(item: item),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({
    required this.item,
    required this.onTap,
  });

  final ShiftItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      item.timeRange,
      if ((item.regionName ?? '').trim().isNotEmpty) 'Vùng: ${item.regionName}',
      if ((item.branchName ?? '').trim().isNotEmpty)
        'Chi nhánh: ${item.branchName}',
      if (item.weekdays.isNotEmpty) 'Ngày: ${_weekdayText(item.weekdays)}',
    ];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitleParts.join(' • '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }

  String _weekdayText(List<int> weekdays) {
    const labels = <int, String>{
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    return weekdays
        .map((value) => labels[value] ?? value.toString())
        .join(', ');
  }
}
