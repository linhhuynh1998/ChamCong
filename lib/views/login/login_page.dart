import 'package:flutter/material.dart';

import '../../controllers/login_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasSession = await _controller.hasSavedSession();
      if (!mounted || !hasSession) {
        return;
      }

      await Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 48,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        child: Column(
                          children: [
                            const _LogoCard(),
                            const SizedBox(height: 24),
                            _LoginTextField(
                              controller: _controller.emailController,
                              hintText: 'Nhập email của bạn',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _LoginTextField(
                              controller: _controller.passwordController,
                              hintText: 'Nhập mật khẩu',
                              icon: Icons.lock_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.mint,
                                        foregroundColor: AppColors.dark,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      onPressed: _controller.isSubmitting
                                          ? null
                                          : () => _controller.submit(context),
                                      child: Text(
                                        _controller.isSubmitting
                                            ? 'Đang xử lý...'
                                            : 'Đăng nhập',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _SquareActionButton(
                                  icon:
                                      Theme.of(context).platform ==
                                          TargetPlatform.iOS
                                      ? Icons.face_retouching_natural
                                      : Icons.fingerprint_rounded,
                                  onPressed: () => _controller
                                      .loginWithBiometric(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            const _DividerLabel(),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 150,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _SquareActionButton(
                                    icon: Icons.mail_outline_rounded,
                                    onPressed: () =>
                                        _controller.loginWithEmail(context),
                                  ),
                                  _SquareActionButton(
                                    label: 'G',
                                    labelColor: const Color(0xFF4285F4),
                                    onPressed: () =>
                                        _controller.loginWithGoogle(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  static const String _logoAsset = 'assets/logo/logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Image.asset(
          _logoAsset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF697586),
            size: 26,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 64),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1.2,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Hoặc',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF9A9A9A),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.onPressed,
    this.icon,
    this.label,
    this.labelColor,
  });

  final VoidCallback onPressed;
  final IconData? icon;
  final String? label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFDDF6FF),
          foregroundColor: AppColors.dark,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onPressed,
        child: Center(
          child: icon != null
              ? Icon(icon, size: 32)
              : Text(
                  label ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: labelColor ?? AppColors.dark,
                  ),
                ),
            ),
        ),
    );
  }
}
