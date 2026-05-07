class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.requestId,
    required this.createdAt,
    required this.readAt,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String requestId;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  bool get isRead => readAt != null;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? const <String, dynamic>{};
    final requestId = _firstNonEmptyText([
      _pickText(json, const ['request_id', 'requestId']),
      _pickText(data, const ['request_id', 'requestId', 'id']),
      _pickNestedText(data, const ['request', 'request_data'], const ['id']),
    ]);

    return AppNotificationItem(
      id: _pickText(json, const ['id', 'notification_id']),
      title: _pickText(json, const ['title', 'name']),
      body: _pickText(json, const ['body', 'message', 'content']),
      type: _pickText(json, const ['type', 'notification_type']),
      requestId: requestId,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      readAt: _parseDate(json['read_at'] ?? json['readAt']),
      data: data,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _pickText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return '';
  }

  static String _pickNestedText(
    Map<String, dynamic> source,
    List<String> parentKeys,
    List<String> childKeys,
  ) {
    for (final parentKey in parentKeys) {
      final nested = _asMap(source[parentKey]);
      if (nested == null) {
        continue;
      }

      final text = _pickText(nested, childKeys);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _firstNonEmptyText(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}
