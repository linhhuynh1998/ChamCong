import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class ManagementSettingsPage extends StatelessWidget {
  const ManagementSettingsPage({super.key});

  static const List<_ManagementSettingItem> _items =
      <_ManagementSettingItem>[
        _ManagementSettingItem(
          title: 'Công ty',
          icon: Icons.apartment_rounded,
          color: Color(0xFF79D895),
        ),
        _ManagementSettingItem(
          title: 'Nhân viên',
          icon: Icons.groups_rounded,
          color: Color(0xFF79D895),
        ),
        _ManagementSettingItem(
          title: 'Ca làm',
          icon: Icons.event_available_rounded,
          color: Color(0xFF5B94F0),
        ),
        _ManagementSettingItem(
          title: 'Xếp ca',
          icon: Icons.fact_check_outlined,
          color: Color(0xFF5B94F0),
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
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: _items.length + 1,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0F0EE),
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF202124),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Thiết lập quản lý',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }

            final item = _items[index - 1];
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

    final resolvedOnTap = item.onTap ?? () {
      if (item.title == 'Công ty') {
        Navigator.of(context).pushNamed(AppRoutes.managementSettings);
      }
    };

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
                color: Colors.black,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF202124),
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
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}
