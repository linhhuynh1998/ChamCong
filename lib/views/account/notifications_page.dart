import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/app_notification_item.dart';
import '../../services/app_notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/request_employee_access.dart';
import '../../services/requests_service.dart';
import '../home/request_management_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AppNotificationService _notificationService = AppNotificationService();
  final AuthService _authService = AuthService();
  final RequestsService _requestsService = RequestsService();

  bool _isLoading = false;
  bool _canManageRequests = false;
  String? _error;
  List<AppNotificationItem> _notifications = <AppNotificationItem>[];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAccess();
    _loadNotifications();
  }

  Future<void> _loadCurrentUserAccess() async {
    try {
      final profile = await _authService.me();
      if (!mounted) {
        return;
      }
      setState(() {
        _canManageRequests = RequestEmployeeAccess.canSelectEmployee(profile);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _canManageRequests = false);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _notificationService.fetchNotifications();
      if (mounted) {
        setState(() => _notifications = items);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _notifications = <AppNotificationItem>[];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        AppNotice.showSuccess(context, 'Đã đánh dấu tất cả là đã đọc.');
      }
    } catch (e) {
      if (mounted) {
        AppNotice.showError(context, e.toString());
      }
    }
  }

  Future<void> _openNotification(AppNotificationItem item) async {
    if (!item.isRead) {
      try {
        await _notificationService.markAsRead(item.id);
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final requestId = item.requestId.trim();
    if (requestId.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestDetailPage(
            item: _notificationRequestPayload(item),
            requestsService: _requestsService,
            canManageRequests: _canManageRequests,
          ),
        ),
      );
      if (mounted) {
        _loadNotifications();
      }
      return;
    }

    Map<String, dynamic> requestDetail;
    try {
      requestDetail = await _requestsService.fetchRequestDetail(requestId);
    } catch (e) {
      requestDetail = _notificationRequestPayload(item);
    }

    if (!mounted) {
      return;
    }

    // Extract 'request' object từ API response (backend structure: { request: {...}, employee: {...} })
    final requestData = requestDetail['request'] is Map
        ? requestDetail['request']
        : requestDetail;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailPage(
          item: requestData,
          requestsService: _requestsService,
          canManageRequests: _canManageRequests,
        ),
      ),
    );

    if (mounted) {
      _loadNotifications();
    }
  }

  Map<String, dynamic> _notificationRequestPayload(AppNotificationItem item) {
    return <String, dynamic>{
      'id': item.requestId,
      'request_id': item.requestId,
      ...item.data,
      if (item.title.isNotEmpty) 'title': item.title,
      if (item.body.isNotEmpty) 'body': item.body,
      if (item.type.isNotEmpty) 'type': item.type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((item) => !item.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: PrimarySectionAppBar(
        title: 'Thông báo',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'Đọc hết',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFF9AA8BB),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF657182),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 130),
          Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF9AA8BB),
            size: 52,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657182),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return _NotificationCard(
          item: item,
          onTap: () => _openNotification(item),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        item.isRead ? const Color(0xFF9AA8BB) : const Color(0xFF20C46F);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE7ECF4)
                  : const Color(0xFFCDEEDC),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Thông báo' : item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            item.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Color(0xFF657182),
                        ),
                      ),
                    ],
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatCreatedAt(item.createdAt!),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF9AA8BB),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF20C46F),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('approved')) {
      return Icons.check_circle_outline_rounded;
    }
    if (type.contains('rejected')) {
      return Icons.cancel_outlined;
    }
    if (type.contains('request')) {
      return Icons.assignment_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  String _formatCreatedAt(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
