import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimarySectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PrimarySectionAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBottomDivider = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBottomDivider;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 88,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 68,
      bottom: showBottomDivider
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
            )
          : null,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.sectionHeader,
          size: 30,
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.sectionHeader,
        ),
      ),
      actions: actions,
    );
  }
}
