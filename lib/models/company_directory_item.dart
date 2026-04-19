class CompanyDirectoryItem {
  const CompanyDirectoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.regionId,
    this.regionName,
    this.branchId,
    this.branchName,
    this.departmentId,
    this.departmentName,
    this.country,
    this.city,
    this.ward,
    this.addressDetail,
    this.fullAddress,
    this.latitude,
    this.longitude,
    this.radius,
  });

  final String id;
  final String name;
  final String description;
  final String? regionId;
  final String? regionName;
  final String? branchId;
  final String? branchName;
  final String? departmentId;
  final String? departmentName;
  final String? country;
  final String? city;
  final String? ward;
  final String? addressDetail;
  final String? fullAddress;
  final String? latitude;
  final String? longitude;
  final String? radius;

  factory CompanyDirectoryItem.fromJson(Map<String, dynamic> json) {
    final region = _asMap(json['region']);
    final branch = _asMap(json['branch']);
    final department = _asMap(json['department']);

    return CompanyDirectoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['note']?.toString() ??
          '',
      regionId: json['region_id']?.toString() ?? region?['id']?.toString(),
      regionName: region?['name']?.toString(),
      branchId: json['branch_id']?.toString() ?? branch?['id']?.toString(),
      branchName: branch?['name']?.toString(),
      departmentId:
          json['department_id']?.toString() ?? department?['id']?.toString(),
      departmentName: department?['name']?.toString(),
      country: _pickFirstString(json, const [
        'country',
        'country_name',
      ]),
      city: _pickFirstString(json, const [
        'city',
        'city_name',
        'province',
        'province_name',
      ]),
      ward: _pickFirstString(json, const [
        'ward',
        'ward_name',
        'district',
        'district_name',
      ]),
      addressDetail: _pickFirstString(json, const [
        'address_detail',
        'detail_address',
        'street_address',
      ]),
      fullAddress: _pickFirstString(json, const [
        'full_address',
        'formatted_address',
        'company_address',
        'address',
      ]),
      latitude: _pickFirstString(json, const [
        'latitude',
        'lat',
        'checkin_latitude',
      ]),
      longitude: _pickFirstString(json, const [
        'longitude',
        'lng',
        'lon',
        'checkin_longitude',
      ]),
      radius: _pickFirstString(json, const [
        'radius',
        'checkin_radius_meters',
        'radius_meters',
      ]),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String? _pickFirstString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
