class EmployeeProfile {
  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.jobTitle,
    required this.companyName,
    required this.companyId,
    required this.companyAddress,
    required this.companyLatitude,
    required this.companyLongitude,
    required this.companyRadiusKm,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String jobTitle;
  final String companyName;
  final String companyId;
  final String companyAddress;
  final double? companyLatitude;
  final double? companyLongitude;
  final double companyRadiusKm;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'job_title': jobTitle,
      'company_id': companyId,
      'company_name': companyName,
      'company_address': companyAddress,
      'company_latitude': companyLatitude,
      'company_longitude': companyLongitude,
      'company_radius_km': companyRadiusKm,
    };
  }

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rootMap = data is Map<String, dynamic> ? data : json;
    final map = _asMap(rootMap['user']) ?? rootMap;
    final company = _asMap(map['company']) ??
        _asMap(map['office']) ??
        _asMap(map['branch']) ??
        _asMap(map['store']);
    final addressSource = company ?? map;

    return EmployeeProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ??
          map['full_name']?.toString() ??
          map['username']?.toString() ??
          'Nhan vien',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? map['mobile']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      jobTitle: map['job_title']?.toString() ?? map['position']?.toString() ?? '',
      companyName: company?['name']?.toString() ??
          map['company']?.toString() ??
          map['company_name']?.toString() ??
          '',
      companyId: company?['id']?.toString() ??
          map['company_id']?.toString() ??
          map['companyId']?.toString() ??
          '',
      companyAddress: addressSource['company_address']?.toString() ??
          addressSource['address']?.toString() ??
          addressSource['full_address']?.toString() ??
          addressSource['office_address']?.toString() ??
          '',
      companyLatitude: _toDouble(
        company?['checkin_latitude'] ??
            company?['latitude'] ??
            company?['lat'] ??
            map['company_latitude'] ??
            map['office_latitude'] ??
            map['latitude_company'],
      ),
      companyLongitude: _toDouble(
        company?['checkin_longitude'] ??
            company?['longitude'] ??
            company?['lng'] ??
            company?['lon'] ??
            map['company_longitude'] ??
            map['office_longitude'] ??
            map['longitude_company'],
      ),
      companyRadiusKm: ((_toDouble(
                    company?['checkin_radius_meters'] ??
                        map['company_radius_meters'] ??
                        map['checkin_radius_meters'],
                  ) ??
                  ((_toDouble(map['company_radius_km']) ?? 0.3) * 1000)) /
              1000)
          .toDouble(),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
