class EmployeeListItem {
  const EmployeeListItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.employeeCode,
    required this.jobTitle,
    required this.department,
    this.accessRole = '',
    String? accessRoleId,
    this.regionId = '',
    this.regionName = '',
    this.branchId = '',
    this.branchName = '',
    this.departmentId = '',
    this.jobTitleId = '',
    this.birthDate = '',
    this.address = '',
    String? status,
  })  : _accessRoleId = accessRoleId,
        _status = status;

  final String id;
  final String name;
  final String phone;
  final String email;
  final String employeeCode;
  final String jobTitle;
  final String department;
  final String accessRole;
  final String? _accessRoleId;
  final String regionId;
  final String regionName;
  final String branchId;
  final String branchName;
  final String departmentId;
  final String jobTitleId;
  final String birthDate;
  final String address;
  final String? _status;

  String get accessRoleId => _accessRoleId ?? '';
  String get status => _status ?? '';

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
    final region = _asMap(source['region']) ?? _asMap(json['region']);
    final branch = _asMap(source['branch']) ?? _asMap(json['branch']);
    final department =
        _asMap(source['department']) ?? _asMap(json['department']);
    final jobTitle = _asMap(source['job_title']) ?? _asMap(json['job_title']);
    final permissionGroup =
        _asMap(source['permission_group']) ?? _asMap(json['permission_group']);

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
        'job_title_name',
      ]),
      department: _pickFirstString(source, const [
        'department',
        'department_name',
        'team',
      ]) !=
              ''
          ? _pickFirstString(source, const [
              'department',
              'department_name',
              'team',
            ])
          : department?['name']?.toString() ?? '',
      accessRole: _pickFirstString(source, const [
        'role',
        'access_role',
        'permission',
      ]) !=
              ''
          ? _pickFirstString(source, const [
              'role',
              'access_role',
              'permission',
            ])
          : permissionGroup?['name']?.toString() ??
              source['role_name']?.toString() ??
              '',
      accessRoleId: _pickFirstString(source, const [
        'permission_group_id',
        'role_id',
        'access_role_id',
      ]),
      regionId: _pickFirstString(source, const [
        'region_id',
      ]),
      regionName: region?['name']?.toString() ??
          _pickFirstString(source, const ['region_name']),
      branchId: _pickFirstString(source, const [
        'branch_id',
        'default_branch_id',
      ]),
      branchName: branch?['name']?.toString() ??
          _pickFirstString(source, const ['branch_name']),
      departmentId: _pickFirstString(source, const [
        'department_id',
        'default_department_id',
      ]),
      jobTitleId: _pickFirstString(source, const [
        'job_title_id',
        'position_id',
      ]) !=
              ''
          ? _pickFirstString(source, const [
              'job_title_id',
              'position_id',
            ])
          : jobTitle?['id']?.toString() ?? '',
      birthDate: _pickFirstString(source, const [
        'birth_date',
        'date_of_birth',
        'birthday',
      ]),
      address: _pickFirstString(source, const [
        'address',
        'full_address',
        'address_detail',
      ]),
      status: _pickFirstString(source, const [
        'status',
        'employment_status',
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

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
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
