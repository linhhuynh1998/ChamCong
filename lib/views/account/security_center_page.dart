import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';

class SecurityCenterPage extends StatelessWidget {
  const SecurityCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const PrimarySectionAppBar(
        title: 'Trung tâm bảo mật',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: const [
            _SecurityHeroCard(),
            SizedBox(height: 16),
            _SecurityStatusCard(
              title: 'Phiên đăng nhập',
              subtitle: 'Thiết bị hiện tại đang hoạt động bình thường.',
              status: 'An toàn',
              icon: Icons.verified_user_rounded,
              accent: Color(0xFF118A5A),
            ),
            SizedBox(height: 14),
            _SecurityStatusCard(
              title: 'Bảo vệ dữ liệu',
              subtitle:
                  'Thông tin tài khoản và dữ liệu hồ sơ được lưu qua phiên cục bộ để tăng tốc trải nghiệm sử dụng.',
              status: 'Đang bảo vệ',
              icon: Icons.lock_outline_rounded,
              accent: Color(0xFF2B66D9),
            ),
            SizedBox(height: 14),
            _SecurityTipsCard(),
          ],
        ),
      ),
    );
  }
}

class _SecurityHeroCard extends StatelessWidget {
  const _SecurityHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF122033),
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF13233A),
            Color(0xFF1B3D67),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_moon_rounded,
              size: 30,
              color: Color(0xFFA9F1C8),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bảo mật tài khoản',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Theo dõi nhanh trạng thái phiên đăng nhập và một số khuyến nghị để sử dụng ứng dụng an toàn hơn trên thiết bị cá nhân.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xD9FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF5F6674),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTipsCard extends StatelessWidget {
  const _SecurityTipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = <String>[
      'Không chia sẻ tài khoản hoặc mã OTP cho người khác.',
      'Đăng xuất khi dùng chung thiết bị hoặc mạng không tin cậy.',
      'Dùng tính năng làm mới ứng dụng nếu dữ liệu tài khoản hiển thị chưa đồng bộ.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2E2B6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: Color(0xFFB07A14),
              ),
              SizedBox(width: 10),
              Text(
                'Khuyến nghị',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final tip in tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB07A14),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF5F6674),
                    ),
                  ),
                ),
              ],
            ),
            if (tip != tips.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
