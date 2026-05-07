import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/location_option.dart';
import 'session_service.dart';

class RequestTypeService {
  RequestTypeService({
    ApiClient? apiClient,
    SessionService? sessionService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionService = sessionService ?? SessionService();

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<List<LocationOption>> fetchRequestTypes() async {
    try {
      final token = await _sessionService.getToken();
      final response = await _apiClient.get(
        '/requests/types',
        headers: _buildAuthHeaders(token ?? ''),
      );

      final options = _mergeOptions(
        _extractOptions(response),
        _defaultOptions,
      );
      if (options.isNotEmpty) return options;
    } catch (_) {
      // Fall through to local defaults when API is unavailable.
    }

    return _defaultOptions;
  }

  Future<List<LocationOption>> fetchAdvanceTypes() async {
    try {
      final token = await _sessionService.getToken();
      final response = await _apiClient.get(
        '/requests/advance-types',
        headers: _buildAuthHeaders(token ?? ''),
      );

      final options = _mergeOptions(
        _extractOptionsRecursively(response),
        _defaultAdvanceOptions,
      );
      if (options.isNotEmpty) return options;
    } catch (_) {
      // Fall through to local defaults when API is unavailable.
    }

    return _defaultAdvanceOptions;
  }

  Future<List<LocationOption>> fetchRewardTypes() async {
    try {
      final token = await _sessionService.getToken();
      final response = await _apiClient.get(
        '/requests/reward-types',
        headers: _buildAuthHeaders(token ?? ''),
      );

      final options = _mergeOptions(
        _extractOptionsRecursively(response),
        _defaultRewardOptions,
      );
      if (options.isNotEmpty) return options;
    } catch (_) {
      // Fall through to local defaults when API is unavailable.
    }

    return _defaultRewardOptions;
  }

  Map<String, String> _buildAuthHeaders(String token) {
    if (token.trim().isEmpty) {
      throw ApiException('Phiên bản đã hết hạn. Vui lòng đăng nhập lại.');
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  List<LocationOption> _extractOptions(Map<String, dynamic> response) {
    final requests = _extractRequests(response);
    final options = <LocationOption>[];

    for (final request in requests) {
      final name = _pickFirstString(
        request,
        const [
          'request_type',
          'requestType',
          'request_type_name',
          'requestTypeName',
          'type',
          'type_name',
          'title',
          'label',
          'name',
        ],
      );
      if (name == null || name.isEmpty) {
        continue;
      }

      final id = _pickFirstString(
        request,
        const [
          'request_type',
          'requestType',
          'request_type_name',
          'requestTypeName',
          'type',
          'type_name',
          'id',
          'title',
          'label',
          'name'
        ],
      );

      final canonicalName = _canonicalizeRequestTypeName(name);

      options.add(
        LocationOption(
          id: (id == null || id.isEmpty) ? name : id,
          name: canonicalName,
        ),
      );
    }

    final unique = <String, LocationOption>{};
    for (final option in options) {
      final key = option.name.trim().toLowerCase();
      if (key.isNotEmpty) {
        unique[key] = option;
      }
    }

    final sorted = unique.values.toList();
    sorted.sort(_compareByPreferredOrder);
    return sorted;
  }

  List<LocationOption> _mergeOptions(
    List<LocationOption> primary,
    List<LocationOption> fallback,
  ) {
    final unique = <String, LocationOption>{};

    for (final option in fallback) {
      final key = option.name.trim().toLowerCase();
      if (key.isNotEmpty) {
        unique[key] = option;
      }
    }

    for (final option in primary) {
      final key = option.name.trim().toLowerCase();
      if (key.isNotEmpty) {
        unique[key] = option;
      }
    }

    final merged = unique.values.toList();
    merged.sort(_compareByPreferredOrder);
    return merged;
  }

  String _canonicalizeRequestTypeName(String value) {
    final normalized = _normalizeKey(value);

    const aliases = <String, String>{
      'tam_ung': 'Tạm ứng lương',
      'tam_ung_luong': 'Tạm ứng lương',
      'tam_ung_hoan_ung': 'Tạm ứng - Hoàn ứng',
      'hoan_ung': 'Tạm ứng - Hoàn ứng',
      'thuong_chuyen_can': 'Thưởng chuyên cần',
      'thuong_hieu_suat': 'Thưởng hiệu suất',
      'thuong_dot_xuat': 'Thưởng đột xuất',
      'thuong_le': 'Thưởng lễ',
      'khen_thuong': 'Khen thưởng',
      'muon': 'Mượn',
      'cong_tac_ra_ngoai': 'Công tác/Ra ngoài',
      'cong_tac': 'Công tác/Ra ngoài',
      'ra_ngoai': 'Công tác/Ra ngoài',
      'nghi_phep': 'Nghỉ phép',
      'lam_them_gio': 'Làm thêm giờ',
      'thanh_toan_chi_phi': 'Thanh toán chi phí',
      'thanh_toan': 'Thanh toán',
      'mua_hang': 'Mua hàng',
      'nghi_viec': 'Nghỉ việc',
      'dang_ky_ca': 'Đăng ký ca làm',
      'doi_ca': 'Đổi ca làm',
    };

    return aliases[normalized] ?? value.trim();
  }

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  List<Map<String, dynamic>> _extractRequests(Map<String, dynamic> response) {
    final payload = _extractPrimaryPayload(response);

    if (payload is List) {
      return _mapList(payload);
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const [
        'requests',
        'items',
        'results',
        'records',
      ]) {
        final value = payload[key];
        if (value is List) {
          return _mapList(value);
        }
      }

      for (final nested in _pickNestedPayloads(payload)) {
        if (nested is List) {
          return _mapList(nested);
        }

        if (nested is Map<String, dynamic>) {
          for (final key in const [
            'requests',
            'items',
            'results',
            'records',
          ]) {
            final value = nested[key];
            if (value is List) {
              return _mapList(value);
            }
          }
        }
      }
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _mapList(List source) {
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  int _compareByPreferredOrder(LocationOption a, LocationOption b) {
    final aIndex = _preferredOrderIndex(a.name);
    final bIndex = _preferredOrderIndex(b.name);

    if (aIndex != bIndex) {
      return aIndex.compareTo(bIndex);
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _preferredOrderIndex(String value) {
    final normalized = value.trim().toLowerCase();
    final index = _defaultOrderMap[normalized];
    if (index != null) {
      return index;
    }

    return _defaultOrderMap.length + 1000;
  }

  List<LocationOption> _extractOptionsRecursively(
    dynamic value, {
    bool fromListItem = false,
  }) {
    final results = <LocationOption>[];

    if (value is Map<String, dynamic>) {
      final name = _pickFirstString(
        value,
        const [
          'name',
          'label',
          'title',
          'text',
          'request_type',
          'requestType',
          'type',
          'value',
        ],
      );
      final id = _pickFirstString(
        value,
        const ['id', 'code', 'key', 'value', 'name'],
      );

      if (fromListItem && name != null && name.isNotEmpty) {
        results.add(
          LocationOption(
            id: (id == null || id.isEmpty) ? name : id,
            name: name,
          ),
        );
      }

      for (final nested in _pickNestedPayloads(value)) {
        results.addAll(
          _extractOptionsRecursively(
            nested,
            fromListItem: nested is! Map<String, dynamic>,
          ),
        );
      }

      return results;
    }

    if (value is List) {
      for (final item in value) {
        results.addAll(_extractOptionsRecursively(item, fromListItem: true));
      }
      return results;
    }

    final scalar = value?.toString().trim();
    if (fromListItem && scalar != null && scalar.isNotEmpty) {
      results.add(
        LocationOption(
          id: scalar,
          name: scalar,
        ),
      );
    }

    return results;
  }

  dynamic _extractPrimaryPayload(Map<String, dynamic> response) {
    for (final key in const [
      'data',
      'items',
      'results',
      'records',
      'requests',
    ]) {
      final value = response[key];
      if (value is List || value is Map<String, dynamic>) {
        return value;
      }
    }

    return response;
  }

  Iterable<dynamic> _pickNestedPayloads(Map<String, dynamic> source) sync* {
    for (final key in const [
      'data',
      'items',
      'results',
      'records',
      'requests',
      'meta',
    ]) {
      final value = source[key];
      if (value != null) {
        yield value;
      }
    }
  }

  String? _pickFirstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  List<LocationOption> get _defaultOptions {
    const defaults = <String>[
      'Tạm ứng lương',
      'Tạm ứng - Hoàn ứng',
      'Khen thưởng',
      'Mượn',
      'Công tác/Ra ngoài',
      'Thay đổi thiết bị',
      'Kỷ luật',
      'Thay đổi giờ vào/ra',
      'Phiếu đề nghị',
      'Đi muộn, về sớm',
      'Suất ăn',
      'Nghỉ phép',
      'Làm thêm giờ',
      'Thanh toán',
      'Thanh toán chi phí',
      'Mua hàng',
      'Nghỉ việc',
      'Đăng ký ca làm',
      'Đổi ca làm',
    ];

    return defaults
        .map(
          (name) => LocationOption(
            id: name,
            name: name,
          ),
        )
        .toList(growable: false);
  }

  List<LocationOption> get _defaultAdvanceOptions {
    const defaults = <String>[
      'Tạm ứng công tác',
      'Tạm ứng mua hàng',
      'Hoàn ứng',
    ];

    return defaults
        .map(
          (name) => LocationOption(
            id: name,
            name: name,
          ),
        )
        .toList(growable: false);
  }

  List<LocationOption> get _defaultRewardOptions {
    const defaults = <String>[
      'Thưởng chuyên cần',
      'Thưởng hiệu suất',
      'Thưởng đột xuất',
      'Thưởng lễ',
    ];

    return defaults
        .map(
          (name) => LocationOption(
            id: name,
            name: name,
          ),
        )
        .toList(growable: false);
  }

  Map<String, int> get _defaultOrderMap {
    const defaults = <String>[
      'Tạm ứng lương',
      'Tạm ứng - Hoàn ứng',
      'Khen thưởng',
      'Mượn',
      'Công tác/Ra ngoài',
      'Thay đổi thiết bị',
      'Kỷ luật',
      'Thay đổi giờ vào/ra',
      'Phiếu đề nghị',
      'Đi muộn, về sớm',
      'Suất ăn',
      'Nghỉ phép',
      'Làm thêm giờ',
      'Thanh toán',
      'Thanh toán chi phí',
      'Mua hàng',
      'Nghỉ việc',
      'Đăng ký ca làm',
      'Đổi ca làm',
    ];

    return <String, int>{
      for (var i = 0; i < defaults.length; i++) defaults[i].toLowerCase(): i,
    };
  }
}
