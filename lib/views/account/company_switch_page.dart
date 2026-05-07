import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';

class CompanySwitchPage extends StatefulWidget {
  const CompanySwitchPage({super.key});

  @override
  State<CompanySwitchPage> createState() => _CompanySwitchPageState();
}

class _CompanySwitchPageState extends State<CompanySwitchPage> {
  String _selectedCompanyId = 'linhhuynh';

  static const List<({String id, String name, String subtitle, bool active})>
      _companies = <({String id, String name, String subtitle, bool active})>[
    (
      id: 'linhhuynh',
      name: 'LinhHuynh Developer',
      subtitle: 'Doanh nghiệp đang vận hành chính',
      active: true,
    ),
    (
      id: 'internal',
      name: 'Internal Operations',
      subtitle: 'Không gian thử nghiệm nội bộ cho cấu hình và báo cáo',
      active: false,
    ),
  ];

  void _save() {
    final company =
        _companies.firstWhere((item) => item.id == _selectedCompanyId);
    AppNotice.showSuccess(context, 'Đã chuyển sang ${company.name}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: PrimarySectionAppBar(
        title: 'Chuyển doanh nghiệp',
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
              icon: Icons.business_center_outlined,
              title: 'Chọn không gian làm việc',
              description:
                  'Chuyển nhanh giữa các doanh nghiệp để xem dữ liệu, cấu hình và quyền truy cập phù hợp.',
              accent: Color(0xFF2D4E84),
            ),
            const SizedBox(height: 16),
            ..._companies.map((company) {
              final selected = company.id == _selectedCompanyId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompanyCard(
                  title: company.name,
                  subtitle: company.subtitle,
                  active: company.active,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedCompanyId = company.id;
                    });
                  },
                ),
              );
            }),
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

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE7ECEA),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F7F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Đang dùng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : const Color(0xFFB1B8C3),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
