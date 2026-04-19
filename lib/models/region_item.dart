class RegionItem {
  const RegionItem({
    required this.id,
    required this.name,
    required this.note,
  });

  final String id;
  final String name;
  final String note;

  factory RegionItem.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;

    return RegionItem(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? data['title']?.toString() ?? '',
      note: data['note']?.toString() ??
          data['description']?.toString() ??
          data['notes']?.toString() ??
          '',
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
