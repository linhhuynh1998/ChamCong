import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimarySectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PrimarySectionAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBottomDivider = false,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.bottomDividerColor = AppColors.divider,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBottomDivider;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color bottomDividerColor;

  static final ButtonStyle actionButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size(68, 44),
    fixedSize: const Size(68, 44),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
  );

  static const TextStyle actionTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 88,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 68,
      bottom: showBottomDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: bottomDividerColor,
              ),
            )
          : null,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: foregroundColor,
          size: 30,
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
      actions: actions,
    );
  }
}
