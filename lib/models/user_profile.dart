class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : json;

    return UserProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ??
          map['full_name']?.toString() ??
          map['username']?.toString() ??
          'Nhân viên',
      email: map['email']?.toString() ?? '',
    );
  }
}
