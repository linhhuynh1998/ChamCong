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
      id: _pickFirstString(data, const [
            'id',
            'permission_group_id',
            'group_id',
          ]) ??
          '',
      name: _pickFirstString(data, const [
            'name',
            'title',
            'group_name',
          ]) ??
          '',
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

  static String? _pickFirstString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
