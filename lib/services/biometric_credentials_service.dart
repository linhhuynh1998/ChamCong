import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricCredentials {
  const BiometricCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class BiometricCredentialsService {
  BiometricCredentialsService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _emailKey = 'biometric_login_email';
  static const String _passwordKey = 'biometric_login_password';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _emailKey, value: email.trim());
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<BiometricCredentials?> getCredentials() async {
    final email = (await _secureStorage.read(key: _emailKey))?.trim();
    final password = await _secureStorage.read(key: _passwordKey);

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return BiometricCredentials(email: email, password: password);
  }

  Future<bool> hasCredentials() async {
    return await getCredentials() != null;
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }
}
