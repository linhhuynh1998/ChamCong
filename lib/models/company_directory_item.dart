class CompanyDirectoryItem {
  const CompanyDirectoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.regionId,
    this.regionName,
  });

  final String id;
  final String name;
  final String description;
  final String? regionId;
  final String? regionName;

  factory CompanyDirectoryItem.fromJson(Map<String, dynamic> json) {
    final region = _asMap(json['region']);

    return CompanyDirectoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['note']?.toString() ??
          '',
      regionId: json['region_id']?.toString() ?? region?['id']?.toString(),
      regionName: region?['name']?.toString(),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
