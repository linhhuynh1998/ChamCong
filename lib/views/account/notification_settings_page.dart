import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _attendanceReminder = true;
  bool _scheduleUpdate = true;
  bool _salaryNotice = false;
  bool _generalNews = true;

  void _save() {
    AppNotice.showSuccess(context, 'Đã cập nhật cài đặt thông báo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: PrimarySectionAppBar(
        title: 'Thông báo',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _save,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            const _SettingsHeroCard(
              icon: Icons.notifications_active_outlined,
              title: 'Cài đặt thông báo',
              description:
                  'Chọn những loại thông báo quan trọng bạn muốn nhận trên thiết bị.',
              accent: Color(0xFF35598D),
            ),
            const SizedBox(height: 16),
            _SwitchCard(
              title: 'Nhắc chấm công',
              subtitle: 'Nhắc bạn check-in hoặc check-out đúng khung giờ làm.',
              value: _attendanceReminder,
              onChanged: (value) {
                setState(() {
                  _attendanceReminder = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Cập nhật xếp ca',
              subtitle:
                  'Thông báo khi lịch làm việc hoặc ca trực được thay đổi.',
              value: _scheduleUpdate,
              onChanged: (value) {
                setState(() {
                  _scheduleUpdate = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Thông báo phiếu lương',
              subtitle: 'Nhận thông báo khi có bảng lương hoặc kỳ lương mới.',
              value: _salaryNotice,
              onChanged: (value) {
                setState(() {
                  _salaryNotice = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Tin tức nội bộ',
              subtitle:
                  'Nhận cập nhật chung từ doanh nghiệp và bộ phận quản lý.',
              value: _generalNews,
              onChanged: (value) {
                setState(() {
                  _generalNews = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Color(0xEEFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Color(0xFF657182),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
