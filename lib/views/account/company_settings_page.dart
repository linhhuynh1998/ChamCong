import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import 'company_directory_form_page.dart';

class CompanySettingsPage extends StatelessWidget {
  const CompanySettingsPage({super.key});

  static const List<_CompanySettingItem> _items = <_CompanySettingItem>[
    _CompanySettingItem(
      title: 'Vùng',
      icon: Icons.public,
      color: AppColors.mint,
    ),
    _CompanySettingItem(
      title: 'Chi nhánh',
      icon: Icons.account_tree,
      color: AppColors.mint,
    ),
    _CompanySettingItem(
      title: 'Chức vụ',
      icon: Icons.person,
      color: AppColors.mint,
    ),
    _CompanySettingItem(
      title: 'Phòng ban',
      icon: Icons.account_tree,
      color: AppColors.mint,
    ),
    _CompanySettingItem(
      title: 'Vị trí chấm công',
      icon: Icons.location_on,
      color: AppColors.mint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimarySectionAppBar(
        title: 'Công ty',
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
            return _CompanySettingsTile(item: item);
          },
        ),
      ),
    );
  }
}

class _CompanySettingsTile extends StatelessWidget {
  const _CompanySettingsTile({
    required this.item,
  });

  final _CompanySettingItem item;

  @override
  Widget build(BuildContext context) {
    void resolvedOnTap() {
      switch (item.title) {
        case 'Vùng':
          Navigator.of(context).pushNamed(AppRoutes.regionSettings);
          break;
        case 'Chi nhánh':
          Navigator.of(context).pushNamed(AppRoutes.branchSettings);
          break;
        case 'Chức vụ':
          Navigator.of(context).pushNamed(AppRoutes.jobTitleSettings);
          break;
        case 'Phòng ban':
          Navigator.of(context).pushNamed(AppRoutes.departmentSettings);
          break;
        case 'Vị trí chấm công':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CompanyDirectoryFormPage(
                title: 'Vị trí chấm công',
                endpoint: '/company/location',
              ),
            ),
          );
          break;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedOnTap,
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

class _CompanySettingItem {
  const _CompanySettingItem({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}
