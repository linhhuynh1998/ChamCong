import 'package:local_auth/local_auth.dart';

import '../core/network/api_exception.dart';

class BiometricService {
  BiometricService({
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> authenticateForLogin() async {
    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (!isSupported || !canCheckBiometrics) {
        throw ApiException('Thiết bị này chưa hỗ trợ vân tay hoặc Face ID.');
      }

      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: 'Xác thực để đăng nhập nhanh',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Không thể xác thực sinh trắc học. Vui lòng thử lại.');
    }
  }
}
