import 'package:flutter/material.dart';

import '../../core/routes/app_navigator.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_notice.dart';
import '../../services/session_service.dart';

class AuthSessionHandler {
  AuthSessionHandler._();

  static bool _isHandlingUnauthorized = false;

  static Future<void> handleUnauthorized({
    String message = 'Phien dang nhap da het han. Vui long dang nhap lai.',
  }) async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      await SessionService().clearToken();

      final context = AppNavigator.context;
      final navigator = AppNavigator.navigatorKey.currentState;

      if (context != null) {
        AppNotice.showError(context, message);
      }

      if (navigator != null) {
        await navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}
