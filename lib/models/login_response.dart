class LoginResponse {
  const LoginResponse({
    required this.message,
    this.token,
    this.success = true,
  });

  final String message;
  final String? token;
  final bool success;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final nestedData = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final token = json['token']?.toString() ??
        json['access_token']?.toString() ??
        nestedData['token']?.toString() ??
        nestedData['access_token']?.toString();
    final successValue = json['success'] ?? json['status'] ?? nestedData['success'];

    final bool success = switch (successValue) {
      bool value => value,
      int value => value == 1,
      String value =>
        value.toLowerCase() == 'true' ||
        value == '1' ||
        value.toLowerCase() == 'success',
      _ => token != null || json['message'] != null,
    };

    return LoginResponse(
      success: success,
      token: token,
      message: json['message']?.toString() ??
          json['msg']?.toString() ??
          nestedData['message']?.toString() ??
          json['error']?.toString() ??
          (success
              ? 'Dang nhap thanh cong.'
              : 'Dang nhap that bai.'),
    );
  }
}
