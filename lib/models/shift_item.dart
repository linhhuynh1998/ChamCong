class ShiftItem {
  const ShiftItem({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    List<String>? regionIds,
    this.regionId,
    this.regionName,
    List<String>? branchIds,
    this.branchId,
    this.branchName,
    List<String>? departmentIds,
    List<String>? departmentNames,
    List<String>? jobTitleIds,
    List<String>? jobTitleNames,
    List<int>? weekdays,
  })  : _regionIds = regionIds,
        _branchIds = branchIds,
        _departmentIds = departmentIds,
        _departmentNames = departmentNames,
        _jobTitleIds = jobTitleIds,
        _jobTitleNames = jobTitleNames,
        _weekdays = weekdays;

  final String id;
  final String name;
  final String startHour;
  final String startMinute;
  final String endHour;
  final String endMinute;
  final List<String>? _regionIds;
  final String? regionId;
  final String? regionName;
  final List<String>? _branchIds;
  final String? branchId;
  final String? branchName;
  final List<String>? _departmentIds;
  final List<String>? _departmentNames;
  final List<String>? _jobTitleIds;
  final List<String>? _jobTitleNames;
  final List<int>? _weekdays;

  List<String> get regionIds => _regionIds ?? const <String>[];
  List<String> get branchIds => _branchIds ?? const <String>[];
  List<String> get departmentIds => _departmentIds ?? const <String>[];
  List<String> get departmentNames => _departmentNames ?? const <String>[];
  List<String> get jobTitleIds => _jobTitleIds ?? const <String>[];
  List<String> get jobTitleNames => _jobTitleNames ?? const <String>[];
  List<int> get weekdays => _weekdays ?? const <int>[];

  String get timeRange =>
      '${_padTwo(startHour)}:${_padTwo(startMinute)} - ${_padTwo(endHour)}:${_padTwo(endMinute)}';

  factory ShiftItem.fromJson(Map<String, dynamic> json) {
    final settings = _asMap(json['settings']) ?? const <String, dynamic>{};
    final region = _asMap(json['region']);
    final branch = _asMap(json['branch']);
    final departments = _asListOfMaps(json['departments']) +
        _asListOfMaps(json['department_list']) +
        _asListOfMaps(json['departmentDetails']);
    final jobTitles = _asListOfMaps(json['job_titles']) +
        _asListOfMaps(json['jobTitles']) +
        _asListOfMaps(json['positions']) +
        _asListOfMaps(json['job_title_list']) +
        _asListOfMaps(json['jobTitleDetails']);
    final departmentNamesFromKeys = _pickStringList(
      json,
      const [
        'department_names',
        'departmentNames',
        'department_name_list',
      ],
    );
    final jobTitleNamesFromKeys = _pickStringList(
      json,
      const [
        'job_title_names',
        'jobTitleNames',
        'position_names',
      ],
    );
    final regionIdsFromSettings =
        _pickStringList(settings, const ['region_ids']);
    final branchIdsFromSettings =
        _pickStringList(settings, const ['branch_ids']);
    final departmentIdsFromSettings = _pickStringList(
      settings,
      const ['department_ids'],
    );
    final jobTitleIdsFromSettings = _pickStringList(
      settings,
      const ['job_title_ids'],
    );
    final weekdaysFromSettings = _pickIntList(settings, const ['weekdays']);

    return ShiftItem(
      id: _pickFirstString(json, const ['id', 'shift_id']) ?? '',
      name: _pickFirstString(json, const ['name', 'title']) ?? 'Không có tên',
      startHour: _normalizeNumber(
        _pickFirstString(json, const ['start_hour', 'startHour']) ??
            _pickFirstString(settings, const ['start_hour']) ??
            _extractHour(json['start_time']?.toString()),
      ),
      startMinute: _normalizeNumber(
        _pickFirstString(json, const ['start_minute', 'startMinute']) ??
            _pickFirstString(settings, const ['start_minute']) ??
            _extractMinute(json['start_time']?.toString()),
      ),
      endHour: _normalizeNumber(
        _pickFirstString(json, const ['end_hour', 'endHour']) ??
            _pickFirstString(settings, const ['end_hour']) ??
            _extractHour(json['end_time']?.toString()),
      ),
      endMinute: _normalizeNumber(
        _pickFirstString(json, const ['end_minute', 'endMinute']) ??
            _pickFirstString(settings, const ['end_minute']) ??
            _extractMinute(json['end_time']?.toString()),
      ),
      regionIds: regionIdsFromSettings.isNotEmpty
          ? regionIdsFromSettings
          : _pickStringList(json, const ['region_ids', 'regionIds']),
      regionId: _pickFirstString(json, const ['region_id']) ??
          (regionIdsFromSettings.isNotEmpty
              ? regionIdsFromSettings.first
              : null) ??
          _pickFirstString(settings, const ['region_id']) ??
          region?['id']?.toString(),
      regionName: region?['name']?.toString() ??
          _pickFirstString(json, const ['region_name', 'regionName']),
      branchIds: branchIdsFromSettings.isNotEmpty
          ? branchIdsFromSettings
          : _pickStringList(json, const ['branch_ids', 'branchIds']),
      branchId: _pickFirstString(json, const ['branch_id']) ??
          (branchIdsFromSettings.isNotEmpty
              ? branchIdsFromSettings.first
              : null) ??
          _pickFirstString(settings, const ['branch_id']) ??
          branch?['id']?.toString(),
      branchName: branch?['name']?.toString() ??
          _pickFirstString(json, const ['branch_name', 'branchName']),
      departmentIds: departmentIdsFromSettings.isNotEmpty
          ? departmentIdsFromSettings
          : _pickStringList(
              json,
              const ['department_ids', 'departmentIds', 'department_id_list'],
            ).isNotEmpty
              ? _pickStringList(
                  json,
                  const [
                    'department_ids',
                    'departmentIds',
                    'department_id_list',
                  ],
                )
              : departments
                  .map((item) => item['id']?.toString() ?? '')
                  .where((item) => item.isNotEmpty)
                  .toList(),
      departmentNames: departmentNamesFromKeys.isNotEmpty
          ? departmentNamesFromKeys
          : departments
              .map((item) =>
                  _pickFirstString(item, const ['name', 'title']) ?? '')
              .where((item) => item.isNotEmpty)
              .toList(),
      jobTitleIds: jobTitleIdsFromSettings.isNotEmpty
          ? jobTitleIdsFromSettings
          : _pickStringList(
              json,
              const [
                'job_title_ids',
                'jobTitleIds',
                'position_ids',
                'job_title_id_list',
              ],
            ).isNotEmpty
              ? _pickStringList(
                  json,
                  const [
                    'job_title_ids',
                    'jobTitleIds',
                    'position_ids',
                    'job_title_id_list',
                  ],
                )
              : jobTitles
                  .map((item) => item['id']?.toString() ?? '')
                  .where((item) => item.isNotEmpty)
                  .toList(),
      jobTitleNames: jobTitleNamesFromKeys.isNotEmpty
          ? jobTitleNamesFromKeys
          : jobTitles
              .map((item) =>
                  _pickFirstString(item, const ['name', 'title']) ?? '')
              .where((item) => item.isNotEmpty)
              .toList(),
      weekdays: weekdaysFromSettings.isNotEmpty
          ? weekdaysFromSettings
          : _pickIntList(
              json,
              const ['weekdays', 'weekday_ids', 'days', 'working_days'],
            ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static String? _pickFirstString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static List<String> _pickStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return _pickFirstString(item, const ['name', 'title', 'id']) ??
                    '';
              }
              return item?.toString().trim() ?? '';
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return const <String>[];
  }

  static List<int> _pickIntList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return int.tryParse(
                  _pickFirstString(item, const ['id', 'value', 'day']) ?? '',
                );
              }
              return int.tryParse(item?.toString() ?? '');
            })
            .whereType<int>()
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((item) => int.tryParse(item.trim()))
            .whereType<int>()
            .toList();
      }
    }

    return const <int>[];
  }

  static String _extractHour(String? time) {
    if (time == null || !time.contains(':')) {
      return '';
    }
    return time.split(':').first;
  }

  static String _extractMinute(String? time) {
    if (time == null || !time.contains(':')) {
      return '';
    }
    final parts = time.split(':');
    return parts.length > 1 ? parts[1] : '';
  }

  static String _normalizeNumber(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      return '';
    }
    return parsed.toString().padLeft(2, '0');
  }

  static String _padTwo(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '00';
    }
    return parsed.toString().padLeft(2, '0');
  }
}
