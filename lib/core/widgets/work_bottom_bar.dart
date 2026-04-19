import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

enum WorkBottomBarItem {
  work,
  task,
  support,
  account,
}

class WorkBottomBar extends StatelessWidget {
  const WorkBottomBar({
    super.key,
    this.currentItem = WorkBottomBarItem.work,
    this.onItemSelected,
  });

  final WorkBottomBarItem currentItem;
  final ValueChanged<WorkBottomBarItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF7DD38A);
    const inactiveColor = Color(0xFF202124);

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAEAEA),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_outlined,
            label: 'Làm Việc',
            color: currentItem == WorkBottomBarItem.work
                ? activeColor
                : inactiveColor,
            onTap: () => _handleTap(context, WorkBottomBarItem.work),
          ),
          _BottomItem(
            icon: Icons.access_time_rounded,
            label: 'Giao Việc',
            color: currentItem == WorkBottomBarItem.task
                ? activeColor
                : inactiveColor,
            onTap: () => _handleTap(context, WorkBottomBarItem.task),
          ),
          _BottomItem(
            icon: Icons.support_agent_rounded,
            label: 'Hỗ Trợ',
            color: currentItem == WorkBottomBarItem.support
                ? activeColor
                : inactiveColor,
            onTap: () => _handleTap(context, WorkBottomBarItem.support),
          ),
          _BottomItem(
            icon: Icons.account_circle_outlined,
            label: 'Tài Khoản',
            color: currentItem == WorkBottomBarItem.account
                ? activeColor
                : inactiveColor,
            onTap: () => _handleTap(context, WorkBottomBarItem.account),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WorkBottomBarItem item) {
    if (onItemSelected != null) {
      onItemSelected!.call(item);
      return;
    }

    switch (item) {
      case WorkBottomBarItem.work:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case WorkBottomBarItem.task:
      case WorkBottomBarItem.support:
        break;
      case WorkBottomBarItem.account:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
