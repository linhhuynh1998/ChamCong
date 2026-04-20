import '../core/network/api_client.dart';
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
}
