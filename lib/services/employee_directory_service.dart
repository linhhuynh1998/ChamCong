import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/employee_list_item.dart';
import 'session_service.dart';

class EmployeeDirectoryService {
  EmployeeDirectoryService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<EmployeeListItem>> listEmployees() async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/employees',
      headers: <String, String>{
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(EmployeeListItem.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  Future<EmployeeListItem?> fetchEmployee(String id) async {
    if (id.trim().isEmpty) {
      return null;
    }

    final token = await _sessionService.getToken();
    final response = await _apiClient.get(
      '/company/employees/$id',
      headers: _buildAuthHeaders(token),
    );

    final rawItem = _extractItem(response);
    if (rawItem == null || rawItem.isEmpty) {
      return null;
    }

    return EmployeeListItem.fromJson(rawItem);
  }

  Future<String> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String employeeCode,
    required String birthDate,
    required String address,
    required String accessRoleId,
    required String accessRoleName,
    required String regionId,
    required String branchId,
    required String departmentId,
    required String jobTitleId,
    required String status,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.post(
      '/company/employees',
      headers: _buildAuthHeaders(token),
      body: _buildEmployeeBody(
        name: name,
        phone: phone,
        email: email,
        employeeCode: employeeCode,
        birthDate: birthDate,
        address: address,
        accessRoleId: accessRoleId,
        accessRoleName: accessRoleName,
        regionId: regionId,
        branchId: branchId,
        departmentId: departmentId,
        jobTitleId: jobTitleId,
        status: status,
      ),
      formUrlEncoded: true,
    );

    return response['message']?.toString() ?? 'Tạo nhân viên thành công.';
  }

  Future<String> updateEmployee(
    String id, {
    required String name,
    required String phone,
    required String email,
    required String employeeCode,
    required String birthDate,
    required String address,
    required String accessRoleId,
    required String accessRoleName,
    required String regionId,
    required String branchId,
    required String departmentId,
    required String jobTitleId,
    required String status,
  }) async {
    final token = await _sessionService.getToken();
    final response = await _apiClient.patch(
      '/company/employees/$id',
      headers: _buildAuthHeaders(token),
      body: _buildEmployeeBody(
        name: name,
        phone: phone,
        email: email,
        employeeCode: employeeCode,
        birthDate: birthDate,
        address: address,
        accessRoleId: accessRoleId,
        accessRoleName: accessRoleName,
        regionId: regionId,
        branchId: branchId,
        departmentId: departmentId,
        jobTitleId: jobTitleId,
        status: status,
      ),
      formUrlEncoded: true,
    );

    return response['message']?.toString() ?? 'Cập nhật nhân viên thành công.';
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['items'],
      response['results'],
      response['records'],
      response['employees'],
      response['users'],
      response['staff'],
    ];

    for (final candidate in candidates) {
      if (candidate is List<dynamic>) {
        return candidate;
      }

      if (candidate is Map<String, dynamic>) {
        final nested = <dynamic>[
          candidate['items'],
          candidate['data'],
          candidate['results'],
          candidate['records'],
          candidate['employees'],
          candidate['users'],
          candidate['staff'],
        ];

        for (final nestedCandidate in nested) {
          if (nestedCandidate is List<dynamic>) {
            return nestedCandidate;
          }
        }
      }
    }

    return const <dynamic>[];
  }

  Map<String, dynamic>? _extractItem(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['data'],
      response['item'],
      response['result'],
      response['record'],
      response['employee'],
      response['user'],
      response,
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        if (_looksLikeEmployee(candidate)) {
          return candidate;
        }

        for (final value in candidate.values) {
          if (value is Map<String, dynamic> && _looksLikeEmployee(value)) {
            return value;
          }
        }
      }

      if (candidate is List) {
        final firstMap =
            candidate.whereType<Map<String, dynamic>>().firstOrNull;
        if (firstMap != null) {
          return firstMap;
        }
      }
    }

    return null;
  }

  bool _looksLikeEmployee(Map<String, dynamic> source) {
    const keys = <String>{
      'name',
      'full_name',
      'phone',
      'mobile',
      'email',
      'employee_id',
      'employee_code',
    };

    return source.keys.any(keys.contains);
  }

  Map<String, String> _buildAuthHeaders(String? token) {
    return <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _buildEmployeeBody({
    required String name,
    required String phone,
    required String email,
    required String employeeCode,
    required String birthDate,
    required String address,
    required String accessRoleId,
    required String accessRoleName,
    required String regionId,
    required String branchId,
    required String departmentId,
    required String jobTitleId,
    required String status,
  }) {
    final normalizedBirthDate = _normalizeBirthDateForApi(birthDate);

    final body = <String, dynamic>{
      'name': name,
      'full_name': name,
      if (phone.isNotEmpty) 'phone': phone,
      if (email.isNotEmpty) 'email': email,
      if (employeeCode.isNotEmpty) 'employee_id': employeeCode,
      if (employeeCode.isNotEmpty) 'employee_code': employeeCode,
      if (normalizedBirthDate.isNotEmpty) 'date_of_birth': normalizedBirthDate,
      if (normalizedBirthDate.isNotEmpty) 'birth_date': normalizedBirthDate,
      if (address.isNotEmpty) 'address': address,
      if (_looksLikePermissionGroupId(accessRoleId))
        'permission_group_id': accessRoleId,
      if (accessRoleId.isNotEmpty) 'role': accessRoleId,
      if (accessRoleName.isNotEmpty) 'role_name': accessRoleName,
      if (regionId.isNotEmpty) 'region_id': regionId,
      if (branchId.isNotEmpty) 'branch_id': branchId,
      if (departmentId.isNotEmpty) 'department_id': departmentId,
      if (departmentId.isNotEmpty) 'default_department_id': departmentId,
      if (jobTitleId.isNotEmpty) 'job_title_id': jobTitleId,
      if (jobTitleId.isNotEmpty) 'position_id': jobTitleId,
      if (status.isNotEmpty) 'status': status,
    };

    if (body['name'] == null || body['name'].toString().trim().isEmpty) {
      throw ApiException('Tên nhân viên không hợp lệ.');
    }

    return body;
  }

  bool _looksLikePermissionGroupId(String value) {
    return int.tryParse(value.trim()) != null;
  }

  String _normalizeBirthDateForApi(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final dashParts = trimmed.split('-');
    if (dashParts.length == 3) {
      if (dashParts[0].length == 4) {
        return trimmed;
      }

      if (dashParts[2].length == 4) {
        final day = dashParts[0].padLeft(2, '0');
        final month = dashParts[1].padLeft(2, '0');
        final year = dashParts[2];
        return '$year-$month-$day';
      }
    }

    final slashParts = trimmed.split('/');
    if (slashParts.length == 3 && slashParts[2].length == 4) {
      final day = slashParts[0].padLeft(2, '0');
      final month = slashParts[1].padLeft(2, '0');
      final year = slashParts[2];
      return '$year-$month-$day';
    }

    return trimmed;
  }
}
