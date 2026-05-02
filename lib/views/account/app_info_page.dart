import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  static const String _appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: const PrimarySectionAppBar(
        title: 'Thông tin ứng dụng',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: const [
            _AppHeroCard(version: _appVersion),
            SizedBox(height: 16),
            _InfoCard(
              title: 'Mô tả',
              icon: Icons.apps_rounded,
              iconColor: Color(0xFF117A65),
              body:
                  'B2MSR hỗ trợ chấm công, quản lý ca làm, thiết lập doanh nghiệp và theo dõi thông tin nhân sự trong cùng một ứng dụng.',
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Điểm nổi bật',
              icon: Icons.auto_awesome_rounded,
              iconColor: Color(0xFF2667C9),
              body:
                  'Giao diện tối giản, thao tác nhanh trên di động và đồng bộ dữ liệu quản lý nội bộ theo thời gian thực.',
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Hỗ trợ',
              icon: Icons.support_agent_rounded,
              iconColor: Color(0xFFB25619),
              body:
                  'Nếu gặp vấn đề trong quá trình sử dụng, bạn có thể làm mới ứng dụng hoặc liên hệ bộ phận vận hành để kiểm tra tài khoản và dữ liệu.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeroCard extends StatelessWidget {
  const _AppHeroCard({
    required this.version,
  });

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0B8F61),
            Color(0xFF5AC88F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F0B8F61),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'B2MSR',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ứng dụng quản lý chấm công nội bộ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Phiên bản $version',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.body,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEFEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF5F6674),
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
