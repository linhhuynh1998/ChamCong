import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class RequestFormStyle {
  const RequestFormStyle._();

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(22, 28, 22, 28);
  static const double itemGap = 26;
  static const double compactGap = 14;

  static const Color fieldBackground = Color(0xFFF5F7FA);
  static const Color requiredColor = Color(0xFFDF6A7D);
  static const double fieldRadius = 12;
  static const double fieldMinHeight = 62;
  static const double multilineMinHeight = 134;
  static const EdgeInsets fieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  static const double iconSize = 24;
  static const double iconTextGap = 14;

  static const TextStyle fieldTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle hintTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );
}
