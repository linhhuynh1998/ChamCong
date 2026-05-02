import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../controllers/attendance_home_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/work_bottom_bar.dart';
import '../../models/attendance_day_record.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  late final AttendanceHomeController _controller;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = AttendanceHomeController();
    _selectedDate = _normalizeDate(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runWithLoadingDialog(Future<void> Function() action) async {
    if (!mounted) {
      return;
    }

    AppLoading.show(message: 'Đang tải dữ liệu...');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await action();
    } finally {
      AppLoading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final snapshot = _controller.locationSnapshot;
            final today = _normalizeDate(DateTime.now());
            final normalizedSelectedDate = _normalizeDate(_selectedDate);
            final isTodaySelected = _isSameDate(normalizedSelectedDate, today);
            final isFutureSelected = normalizedSelectedDate.isAfter(today);
            final selectedRecord =
                _controller.attendanceHistory[normalizedSelectedDate];
            final hasCheckedIn = isTodaySelected
                ? _controller.hasCheckedInToday ||
                    _hasRecordedCheckIn(_controller.statusMessage)
                : selectedRecord?.hasCheckedIn == true;
            final hasCheckedOut = isTodaySelected
                ? _controller.hasCheckedOutToday
                : selectedRecord?.hasCheckedOut == true;
            final statusText = _buildStatusText(
              controller: _controller,
              selectedDate: normalizedSelectedDate,
              selectedRecord: selectedRecord,
              isFutureSelected: isFutureSelected,
              isTodaySelected: isTodaySelected,
            );
            final currentAddressText = _buildCurrentAddressText(
              snapshotCurrentAddress: snapshot?.currentAddress,
              selectedRecord: selectedRecord,
              isFutureSelected: isFutureSelected,
              isTodaySelected: isTodaySelected,
            );
            final actionTimeText = _buildActionTimeText(
              isFutureSelected: isFutureSelected,
              hasCheckedIn: hasCheckedIn,
              hasCheckedOut: hasCheckedOut,
              selectedRecord: selectedRecord,
              isTodaySelected: isTodaySelected,
              isSubmitting: _controller.isSubmitting,
            );
            final canSubmitAttendance = _canSubmitAttendance(
              isFutureSelected: isFutureSelected,
              isTodaySelected: isTodaySelected,
              hasCheckedIn: hasCheckedIn,
              hasCheckedOut: hasCheckedOut,
              selectedRecord: selectedRecord,
            );
            final actionTitle = _buildActionTitle(
              isFutureSelected: isFutureSelected,
              hasCheckedIn: hasCheckedIn,
              hasCheckedOut: hasCheckedOut,
              isTodaySelected: isTodaySelected,
              selectedRecord: selectedRecord,
            );

            return RefreshIndicator(
              onRefresh: () async {
                await _runWithLoadingDialog(() async {
                  await _controller.loadProfile();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _selectedDate = _normalizeDate(DateTime.now());
                  });
                });
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _HeaderRow(
                    employeeName: _controller.employeeName,
                    isSubmitting: _controller.isSubmitting,
                    onBack: () => Navigator.of(context).maybePop(),
                    onRefreshLocation: () async {
                      await _runWithLoadingDialog(() async {
                        await _controller.refreshLocation();
                      });
                      if (!context.mounted) {
                        return;
                      }
                      if (_controller.lastActionSucceeded) {
                        AppNotice.showInfo(
                          context,
                          _controller.statusMessage,
                        );
                      } else {
                        AppNotice.showError(context, _controller.statusMessage);
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'Lịch làm việc'),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 100,
                    child: _ScheduleStrip(
                      selectedDate: normalizedSelectedDate,
                      attendanceHistory: _controller.attendanceHistory,
                      onDateSelected: (date) async {
                        await _runWithLoadingDialog(() async {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _selectedDate = _normalizeDate(date);
                          });
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _CheckInHeroCard(
                    title: actionTitle,
                    timeLabel: actionTimeText,
                    isSubmitting: _controller.isSubmitting,
                    isEnabled: canSubmitAttendance,
                    onTap: _controller.isLoading ||
                        _controller.isSubmitting ||
                        !canSubmitAttendance
                    ? null
                    : () async {
                        final isCheckout = hasCheckedIn && !hasCheckedOut;
                        final reason = await _promptAttendanceReasonIfNeeded(
                          context,
                          isCheckout: isCheckout,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        if (reason == _reasonDialogCancelled) {
                          AppNotice.showError(
                            context,
                            'Bạn chưa nhập lý do!',
                          );
                          return;
                        }
                        final message = isCheckout
                            ? await _controller.submitCheckOut(
                                reason: reason,
                              )
                            : await _controller.submitCheckIn(
                                reason: reason,
                              );
                        if (!context.mounted) {
                          return;
                        }
                        if (_controller.lastActionSucceeded) {
                          AppNotice.showSuccess(context, message);
                        } else {
                          AppNotice.showError(context, message);
                        }
                      },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Thư Mục'),
                  const SizedBox(height: 18),
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
                        badgeValues: const ['0', '0', '0'],
                        badgeColors: const [
                          Color(0xFF7FD89A),
                          Color(0xFF7FD0F1),
                          Color(0xFF72A9FF),
                        ],
                        onTap: () {},
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
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const WorkBottomBar(
        currentItem: WorkBottomBarItem.work,
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.employeeName,
    required this.isSubmitting,
    required this.onBack,
    required this.onRefreshLocation,
  });

  final String employeeName;
  final bool isSubmitting;
  final VoidCallback onBack;
  final Future<void> Function() onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final initial = employeeName.isNotEmpty
        ? employeeName.characters.first.toUpperCase()
        : 'C';

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6ED07E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            employeeName.isEmpty ? 'Nhân Viên' : employeeName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IconButton(
            onPressed: isSubmitting ? null : () => onRefreshLocation(),
            icon: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFF4B6460),
              size: 26,
            ),
            tooltip: 'Cập nhật vị trí',
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 44,
          color: Color(0xFFC8C8C8),
        ),
      ],
    );
  }
}

class _ScheduleStrip extends StatefulWidget {
  const _ScheduleStrip({
    required this.selectedDate,
    required this.attendanceHistory,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final Map<DateTime, AttendanceDayRecord> attendanceHistory;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_ScheduleStrip> createState() => _ScheduleStripState();
}

class _ScheduleStripState extends State<_ScheduleStrip> {
  static const double _itemWidth = 104;
  static const double _itemSpacing = 10;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDate();
    });
  }

  @override
  void didUpdateWidget(covariant _ScheduleStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerSelectedDate(animated: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerSelectedDate({bool animated = false}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final today = _normalizeDate(DateTime.now());
    final startDate = today.subtract(const Duration(days: 3));
    final selectedIndex =
        _normalizeDate(widget.selectedDate).difference(startDate).inDays;
    final safeIndex = selectedIndex.clamp(0, 6);
    final itemExtent = _itemWidth + _itemSpacing;
    final viewport = _scrollController.position.viewportDimension;
    final targetOffset =
        (safeIndex * itemExtent) - ((viewport - _itemWidth) / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animated) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _scrollController.jumpTo(clampedOffset);
  }

  @override
  Widget build(BuildContext context) {
    final today = _normalizeDate(DateTime.now());
    final startDate = today.subtract(const Duration(days: 4));
    final items = List<DateTime>.generate(
      7,
      (index) => _normalizeDate(startDate.add(Duration(days: index))),
    );

    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final date = items[index];
        final record = widget.attendanceHistory[date];
        final isSelected = _isSameDate(date, widget.selectedDate);
        final isToday = _isSameDate(date, today);
        final isFuture = date.isAfter(today);

        return _ScheduleCard(
          date: date,
          isSelected: isSelected,
          isToday: isToday,
          isFuture: isFuture,
          hasRecord: record != null,
          onTap: () => widget.onDateSelected(date),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasRecord,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool hasRecord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdayLabel(date);
    final day = date.day.toString().padLeft(2, '0');
    final numberColor = isSelected
        ? const Color(0xFF72D48A)
        : isFuture
            ? const Color(0xFF9AA3AF)
            : const Color(0xFF1F2430);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF0FBFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF72D48A) : Colors.transparent,
            width: 1.6,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF979797),
            ),
          ),
            Text(
              day,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFD8D8D8)
                    : hasRecord
                        ? const Color(0xFF72D48A)
                        : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInHeroCard extends StatelessWidget {
  const _CheckInHeroCard({
    required this.title,
    required this.timeLabel,
    required this.isSubmitting,
    required this.isEnabled,
    required this.onTap,
  });

  final String title;
  final String timeLabel;
  final bool isSubmitting;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final biometricIcon =
        Platform.isIOS ? Icons.face_retouching_natural : Icons.fingerprint_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF7ED286)
                : const Color(0xFFC9D4CC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isSubmitting ? 'Đang xử lý...' : timeLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF2C2C2C),
                          ),
                        )
                      : Icon(
                          biometricIcon,
                          size: 35,
                          color: const Color(0xFF2C2C2C),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String value;
  final String? trailing;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF737373),
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4C8F60),
                  ),
                ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction == null ? null : () => onAction!.call(),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Color(0xFF1F2430),
            ),
          ),
        ],
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
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final VoidCallback onTap;
  final List<String>? badgeValues;
  final List<Color>? badgeColors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2F3A45),
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


bool _hasRecordedCheckIn(String statusMessage) {
  final normalized = statusMessage.toLowerCase();
  return normalized.contains('Vào Ca') ||
      normalized.contains('check in') ||
      normalized.contains('thanh cong');
}

const String _reasonDialogCancelled = '__reason_dialog_cancelled__';

Future<String?> _promptAttendanceReasonIfNeeded(
  BuildContext context, {
  required bool isCheckout,
}) async {
  final now = TimeOfDay.now();
  final needsLateReason = !isCheckout &&
      (now.hour > 8 || (now.hour == 8 && now.minute > 0));
  final needsEarlyCheckoutReason = isCheckout &&
      (now.hour < 17 || (now.hour == 17 && now.minute < 30));

  if (!needsLateReason && !needsEarlyCheckoutReason) {
    return null;
  }

  final title = needsLateReason ? 'Lý do đi muộn' : 'Lý do rời ca sớm';
  final hint = needsLateReason
      ? 'Nhập lý do vào ca muộn'
      : 'Nhập lý do rời ca sớm';
  var reasonText = '';

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final hasReason = reasonText.trim().isNotEmpty;
          final accentColor = needsLateReason
              ? const Color(0xFFE58E39)
              : const Color(0xFF1F8A70);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FCF9),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          needsLateReason
                              ? Icons.schedule_rounded
                              : Icons.logout_rounded,
                          color: accentColor,
                          size: 26,
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
                                color: Color(0xFF182028),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Vui lòng nhập lý do để tiếp tục chấm công.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF5B6673),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: hasReason
                            ? accentColor.withValues(alpha: 0.22)
                            : const Color(0xFFE7EEEA),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                      ),
                      child: TextField(
                        maxLines: 4,
                        minLines: 4,
                        autofocus: true,
                        cursorColor: accentColor,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          setDialogState(() {
                            reasonText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFADB5BD),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(
                            18,
                            18,
                            18,
                            18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(
                              _reasonDialogCancelled,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B6673),
                            side: const BorderSide(color: Color(0xFFD5DFD8)),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: hasReason
                              ? () {
                                  Navigator.of(dialogContext).pop(
                                    reasonText.trim(),
                                  );
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor: const Color(0xFFB9C7BE),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return result;
}

String _buildStatusText({
  required AttendanceHomeController controller,
  required DateTime selectedDate,
  required AttendanceDayRecord? selectedRecord,
  required bool isFutureSelected,
  required bool isTodaySelected,
}) {
  if (isFutureSelected) {
    return 'Chưa đến ngày vào ca.';
  }

  if (isTodaySelected) {
    return controller.statusMessage;
  }

  if (selectedRecord == null) {
    return 'Không có dữ liệu chấm công cho ngày này.';
  }

  final checkIn = _formatAttendanceTime(selectedRecord.checkInTime);
  final checkOut = _formatAttendanceTime(selectedRecord.checkOutTime);
  return 'Dữ liệu ngày ${_formatDisplayDate(selectedDate)}\n'
      'Vào Ca: $checkIn\n'
      'Rời Ca: $checkOut';
}

String _buildCurrentAddressText({
  required String? snapshotCurrentAddress,
  required AttendanceDayRecord? selectedRecord,
  required bool isFutureSelected,
  required bool isTodaySelected,
}) {
  if (isFutureSelected) {
    return 'Chưa đến ngày vào ca.';
  }

  if (isTodaySelected) {
    return snapshotCurrentAddress ?? 'Chưa lấy được địa chỉ hiện tại.';
  }

  if (selectedRecord == null || selectedRecord.location.isEmpty) {
    return 'Không có dữ liệu vị trí cho ngày đã chọn.';
  }

  return selectedRecord.location;
}

String _buildActionTitle({
  required bool isFutureSelected,
  required bool hasCheckedIn,
  required bool hasCheckedOut,
  required bool isTodaySelected,
  required AttendanceDayRecord? selectedRecord,
}) {
  if (isFutureSelected) {
    return 'Chưa Đến Ngày';
  }

  if (!isTodaySelected) {
    return hasCheckedOut
        ? 'Đã Rời Ca'
        : hasCheckedIn
            ? 'Đã Vào Ca'
            : 'Không Có Dữ Liệu';
  }

  if (_isBeforeCheckInWindow(selectedRecord) &&
      !hasCheckedIn &&
      !hasCheckedOut) {
    return 'Chưa Đến Giờ';
  }

  if (_isAfterCheckInDeadline(selectedRecord) &&
      !hasCheckedIn &&
      !hasCheckedOut) {
    return 'Hết Giờ Chấm Công';
  }

  return hasCheckedIn && !hasCheckedOut ? 'Rời Ca' : 'Vào Ca';
}

String _buildActionTimeText({
  required bool isFutureSelected,
  required bool hasCheckedIn,
  required bool hasCheckedOut,
  required AttendanceDayRecord? selectedRecord,
  required bool isTodaySelected,
  required bool isSubmitting,
}) {
  if (isSubmitting && isTodaySelected) {
    return 'Đang xử lý...';
  }

  if (isFutureSelected) {
    return _formatDisplayDate(DateTime.now().add(const Duration(days: 1)))
        .replaceFirst(
          _formatDisplayDate(DateTime.now().add(const Duration(days: 1))),
          'Chưa đến lịch',
        );
  }

  if (!isTodaySelected) {
    if (selectedRecord == null) {
      return 'Chưa có bản ghi';
    }
    if (hasCheckedOut) {
      return _formatAttendanceTime(selectedRecord.checkOutTime);
    }
    if (hasCheckedIn) {
      return _formatAttendanceTime(selectedRecord.checkInTime);
    }
    return 'Chưa có bản ghi';
  }

  if (_isBeforeCheckInWindow(selectedRecord) && !hasCheckedIn && !hasCheckedOut) {
    final shiftStart = _resolveShiftStart(selectedRecord);
    final checkInWindowStart = _resolveCheckInWindowStart(selectedRecord);
    return 'Ca ${_formatTimeOfDay(shiftStart)}, chấm công từ ${_formatTimeOfDay(checkInWindowStart)}';
  }

  if (_isAfterCheckInDeadline(selectedRecord) &&
      !hasCheckedIn &&
      !hasCheckedOut) {
    final shiftEnd = _resolveShiftEnd(selectedRecord);
    return 'Đã quá giờ chấm công ${_formatTimeOfDay(shiftEnd)}';
  }

  final now = TimeOfDay.now();
  final nowLabel =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  return nowLabel;
}

const TimeOfDay _defaultShiftStart = TimeOfDay(hour: 8, minute: 0);
const TimeOfDay _defaultShiftEnd = TimeOfDay(hour: 17, minute: 0);
const TimeOfDay _morningShiftStart = TimeOfDay(hour: 8, minute: 0);
const TimeOfDay _morningShiftEnd = TimeOfDay(hour: 14, minute: 30);
const TimeOfDay _afternoonShiftStart = TimeOfDay(hour: 14, minute: 0);
const TimeOfDay _afternoonShiftEnd = TimeOfDay(hour: 20, minute: 30);

bool _canSubmitAttendance({
  required bool isFutureSelected,
  required bool isTodaySelected,
  required bool hasCheckedIn,
  required bool hasCheckedOut,
  required AttendanceDayRecord? selectedRecord,
}) {
  if (isFutureSelected || !isTodaySelected) {
    return false;
  }

  if (!hasCheckedIn &&
      !hasCheckedOut &&
      _isBeforeCheckInWindow(selectedRecord)) {
    return false;
  }

  if (!hasCheckedIn &&
      !hasCheckedOut &&
      _isAfterCheckInDeadline(selectedRecord)) {
    return false;
  }

  return true;
}

bool _isBeforeCheckInWindow(AttendanceDayRecord? selectedRecord) {
  final now = TimeOfDay.now();
  return _timeOfDayToMinutes(now) <
      _timeOfDayToMinutes(_resolveCheckInWindowStart(selectedRecord));
}

int _timeOfDayToMinutes(TimeOfDay value) => (value.hour * 60) + value.minute;

TimeOfDay _resolveShiftStart(AttendanceDayRecord? record) {
  final parsed = _parseTimeOfDay(record?.shiftStartTime);
  if (parsed != null) {
    return parsed;
  }

  final inferred = _inferShiftTimeFromName(
    record?.shiftName,
    preferEndTime: false,
  );
  if (inferred != null) {
    return inferred;
  }

  return _defaultShiftStart;
}

TimeOfDay _resolveShiftEnd(AttendanceDayRecord? record) {
  final parsed = _parseTimeOfDay(record?.shiftEndTime);
  if (parsed != null) {
    return parsed;
  }

  final inferred = _inferShiftTimeFromName(
    record?.shiftName,
    preferEndTime: true,
  );
  if (inferred != null) {
    return inferred;
  }

  final shiftStart = _resolveShiftStart(record);
  final defaultStartMinutes = _timeOfDayToMinutes(_defaultShiftStart);
  final defaultEndMinutes = _timeOfDayToMinutes(_defaultShiftEnd);
  final totalMinutes = _timeOfDayToMinutes(shiftStart) +
      (defaultEndMinutes - defaultStartMinutes);
  return TimeOfDay(
    hour: (totalMinutes ~/ 60) % 24,
    minute: totalMinutes % 60,
  );
}

TimeOfDay _resolveCheckInWindowStart(AttendanceDayRecord? record) {
  final shiftStart = _resolveShiftStart(record);
  final totalMinutes = _timeOfDayToMinutes(shiftStart) - 60;
  final normalizedMinutes = totalMinutes < 0 ? 0 : totalMinutes;
  return TimeOfDay(
    hour: normalizedMinutes ~/ 60,
    minute: normalizedMinutes % 60,
  );
}

bool _isAfterCheckInDeadline(AttendanceDayRecord? selectedRecord) {
  final now = TimeOfDay.now();
  return _timeOfDayToMinutes(now) >
      _timeOfDayToMinutes(_resolveShiftEnd(selectedRecord));
}

TimeOfDay? _inferShiftTimeFromName(
  String? shiftName, {
  required bool preferEndTime,
}) {
  final normalized = shiftName?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.contains('sáng')) {
    return preferEndTime ? _morningShiftEnd : _morningShiftStart;
  }

  if (normalized.contains('chiều')) {
    return preferEndTime ? _afternoonShiftEnd : _afternoonShiftStart;
  }

  return null;
}

TimeOfDay? _parseTimeOfDay(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final parts = raw.split(':');
  if (parts.length < 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }

  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTimeOfDay(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatAttendanceTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return '--:--';
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }

  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDisplayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _weekdayLabel(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'T2';
    case DateTime.tuesday:
      return 'T3';
    case DateTime.wednesday:
      return 'T4';
    case DateTime.thursday:
      return 'T5';
    case DateTime.friday:
      return 'T6';
    case DateTime.saturday:
      return 'T7';
    default:
      return 'CN';
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
