class EmployeeListItem {
  const EmployeeListItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.employeeCode,
    required this.jobTitle,
    required this.department,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String employeeCode;
  final String jobTitle;
  final String department;

  String get initials {
    final segments = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return '?';
    }

    if (segments.length == 1) {
      return _firstLetter(segments.first);
    }

    return '${_firstLetter(segments.first)}${_firstLetter(segments.last)}';
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystacks = <String>[
      name,
      phone,
      email,
      employeeCode,
      jobTitle,
      department,
    ];

    return haystacks.any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }

  factory EmployeeListItem.fromJson(Map<String, dynamic> json) {
    final source = _nestedUserMap(json) ?? json;

    return EmployeeListItem(
      id: _pickFirstString(source, const ['id', 'employee_id', 'user_id']),
      name: _pickFirstString(source, const [
        'name',
        'full_name',
        'employee_name',
        'username',
      ]),
      phone: _pickFirstString(source, const [
        'phone',
        'mobile',
        'phone_number',
        'tel',
      ]),
      email: _pickFirstString(source, const [
        'email',
        'mail',
      ]),
      employeeCode: _pickFirstString(source, const [
        'employee_code',
        'employee_id',
        'code',
      ]),
      jobTitle: _pickFirstString(source, const [
        'job_title',
        'position',
        'title',
      ]),
      department: _pickFirstString(source, const [
        'department',
        'department_name',
        'team',
      ]),
    );
  }

  static Map<String, dynamic>? _nestedUserMap(Map<String, dynamic> source) {
    final candidates = <dynamic>[
      source['user'],
      source['employee'],
      source['staff'],
      source['member'],
      source['account'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
    }

    return null;
  }

  static String _pickFirstString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  static String _firstLetter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
