import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/routes/app_routes.dart';
import '../core/widgets/app_loading.dart';
import '../core/widgets/app_notice.dart';
import '../services/auth_service.dart';
import '../services/biometric_credentials_service.dart';
import '../services/biometric_service.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    AuthService? authService,
    BiometricService? biometricService,
    BiometricCredentialsService? credentialsService,
  })
      : _authService = authService ?? AuthService(),
        _biometricService = biometricService ?? BiometricService(),
        _credentialsService =
            credentialsService ?? BiometricCredentialsService(),
        emailController = TextEditingController(),
        passwordController = TextEditingController();

  final AuthService _authService;
  final BiometricService _biometricService;
  final BiometricCredentialsService _credentialsService;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  Future<bool> hasSavedSession() async {
    final token = await _authService.getSavedToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> submit(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppNotice.showError(
        context,
        'Vui lòng nhập đầy đủ email và mật khẩu.',
      );
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    AppLoading.show(message: 'Đang đăng nhập...');

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      await _credentialsService.saveCredentials(
        email: email,
        password: password,
      );

      if (!context.mounted) {
        return;
      }

      AppNotice.showSuccess(context, response.message);
      await Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on ApiException catch (error) {
      if (context.mounted) {
        AppNotice.showError(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        AppNotice.showError(
          context,
          'Đăng nhập thất bại. Vui lòng thử lại.',
        );
      }
    } finally {
      AppLoading.hide();
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loginWithBiometric(BuildContext context) async {
    if (_isSubmitting) {
      return;
    }

    final savedCredentials = await _credentialsService.getCredentials();
    final hasSession = await hasSavedSession();
    if (savedCredentials == null && !hasSession) {
      if (context.mounted) {
        AppNotice.showInfo(
          context,
          'Hãy đăng nhập bằng email và mật khẩu trước để bật đăng nhập nhanh.',
        );
      }
      return;
    }

    _isSubmitting = true;
    notifyListeners();
    AppLoading.show(message: 'Đang xác thực sinh trắc học...');

    try {
      final didAuthenticate = await _biometricService.authenticateForLogin();
      if (!didAuthenticate) {
        if (context.mounted) {
          AppNotice.showError(context, 'Xác thực thất bại hoặc đã bị hủy.');
        }
        return;
      }

      if (savedCredentials != null) {
        await _authService.login(
          email: savedCredentials.email,
          password: savedCredentials.password,
        );
      }

      if (!context.mounted) {
        return;
      }

      AppNotice.showSuccess(context, 'Đăng nhập nhanh thành công.');
      await Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on ApiException catch (error) {
      if (context.mounted) {
        AppNotice.showError(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        AppNotice.showError(
          context,
          'Không thể đăng nhập bằng sinh trắc học. Vui lòng thử lại.',
        );
      }
    } finally {
      AppLoading.hide();
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void loginWithEmail(BuildContext context) {
    AppNotice.showInfo(context, 'Đăng nhập bằng email sẽ được kết nối sau.');
  }

  void loginWithGoogle(BuildContext context) {
    AppNotice.showInfo(context, 'Đăng nhập bằng Google sẽ được kết nối sau.');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
