import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/work_bottom_bar.dart';
import '../../services/app_notification_service.dart';
import '../../services/requests_service.dart';

class WorkDashboardPage extends StatefulWidget {
  const WorkDashboardPage({super.key});

  @override
  State<WorkDashboardPage> createState() => _WorkDashboardPageState();
}

class _WorkDashboardPageState extends State<WorkDashboardPage> {
  final AppNotificationService _notificationService = AppNotificationService();
  final RequestsService _requestsService = RequestsService();
  RequestSummaryCounts? _requestSummaryCounts;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRequestSummary();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadRequestSummary() async {
    final now = DateTime.now();
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 6));

    try {
      final summary = await _requestsService.fetchRequestSummary(
        start: start,
        end: end,
      );
      if (mounted) {
        setState(() => _requestSummaryCounts = summary);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _requestSummaryCounts = null);
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications = await _notificationService.fetchNotifications();
      final unreadCount =
          notifications.where((notification) => !notification.isRead).length;
      if (mounted) {
        setState(() => _unreadNotificationCount = unreadCount);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _unreadNotificationCount = 0);
      }
    }
  }

  DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  List<String> get _requestBadgeValues {
    final summary = _requestSummaryCounts;
    if (summary == null) {
      return const ['0', '0', '0'];
    }

    return [
      summary.pending.toString(),
      summary.approved.toString(),
      summary.rejected.toString(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Thư Mục',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.notifications,
                      );
                      if (mounted) {
                        _loadUnreadNotificationCount();
                      }
                    },
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                      color: Color(0xFF2E3D5A),
                    ),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _NotificationBadge(
                        count: _unreadNotificationCount,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.2,
              children: [
                _DashboardTile(
                  title: 'Yêu Cầu',
                  icon: Icons.notifications_active_outlined,
                  iconBackground: const Color(0xFFA7F0DE),
                  badgeValues: _requestBadgeValues,
                  badgeColors: const [
                    Color(0xFFFCEEDB),
                    Color(0xFFE7FAEF),
                    Color(0xFFFDEAF2),
                  ],
                  badgeTextColors: const [
                    Color(0xFFD8A366),
                    Color(0xFF20C46F),
                    Color(0xFFE05993),
                  ],
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      AppRoutes.requestManagement,
                    );
                    if (mounted) {
                      _loadRequestSummary();
                    }
                  },
                ),
                _DashboardTile(
                  title: 'Chấm Công',
                  icon: Icons.compare_arrows_rounded,
                  iconBackground: const Color(0xFFAED1FF),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.attendance,
                  ),
                ),
                _DashboardTile(
                  title: 'Xếp Ca',
                  icon: Icons.cached_rounded,
                  iconBackground: const Color(0xFFF3C58E),
                  onTap: () {},
                ),
                _DashboardTile(
                  title: 'Phiếu Lương',
                  icon: Icons.description_outlined,
                  iconBackground: const Color(0xFFA3DA84),
                  onTap: () {},
                ),
                _DashboardTile(
                  title: 'Hỗ Trợ',
                  icon: Icons.support_agent_rounded,
                  iconBackground: const Color(0xFFE88787),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ai Đang Làm Việc?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    size: 38,
                    color: Color(0xFFBEBEBE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.34,
              children: const [
                _StatTile(
                    value: '0', label: 'Đã Vào', color: Color(0xFF5B9A24)),
                _StatTile(
                    value: '0', label: 'Đi Muộn', color: Color(0xFFA4222A)),
                _StatTile(
                    value: '0', label: 'Đúng Giờ', color: Color(0xFF2B4B7A)),
                _StatTile(
                    value: '0', label: 'Chưa Vào', color: Color(0xFFE11A1A)),
                _StatTile(
                    value: '0', label: 'Nghỉ Phép', color: Color(0xFFE6A65B)),
                _StatTile(
                    value: '0',
                    label: 'Chia Sẻ Vị Trí',
                    color: Color(0xFF5D93EF)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const WorkBottomBar(
        currentItem: WorkBottomBarItem.work,
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE05993),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.onTap,
    this.badgeValues,
    this.badgeColors,
    this.badgeTextColors,
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final VoidCallback onTap;
  final List<String>? badgeValues;
  final List<Color>? badgeColors;
  final List<Color>? badgeTextColors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      iconBackground.withValues(alpha: 0.95),
                      iconBackground.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (badgeValues != null && badgeColors != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    badgeValues!.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        right: index == badgeValues!.length - 1 ? 0 : 8,
                      ),
                      child: Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColors![index],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeValues![index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                (badgeTextColors?.length ?? 0) > index
                                    ? badgeTextColors![index]
                                    : const Color(0xFF2F3A45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
