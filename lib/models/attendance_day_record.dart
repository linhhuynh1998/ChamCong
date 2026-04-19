class AttendanceDayRecord {
  const AttendanceDayRecord({
    required this.id,
    required this.workDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.location,
    required this.status,
    required this.statusLabel,
    required this.shiftName,
    required this.shiftStartTime,
    required this.shiftEndTime,
  });

  final String id;
  final DateTime workDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String location;
  final String status;
  final String statusLabel;
  final String shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;

  bool get hasCheckedIn => checkInTime != null && checkInTime!.isNotEmpty;
  bool get hasCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;

  factory AttendanceDayRecord.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    final shift = _asMap(map['shift']);
    final workingShift = _asMap(map['working_shift']);
    final attendanceStatus = _asMap(map['attendance_status']);
    final workDate = _parseDate(
          map['work_date'] ??
              map['date'] ??
              map['attendance_date'] ??
              map['created_at'],
        ) ??
        DateTime.now();

    return AttendanceDayRecord(
      id: map['id']?.toString() ??
          map['attendance_log_id']?.toString() ??
          map['log_id']?.toString() ??
          '',
      workDate: DateTime(workDate.year, workDate.month, workDate.day),
      checkInTime: _firstNonEmpty(<dynamic>[
        map['checkin_time'],
        map['check_in_time'],
        map['time_in'],
        map['checkin_at'],
        map['check_in'],
      ]),
      checkOutTime: _firstNonEmpty(<dynamic>[
        map['checkout_time'],
        map['check_out_time'],
        map['time_out'],
        map['checkout_at'],
        map['check_out'],
      ]),
      location: _firstNonEmpty(<dynamic>[
            map['location'],
            map['address'],
            map['current_address'],
          ]) ??
          '',
      status: _firstNonEmpty(<dynamic>[
            map['status'],
            attendanceStatus?['code'],
            map['state'],
          ]) ??
          '',
      statusLabel: _firstNonEmpty(<dynamic>[
            map['status_label'],
            attendanceStatus?['label'],
          ]) ??
          '',
      shiftName: _firstNonEmpty(<dynamic>[
            shift?['name'],
            workingShift?['name'],
          ]) ??
          '',
      shiftStartTime: _firstNonEmpty(<dynamic>[
        shift?['start_time'],
        workingShift?['start_time'],
      ]),
      shiftEndTime: _firstNonEmpty(<dynamic>[
        shift?['end_time'],
        workingShift?['end_time'],
      ]),
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
