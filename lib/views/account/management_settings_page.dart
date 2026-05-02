import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/primary_section_app_bar.dart';

class ManagementSettingsPage extends StatelessWidget {
  const ManagementSettingsPage({super.key});

  static const List<_ManagementSettingItem> _items = <_ManagementSettingItem>[
    _ManagementSettingItem(
      title: 'Công ty',
      icon: Icons.apartment_rounded,
      color: AppColors.mint,
    ),
    _ManagementSettingItem(
      title: 'Nhân viên',
      icon: Icons.groups_rounded,
      color: AppColors.mint,
      routeName: AppRoutes.employeeSettings,
    ),
    _ManagementSettingItem(
      title: 'Ca làm',
      icon: Icons.event_available_rounded,
      color: Color(0xFF5B94F0),
      routeName: AppRoutes.shiftSettings,
    ),
    _ManagementSettingItem(
      title: 'Xếp ca',
      icon: Icons.fact_check_outlined,
      color: Color(0xFF5B94F0),
      routeName: AppRoutes.shiftSettings,
    ),
    _ManagementSettingItem(
      title: 'Điểm danh',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF5B94F0),
    ),
    _ManagementSettingItem(
      title: 'Chỉnh sửa giờ công',
      icon: Icons.history_toggle_off_rounded,
      color: Color(0xFF5B94F0),
    ),
    _ManagementSettingItem(
      title: 'Web admin',
      icon: Icons.monitor_rounded,
      color: Color(0xFFE95B0C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimarySectionAppBar(
        title: 'Thiết lập quản lý',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _ManagementSettingsTile(item: item);
          },
        ),
      ),
    );
  }
}

class _ManagementSettingsTile extends StatelessWidget {
  const _ManagementSettingsTile({
    required this.item,
  });

  final _ManagementSettingItem item;

  @override
  Widget build(BuildContext context) {
    final resolvedRouteName = item.routeName ??
        (item.title == 'Công ty' ? AppRoutes.companySettings : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedRouteName == null
            ? null
            : () => Navigator.of(context).pushNamed(resolvedRouteName),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: SizedBox(
              width: 36,
              child: Center(
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 32,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
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
}

class _ManagementSettingItem {
  const _ManagementSettingItem({
    required this.title,
    required this.icon,
    required this.color,
    this.routeName,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? routeName;
}
