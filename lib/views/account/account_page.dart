import 'package:flutter/material.dart';

import '../../controllers/account_controller.dart';
import '../../core/routes/app_navigator.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/work_bottom_bar.dart';
import '../../models/employee_profile.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountController _controller;

  static const List<_AccountMenuItemData> _managementItems =
      <_AccountMenuItemData>[
    _AccountMenuItemData(
      title: 'Thiết lập quản lý',
      icon: Icons.settings_outlined,
      color: Color(0xFF79D895),
    ),
    _AccountMenuItemData(
      title: 'Báo cáo',
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF79D895),
    ),
    _AccountMenuItemData(
      title: 'Quản lý phép',
      icon: Icons.calendar_month_outlined,
      color: Color(0xFF79D895),
    ),
    _AccountMenuItemData(
      title: 'Phiếu lương',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF79D895),
    ),
  ];

  static const List<_AccountMenuItemData> _settingItems =
      <_AccountMenuItemData>[
    _AccountMenuItemData(
      title: 'Ngôn ngữ',
      icon: Icons.language_rounded,
      color: Color(0xFF2E4F7E),
    ),
    _AccountMenuItemData(
      title: 'Cài đặt cảnh báo',
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF2E4F7E),
    ),
    _AccountMenuItemData(
      title: 'Đổi doanh nghiệp',
      icon: Icons.business_center_outlined,
      color: Color(0xFF2E4F7E),
    ),
  ];

  static const List<_AccountMenuItemData> _systemItems = <_AccountMenuItemData>[
    _AccountMenuItemData(
      title: 'Thông tin ứng dụng',
      icon: Icons.description_outlined,
      color: Color(0xFFA52A2A),
    ),
    _AccountMenuItemData(
      title: 'Làm mới ứng dụng',
      icon: Icons.sync_rounded,
      color: Color(0xFFA52A2A),
    ),
    _AccountMenuItemData(
      title: 'Trung tâm bảo mật',
      icon: Icons.shield_outlined,
      color: Color(0xFFA52A2A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AccountController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSystemItemTap(_AccountMenuItemData item) async {
    if (item.title == 'Thông tin ứng dụng') {
      Navigator.of(context).pushNamed(AppRoutes.appInfo);
      return;
    }

    if (item.title == 'Trung tâm bảo mật') {
      Navigator.of(context).pushNamed(AppRoutes.securityCenter);
      return;
    }

    if (item.title != 'Làm mới ứng dụng' || _controller.isSubmitting) {
      return;
    }

    if (AppNavigator.context == null) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Đang làm mới ứng dụng...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );

    await _controller.refreshApp();
    if (!mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (_controller.lastActionSucceeded) {
      AppNotice.showSuccess(context, 'Ứng dụng đã được làm mới.');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else {
      AppNotice.showError(context, _controller.statusMessage);
    }
  }

  void _handleSettingItemTap(_AccountMenuItemData item) {
    switch (item.title) {
      case 'Ngôn ngữ':
        Navigator.of(context).pushNamed(AppRoutes.languageSettings);
        break;
      case 'Cài đặt cảnh báo':
        Navigator.of(context).pushNamed(AppRoutes.notificationSettings);
        break;
      case 'Đổi doanh nghiệp':
        Navigator.of(context).pushNamed(AppRoutes.companySwitch);
        break;
    }
  }

  bool _canViewManagementItems(EmployeeProfile? profile) {
    final role = profile?.role.trim().toLowerCase() ?? '';
    if (role.isEmpty) {
      return false;
    }

    return const <String>{
      'admin',
      'administrator',
      'company',
      'owner',
      'manager',
      'super_admin',
      'superadmin',
      'hr',
      'quan ly',
      'quan_ly',
      'quản lý',
      'quản_lý',
    }.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final profile = _controller.profile;
            final canViewManagementItems = _canViewManagementItems(profile);

            return RefreshIndicator(
              onRefresh: () => _controller.loadProfile(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _AccountTopBar(
                    isSubmitting: _controller.isSubmitting,
                    onBackToWork: () {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.home);
                    },
                  ),
                  const SizedBox(height: 14),
                  _AccountIdentity(profile: profile),
                  const SizedBox(height: 28),
                  if (canViewManagementItems) ...[
                    _AccountMenuSection(items: _managementItems),
                    const SizedBox(height: 18),
                  ],
                  _AccountMenuSection(
                    items: _settingItems,
                    onItemTap: (item) async {
                      _handleSettingItemTap(item);
                    },
                  ),
                  const SizedBox(height: 18),
                  _AccountMenuSection(
                    items: _systemItems,
                    onItemTap: _handleSystemItemTap,
                  ),
                  const SizedBox(height: 36),
                  OutlinedButton(
                    onPressed: _controller.isSubmitting
                        ? null
                        : () async {
                            await _controller.logout();
                            if (!context.mounted) {
                              return;
                            }
                            if (_controller.lastActionSucceeded) {
                              AppNotice.showInfo(context, 'Bạn đã đăng xuất.');
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.login);
                            } else {
                              AppNotice.showError(
                                context,
                                _controller.statusMessage,
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB22B2B),
                      side: const BorderSide(
                        color: Color(0xFFB22B2B),
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(62),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: _controller.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Text('Đăng Xuất'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: WorkBottomBar(
        currentItem: WorkBottomBarItem.account,
        onItemSelected: (item) {
          switch (item) {
            case WorkBottomBarItem.work:
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              break;
            case WorkBottomBarItem.account:
              break;
            case WorkBottomBarItem.task:
            case WorkBottomBarItem.support:
              break;
          }
        },
      ),
    );
  }
}

class _AccountTopBar extends StatelessWidget {
  const _AccountTopBar({
    required this.isSubmitting,
    required this.onBackToWork,
  });

  final bool isSubmitting;
  final VoidCallback onBackToWork;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBackToWork,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFF2B2B30),
              size: 24,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: isSubmitting ? null : () {},
          child: const Text(
            'Sửa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({
    required this.profile,
  });

  final EmployeeProfile? profile;

  @override
  Widget build(BuildContext context) {
    final displayName =
        profile?.name.trim().isNotEmpty == true ? profile!.name : 'Nhân viên';
    final subtitle = _buildSubtitle(profile);
    final initial = displayName.characters.first.toUpperCase();

    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F3),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7ED286),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFFA0A0A5),
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(EmployeeProfile? profile) {
    final role = profile?.jobTitle.trim().isNotEmpty == true
        ? profile!.jobTitle
        : profile?.department.trim().isNotEmpty == true
            ? profile!.department
            : profile?.role.trim().isNotEmpty == true
                ? profile!.role
                : 'Nhân viên';
    final maskedPhone = _maskPhone(profile?.phone ?? '');
    return maskedPhone.isEmpty ? role : '$role • $maskedPhone';
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return phone;
    }

    return '${digits.substring(0, 4)}****${digits.substring(digits.length - 2)}';
  }
}

class _AccountMenuSection extends StatelessWidget {
  const _AccountMenuSection({
    required this.items,
    this.onItemTap,
  });

  final List<_AccountMenuItemData> items;
  final Future<void> Function(_AccountMenuItemData item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _AccountMenuTile(
              item: items[index],
              onTapOverride: onItemTap == null
                  ? null
                  : () {
                      onItemTap!(items[index]);
                    },
            ),
            if (index != items.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F0EE)),
          ],
        ],
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.item,
    this.onTapOverride,
  });

  final _AccountMenuItemData item;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final resolvedOnTap = onTapOverride ??
        () {
          if (item.title == 'Thiết lập quản lý') {
            Navigator.of(context).pushNamed(AppRoutes.managementSettings);
          }
        };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedOnTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            leading: Icon(item.icon, color: item.color, size: 30),
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

class _AccountMenuItemData {
  const _AccountMenuItemData({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}
