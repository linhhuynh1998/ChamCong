class CompanyEntityItem {
  const CompanyEntityItem({
    required this.id,
    required this.name,
    required this.description,
    this.regionId,
  });

  final String id;
  final String name;
  final String description;
  final String? regionId;

  factory CompanyEntityItem.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;

    return CompanyEntityItem(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? data['title']?.toString() ?? '',
      description: data['description']?.toString() ??
          data['note']?.toString() ??
          data['notes']?.toString() ??
          '',
      regionId: data['region_id']?.toString(),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
