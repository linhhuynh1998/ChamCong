import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import 'request_type_picker_page.dart';
import '../../services/auth_service.dart';
import '../../services/request_employee_access.dart';
import '../../services/requests_service.dart';

class RequestManagementPage extends StatefulWidget {
  const RequestManagementPage({super.key});

  @override
  State<RequestManagementPage> createState() => _RequestManagementPageState();
}

class _RequestManagementPageState extends State<RequestManagementPage> {
  late DateTime _selectedDate;
  _RequestDateRangeMode _rangeMode = _RequestDateRangeMode.week;
  final AuthService _authService = AuthService();
  final RequestsService _requestsService = RequestsService();
  bool _isLoadingRequests = false;
  bool _canManageRequests = false;
  String? _busyRequestId;
  String? _requestsError;
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];
  RequestSummaryCounts? _summaryCounts;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUserAccess();
      _loadRequests();
    });
  }

  Future<void> _loadCurrentUserAccess() async {
    try {
      final profile = await _authService.me();
      if (!mounted) {
        return;
      }
      setState(() {
        _canManageRequests = RequestEmployeeAccess.canSelectEmployee(profile);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _canManageRequests = false);
    }
  }

  void _openRequestTypePicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RequestTypePickerPage(),
      ),
    );
  }

  Future<void> _openRequestDetail(Map<String, dynamic> item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RequestDetailPage(
          item: item,
          requestsService: _requestsService,
          canManageRequests: _canManageRequests,
        ),
      ),
    );

    if (changed == true) {
      await _loadRequests();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<_RequestDateRangeSelection>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.38),
      builder: (context) => _RequestDateRangeDialog(
        initialDate: _selectedDate,
        initialMode: _rangeMode,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        startOfRange: _startOfRange,
        endOfRange: _endOfRange,
      ),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked.date;
      _rangeMode = picked.mode;
    });
    await _loadRequests();
  }

  String get _rangeLabel {
    final start = _startOfRange(_selectedDate, _rangeMode);
    final end = _endOfRange(_selectedDate, _rangeMode);
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final offset = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: offset));
  }

  DateTime _startOfRange(DateTime value, _RequestDateRangeMode mode) {
    final date = DateTime(value.year, value.month, value.day);
    switch (mode) {
      case _RequestDateRangeMode.day:
        return date;
      case _RequestDateRangeMode.week:
        return _startOfWeek(date);
      case _RequestDateRangeMode.month:
        return DateTime(date.year, date.month);
    }
  }

  DateTime _endOfRange(DateTime value, _RequestDateRangeMode mode) {
    final date = DateTime(value.year, value.month, value.day);
    switch (mode) {
      case _RequestDateRangeMode.day:
        return date;
      case _RequestDateRangeMode.week:
        return _startOfWeek(date).add(const Duration(days: 6));
      case _RequestDateRangeMode.month:
        return DateTime(date.year, date.month + 1, 0);
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoadingRequests = true;
      _requestsError = null;
    });

    final start = _startOfRange(_selectedDate, _rangeMode);
    final end = _endOfRange(_selectedDate, _rangeMode);

    try {
      final items =
          await _requestsService.fetchRequests(start: start, end: end);
      RequestSummaryCounts? summary;
      try {
        summary = await _requestsService.fetchRequestSummary(
          start: start,
          end: end,
        );
      } catch (_) {
        summary = null;
      }
      setState(() {
        _requests = items;
        _summaryCounts = summary;
      });
    } catch (e) {
      setState(() {
        _requestsError = e.toString();
        _requests = <Map<String, dynamic>>[];
        _summaryCounts = null;
      });
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  List<Map<String, dynamic>> _requestsForTab(int tabIndex) {
    return _requests
        .where((request) => _requestMatchesTab(request, tabIndex))
        .toList(growable: false);
  }

  bool _requestMatchesTab(Map<String, dynamic> request, int tabIndex) {
    final status = _requestStatus(request);
    final statusCode = int.tryParse(status);
    if (statusCode != null) {
      if (tabIndex == 1) {
        return statusCode == 1;
      }
      if (tabIndex == 2) {
        return statusCode == 2;
      }
      return statusCode == 0;
    }

    final normalizedStatus = _normalizeStatusText(status);
    if (tabIndex == 1) {
      return normalizedStatus.contains('approve') ||
          normalizedStatus.contains('approved') ||
          normalizedStatus.contains('accept') ||
          normalizedStatus.contains('accepted') ||
          normalizedStatus.contains('approved') ||
          normalizedStatus.contains('da duyet') ||
          normalizedStatus.contains('chap thuan') ||
          normalizedStatus.contains('dong y');
    }

    if (tabIndex == 2) {
      return normalizedStatus.contains('reject') ||
          normalizedStatus.contains('rejected') ||
          normalizedStatus.contains('denied') ||
          normalizedStatus.contains('refuse') ||
          normalizedStatus.contains('refused') ||
          normalizedStatus.contains('tu choi');
    }

    if (status.isEmpty) {
      return true;
    }

    return normalizedStatus.contains('pending') ||
        normalizedStatus.contains('wait') ||
        normalizedStatus.contains('waiting') ||
        normalizedStatus.contains('request') ||
        normalizedStatus.contains('requested') ||
        normalizedStatus.contains('submit') ||
        normalizedStatus.contains('submitted') ||
        normalizedStatus.contains('open') ||
        normalizedStatus.contains('new') ||
        normalizedStatus.contains('cho duyet') ||
        normalizedStatus.contains('yeu cau');
  }

  String _requestStatus(Map<String, dynamic> request) {
    final raw = request['status'] ??
        request['state'] ??
        request['result'] ??
        request['approval_status'] ??
        request['request_status'];
    return raw?.toString().trim().toLowerCase() ?? '';
  }

  String _requestId(Map<String, dynamic> request) {
    return _pickText(request, const ['id', 'request_id']);
  }

  String _requestCompanyId(Map<String, dynamic> request) {
    return _pickText(request, const ['company_id', 'companyId']);
  }

  Future<void> _changeRequestStatus(
    Map<String, dynamic> request, {
    required String status,
  }) async {
    if (!_canManageRequests) {
      return;
    }

    final id = _requestId(request);
    if (id.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã yêu cầu.')),
      );
      return;
    }

    setState(() {
      _busyRequestId = id;
    });

    try {
      final message = await _requestsService.updateRequestStatus(
        id: id,
        status: status,
        companyId: _requestCompanyId(request),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _loadRequests();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (_busyRequestId == id) {
            _busyRequestId = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF4F7),
        appBar: PrimarySectionAppBar(
          title: 'Quản lý yêu cầu',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          showBottomDivider: false,
        ),
        body: Column(
          children: [
            _RequestFilterHeader(
              rangeLabel: _rangeLabel,
              onTap: _pickDateRange,
            ),
            _RequestTabs(
              pendingCount:
                  _summaryCounts?.pending ?? _requestsForTab(0).length,
              approvedCount:
                  _summaryCounts?.approved ?? _requestsForTab(1).length,
              rejectedCount:
                  _summaryCounts?.rejected ?? _requestsForTab(2).length,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent(0),
                  _buildTabContent(1),
                  _buildTabContent(2),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openRequestTypePicker(context),
          backgroundColor: const Color(0xFF26CC7D),
          elevation: 3,
          child: const Icon(Icons.add_rounded, size: 36, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requestsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _requestsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF7A8497)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadRequests, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final filtered = _requestsForTab(tabIndex);

    if (filtered.isEmpty) {
      final message = tabIndex == 0
          ? 'Chưa có yêu cầu nào'
          : tabIndex == 1
              ? 'Chưa có chấp thuận nào'
              : 'Chưa có từ chối nào';

      return _EmptyRequestView(message: message);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _RequestListCard(
          item: item,
          isBusy: _busyRequestId == _requestId(item),
          canManageRequests: _canManageRequests,
          onTap: () => _openRequestDetail(item),
          onApprove: () => _changeRequestStatus(item, status: 'approved'),
          onReject: () => _changeRequestStatus(item, status: 'rejected'),
        );
      },
    );
  }
}

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({
    required this.item,
    required this.onTap,
    required this.isBusy,
    required this.canManageRequests,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool isBusy;
  final bool canManageRequests;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = _requestEmployeeName(item);
    final title = _requestTitle(item);
    final status = _requestStatusInfo(item);
    final requestDate = _requestDate(item, start: true);
    final createdAt = _requestCreatedAt(item);
    final summaryFields = _requestSummaryFields(item);

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6ECF4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF223B63).withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    _InitialsAvatar(name: name, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3D5A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusPill(status: status),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDEFF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF20C46F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3D5A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatShortDate(requestDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6D7890),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDEFF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: _buildSummaryFieldRows(summaryFields),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDEFF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _requestCompanyName(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3E4A60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatCompactDateTime(createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6D7890),
                      ),
                    ),
                  ],
                ),
              ),
              if (canManageRequests && status.label == 'Chờ duyệt')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RequestActionButton(
                          label: 'Chấp nhận',
                          icon: Icons.check_rounded,
                          backgroundColor: const Color(0xFFE6F7EE),
                          foregroundColor: const Color(0xFF27B672),
                          onPressed: isBusy ? null : onApprove,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RequestActionButton(
                          label: 'Từ chối',
                          icon: Icons.close_rounded,
                          backgroundColor: const Color(0xFFFDEAF2),
                          foregroundColor: const Color(0xFFE05993),
                          onPressed: isBusy ? null : onReject,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildSummaryFieldRows(List<_RequestDisplayField> fields) {
  final visibleFields = fields.take(4).toList();
  if (visibleFields.isEmpty) {
    visibleFields.add(const _RequestDisplayField('THÔNG TIN', '--'));
  }
  while (visibleFields.length < 4) {
    visibleFields.add(const _RequestDisplayField('--', '--'));
  }

  return <Widget>[
    Row(
      children: [
        Expanded(child: _CardField.fromDisplayField(visibleFields[0])),
        const SizedBox(width: 18),
        Expanded(child: _CardField.fromDisplayField(visibleFields[1])),
      ],
    ),
    const SizedBox(height: 14),
    Row(
      children: [
        Expanded(child: _CardField.fromDisplayField(visibleFields[2])),
        const SizedBox(width: 18),
        Expanded(child: _CardField.fromDisplayField(visibleFields[3])),
      ],
    ),
  ];
}

List<Widget> _buildDetailFieldRows(List<_RequestDisplayField> fields) {
  if (fields.isEmpty) {
    return const <Widget>[
      _DetailInfoRow(label: 'Thông tin', value: '--'),
      SizedBox(height: 18),
    ];
  }

  return <Widget>[
    for (var index = 0; index < fields.length; index++) ...[
      _DetailInfoRow(
        label: fields[index].label,
        value: fields[index].value,
      ),
      SizedBox(height: index == fields.length - 1 ? 18 : 12),
    ],
  ];
}

class _RequestDisplayField {
  const _RequestDisplayField(this.label, this.value);

  final String label;
  final String value;
}

class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({
    super.key,
    required this.item,
    required this.requestsService,
    required this.canManageRequests,
  });

  final Map<String, dynamic> item;
  final RequestsService requestsService;
  final bool canManageRequests;

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  late final Future<Map<String, dynamic>> _detailFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    final id = _pickText(widget.item, const ['id', 'request_id']);
    _detailFuture = id.isEmpty
        ? Future<Map<String, dynamic>>.value(widget.item)
        : widget.requestsService
            .fetchRequestDetail(id)
            .then(
              (detail) => _mergeRequestData(widget.item, detail),
            )
            .catchError((_) => widget.item);
  }

  Future<void> _changeStatus(String status) async {
    if (!widget.canManageRequests || _isUpdatingStatus) {
      return;
    }

    final id = _pickText(widget.item, const ['id', 'request_id']);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã yêu cầu.')),
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);
    try {
      final message = await widget.requestsService.updateRequestStatus(
        id: id,
        status: status,
        companyId: _pickText(widget.item, const ['company_id', 'companyId']),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _requestStatusInfo(widget.item);
    final canShowActions =
        widget.canManageRequests && status.label == 'Chờ duyệt';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFC),
      appBar: PrimarySectionAppBar(
        title: 'Chi tiết',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
        actions: [
          if (canShowActions) ...[
            IconButton(
              tooltip: 'Chấp nhận',
              onPressed:
                  _isUpdatingStatus ? null : () => _changeStatus('approved'),
              icon: const Icon(Icons.check_rounded,
                  size: 28, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Từ chối',
              onPressed:
                  _isUpdatingStatus ? null : () => _changeStatus('rejected'),
              icon: const Icon(Icons.close_rounded,
                  size: 28, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          return _RequestDetailBody(item: snapshot.data ?? widget.item);
        },
      ),
    );
  }
}

class _RequestDetailBody extends StatelessWidget {
  const _RequestDetailBody({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = _requestEmployeeName(item);
    final title = _requestTitle(item);
    final status = _requestStatusInfo(item);
    final startDate = _requestDate(item, start: true);
    final endDate = _requestDate(item, start: false) ?? startDate;
    final branch = _requestField(
        item, const ['Chi nhánh', 'branch', 'branch_name', 'branchName']);
    final code = _requestField(item,
        const ['Mã đơn', 'code', 'request_code', 'requestCode', 'number']);
    final detailFields = _requestSummaryFields(item);
    final createdAt = _requestCreatedAt(item);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF1F1F1),
            padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
            child: Row(
              children: [
                Container(width: 4, height: 28, color: const Color(0xFF20C46F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2E3D5A)),
                  ),
                ),
                _StatusPill(status: status, large: true),
              ],
            ),
          ),
          _DetailSection(
            child: Column(
              children: [
                Row(
                  children: [
                    _InitialsAvatar(name: name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E3D5A)),
                      ),
                    ),
                    Text(_formatDayMonthTime(startDate),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6D7890))),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailInfoRow(label: 'Chi nhánh', value: branch),
                const SizedBox(height: 12),
                _DetailInfoRow(label: 'Mã đơn', value: code),
              ],
            ),
          ),
          _DetailSection(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 28, color: Color(0xFF20C46F)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngày',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF98A4B9),
                        ),
                      ),
                      Text(
                        '${_formatDateOnly(startDate)} - ${_formatDateOnly(endDate)}',
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2E3D5A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _DetailSection(
            child: Column(
              children: [
                ..._buildDetailFieldRows(detailFields),
                Row(
                  children: const [
                    Icon(Icons.groups_2_outlined,
                        size: 28, color: Color(0xFF20C46F)),
                    SizedBox(width: 14),
                    Text('Thông tin duyệt',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF98A4B9))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                        width: 4, height: 24, color: const Color(0xFF20C46F)),
                    const SizedBox(width: 10),
                    const Text('1',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF20C46F))),
                    const SizedBox(width: 12),
                    _InitialsAvatar(name: name, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status.label == 'Chờ duyệt'
                            ? _requestCompanyName(item)
                            : _requestReviewerName(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF20C46F)),
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: status.color.withOpacity(0.85),
                              width: 1.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.label.toUpperCase(),
                          style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF0F6FF),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _requestCompanyName(item),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: _approvalSummaryText(status.label),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                      fontSize: 15, height: 1.3, color: Color(0xFF2E3D5A)),
                ),
                const SizedBox(height: 4),
                const Text('Thứ hai',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF98A4B9))),
                if (status.label == 'Chờ duyệt') ...[
                  const SizedBox(height: 14),
                  Text(
                    'Yêu cầu đang chờ duyệt.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: Color(0xFF2E3D5A),
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatCompactDateTime(createdAt),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF98A4B9)),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _requestReviewerName(item),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: status.label == 'Từ chối'
                              ? ' đã từ chối yêu cầu.'
                              : ' đã duyệt yêu cầu.',
                        ),
                      ],
                    ),
                    style: const TextStyle(
                        fontSize: 15, height: 1.3, color: Color(0xFF2E3D5A)),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatCompactDateTime(createdAt),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF98A4B9)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    this.size = 48,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFBCC8E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.30,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    this.large = false,
  });

  final _RequestStatusInfo status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: large ? 128 : 96),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 7 : 6,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: status.color.withOpacity(0.7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        style: TextStyle(
          fontSize: large ? 15 : 13,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _RequestActionButton extends StatelessWidget {
  const _RequestActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: const Color(0xFFE8ECF2),
          disabledForegroundColor: const Color(0xFF9AA4B5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  factory _CardField.fromDisplayField(_RequestDisplayField field) {
    return _CardField(
      label: field.label.toUpperCase(),
      value: field.value,
      maxLines: 1,
    );
  }

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: Color(0xFF98A4B9),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '--' : value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            height: 1.15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3D5A),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      margin: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF98A4B9),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value.isEmpty ? '--' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E3D5A),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestStatusInfo {
  const _RequestStatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_RequestStatusInfo _requestStatusInfo(Map<String, dynamic> item) {
  final status = _pickText(item, const [
    'status',
    'state',
    'result',
    'approval_status',
    'request_status'
  ]).toLowerCase();
  final normalizedStatus = _normalizeStatusText(status);
  final statusCode = int.tryParse(status);
  if (statusCode == 1) {
    return const _RequestStatusInfo('Đã duyệt', Color(0xFF20C46F));
  }
  if (statusCode == 2) {
    return const _RequestStatusInfo('Từ chối', Color(0xFFE05993));
  }
  if (statusCode == 0) {
    return const _RequestStatusInfo('Chờ duyệt', Color(0xFFD8A366));
  }

  if (normalizedStatus.contains('reject') ||
      normalizedStatus.contains('denied') ||
      normalizedStatus.contains('refuse') ||
      normalizedStatus.contains('tu choi')) {
    return const _RequestStatusInfo('Từ chối', Color(0xFFE05993));
  }
  if (normalizedStatus.contains('approve') ||
      normalizedStatus.contains('accept') ||
      normalizedStatus.contains('da duyet') ||
      normalizedStatus.contains('dong y') ||
      normalizedStatus.contains('chap thuan')) {
    return const _RequestStatusInfo('Đã duyệt', Color(0xFF20C46F));
  }
  return const _RequestStatusInfo('Chờ duyệt', Color(0xFFD8A366));
}

String _normalizeStatusText(String value) {
  return _normalizeFieldKey(value).replaceAll('_', ' ');
}

String _requestTitle(Map<String, dynamic> item) {
  return _requestField(
    item,
    const [
      'Loại yêu cầu',
      'request_type',
      'requestType',
      'request_type_name',
      'type_name',
      'title',
      'name',
    ],
    fallback: 'Yêu cầu',
  );
}

String _requestEmployeeName(Map<String, dynamic> item) {
  final employee = _asMap(item['employee']);
  if (employee != null) {
    final employeeName = _pickText(
      employee,
      const ['name', 'full_name', 'fullName', 'employee_name', 'employeeName'],
    );
    if (employeeName.isNotEmpty) {
      return employeeName;
    }
  }

  final fields = _asMap(item['fields']);
  if (fields != null) {
    final fieldName = _pickText(fields,
        const ['Nhân viên', 'employee', 'employee_name', 'employeeName']);
    if (fieldName.isNotEmpty) {
      return fieldName;
    }
  }

  return _requestField(
    item,
    const [
      'employee_name',
      'employeeName',
      'requested_by',
      'user_name',
      'requester_name',
      'requester',
      'Người yêu cầu',
      'Nhân viên',
    ],
    fallback: 'Nhân viên',
  );
}

DateTime? _requestDate(Map<String, dynamic> item, {required bool start}) {
  final keys = start
      ? const [
          'Ngày',
          'request_date',
          'Ngày bắt đầu',
          'start_date',
          'start_at',
          'from_date',
          'date'
        ]
      : const ['Ngày kết thúc', 'end_date', 'end_at', 'to_date'];
  return _parseDateTime(_requestField(item, keys));
}

DateTime? _requestCreatedAt(Map<String, dynamic> item) {
  return _parseDateTime(_requestField(
    item,
    const [
      'Ngày tạo',
      'created_at',
      'createdAt',
      'submitted_at',
      'requested_at',
    ],
  ));
}

List<_RequestDisplayField> _requestSummaryFields(Map<String, dynamic> item) {
  final fields = _requestDynamicFields(item);
  if (fields.isNotEmpty) {
    return _orderRequestDisplayFields(fields);
  }

  return <_RequestDisplayField>[
    _RequestDisplayField(
        'Ngày', _formatDateOnly(_requestDate(item, start: true))),
    _RequestDisplayField(
        'Số tiền',
        _formatAmountText(
            _requestField(item, const ['amount', 'total', 'money']))),
    _RequestDisplayField('Trạng thái', _requestStatusInfo(item).label),
    _RequestDisplayField('Ghi chú',
        _requestField(item, const ['note', 'reason', 'description'])),
  ];
}

List<_RequestDisplayField> _orderRequestDisplayFields(
  List<_RequestDisplayField> fields,
) {
  final regularFields = <_RequestDisplayField>[];
  final totalFields = <_RequestDisplayField>[];

  for (final field in fields) {
    if (_isTotalAmountField(field.label)) {
      totalFields.add(field);
    } else {
      regularFields.add(field);
    }
  }

  return <_RequestDisplayField>[
    ...regularFields,
    ...totalFields,
  ];
}

bool _isTotalAmountField(String label) {
  final normalized = _normalizeFieldKey(label);
  return normalized == 'tong_so_tien' ||
      normalized == 'tong_tien' ||
      normalized == 'total_amount' ||
      normalized == 'total_money' ||
      normalized == 'grand_total';
}

List<_RequestDisplayField> _requestDynamicFields(Map<String, dynamic> item) {
  final results = <_RequestDisplayField>[];
  final seenLabels = <String>{};
  final seenValuesByKey = <String, String>{};

  void addField(String label, dynamic value) {
    final normalized = _normalizeFieldKey(label);
    if (normalized.isEmpty || seenLabels.contains(normalized)) {
      return;
    }
    if (normalized == 'cach_thuc_thanh_toan' &&
        !_isPaymentRequestTitle(_requestTitle(item))) {
      return;
    }
    if (_isHiddenRequestField(normalized)) {
      return;
    }

    final text = _formatRequestFieldValue(label, value);
    if (text.isEmpty) {
      return;
    }

    final duplicateKey = _requestFieldDuplicateKey(normalized);
    final normalizedText = _normalizeFieldValue(text);
    if (seenValuesByKey[duplicateKey] == normalizedText) {
      return;
    }

    seenLabels.add(normalized);
    seenValuesByKey[duplicateKey] = normalizedText;
    results.add(_RequestDisplayField(label, text));
  }

  for (final key in const ['payload', 'fields']) {
    final map = _asMap(item[key]);
    if (map == null) continue;
    for (final entry in map.entries) {
      addField(entry.key, entry.value);
    }
  }

  final details = _asList(item['details']);
  if (details != null) {
    for (var detailIndex = 0; detailIndex < details.length; detailIndex++) {
      final detail = details[detailIndex];
      final map = _asMap(detail);
      if (map == null) continue;
      final label = _pickText(map, const ['label', 'name', 'key', 'title']);
      final value = map['value'] ?? map['text'] ?? map['content'];
      if (label.isNotEmpty) {
        addField(label, value);
        continue;
      }

      for (final entry in map.entries) {
        final normalizedEntryKey = _normalizeFieldKey(entry.key);
        if (normalizedEntryKey.isEmpty ||
            normalizedEntryKey == 'muc' ||
            normalizedEntryKey == 'stt' ||
            _isHiddenRequestField(normalizedEntryKey)) {
          continue;
        }

        addField('Mục ${detailIndex + 1} - ${entry.key}', entry.value);
      }
    }
  }

  return results;
}

String _normalizeFieldValue(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool _isHiddenRequestField(String normalizedLabel) {
  return const {
    'id',
    'ma',
    'code',
    'title',
    'tieu_de',
    'request_type',
    'loai_yeu_cau',
    'employee',
    'employee_id',
    'employee_name',
    'nhan_vien',
    'ten_nhan_vien',
    'ma_ca_lam',
    'shift_id',
    'shift_code',
    'requester',
    'requester_id',
    'company',
    'company_id',
    'status',
    'delete',
    'created_at',
    'updated_at',
  }.contains(normalizedLabel);
}

String _requestFieldDuplicateKey(String normalizedLabel) {
  final itemPrefixMatch = RegExp(r'^(muc_\d+)_').firstMatch(normalizedLabel);
  final itemPrefix = itemPrefixMatch?.group(1);
  final baseLabel = itemPrefix == null
      ? normalizedLabel
      : normalizedLabel.substring(itemPrefix.length + 1);

  String withItemPrefix(String value) =>
      itemPrefix == null ? value : '${itemPrefix}_$value';

  if (normalizedLabel == 'ngay' ||
      normalizedLabel.contains('request_date') ||
      normalizedLabel.contains('ngay_bat_dau') ||
      normalizedLabel.contains('ngay_ket_thuc') ||
      normalizedLabel.contains('start_date') ||
      normalizedLabel.contains('end_date') ||
      normalizedLabel.contains('ngay_quyet_dinh') ||
      normalizedLabel.contains('decision_date')) {
    return 'date';
  }

  if (baseLabel == 'ten' ||
      baseLabel == 'ten_san_pham' ||
      baseLabel == 'san_pham' ||
      baseLabel == 'product' ||
      baseLabel == 'product_name' ||
      baseLabel == 'name') {
    return withItemPrefix('item_name');
  }

  if (baseLabel == 'don_gia' ||
      baseLabel == 'gia' ||
      baseLabel == 'gia_thanh' ||
      baseLabel == 'price' ||
      baseLabel == 'unit_price') {
    return withItemPrefix('unit_price');
  }

  if (baseLabel == 'thanh_tien' ||
      baseLabel == 'amount' ||
      baseLabel == 'total' ||
      baseLabel == 'line_total') {
    return withItemPrefix('line_total');
  }

  if (baseLabel == 'so_luong' ||
      baseLabel == 'quantity' ||
      baseLabel == 'qty') {
    return withItemPrefix('quantity');
  }

  if (baseLabel == 'ca_lam' ||
      baseLabel == 'ca_lam_viec' ||
      baseLabel == 'shift' ||
      baseLabel == 'shift_name' ||
      baseLabel == 'work_shift') {
    return withItemPrefix('shift_name');
  }

  if (normalizedLabel == 'gio_bat_dau' ||
      normalizedLabel == 'thoi_gian_bat_dau' ||
      normalizedLabel.contains('start_time') ||
      normalizedLabel.contains('time_start')) {
    return 'start_time';
  }

  if (normalizedLabel == 'gio_ket_thuc' ||
      normalizedLabel == 'thoi_gian_ket_thuc' ||
      normalizedLabel.contains('end_time') ||
      normalizedLabel.contains('time_end')) {
    return 'end_time';
  }

  if (normalizedLabel == 'noi_dung' ||
      normalizedLabel == 'noi_dung_trao_doi' ||
      normalizedLabel == 'ghi_chu' ||
      normalizedLabel == 'mo_ta' ||
      normalizedLabel.contains('content') ||
      normalizedLabel.contains('description') ||
      normalizedLabel.contains('note')) {
    return 'content';
  }

  if (normalizedLabel == 'nguoi_ban_giao' ||
      normalizedLabel == 'nguoi_nhan_ban_giao' ||
      normalizedLabel.contains('handover_person') ||
      normalizedLabel.contains('handover_receiver') ||
      normalizedLabel.contains('receiver')) {
    return 'handover_person';
  }

  if (normalizedLabel == 'loai' ||
      normalizedLabel.contains('loai_ky_luat') ||
      normalizedLabel.contains('discipline_type')) {
    return 'type';
  }

  if (normalizedLabel.contains('tien') ||
      normalizedLabel.contains('amount') ||
      normalizedLabel.contains('money')) {
    return 'amount';
  }

  return normalizedLabel;
}

String _formatRequestFieldValue(String label, dynamic value) {
  final text = _textFromValue(value);
  if (text.isEmpty) {
    return '';
  }

  final normalized = _normalizeFieldKey(label);
  if (normalized.contains('tien') ||
      normalized.contains('gia') ||
      normalized.contains('don_gia') ||
      normalized.contains('amount') ||
      normalized.contains('price') ||
      normalized.contains('money')) {
    return _formatAmountText(text);
  }

  return text;
}

bool _isPaymentRequestTitle(String title) {
  final normalized = _normalizeFieldKey(title);
  return normalized == 'thanh_toan' || normalized == 'payment';
}

String _formatAmountText(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return value;
  }

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _requestCompanyName(Map<String, dynamic> item) {
  final requester = _asMap(item['requester']);
  if (requester != null) {
    final requesterName = _pickText(
      requester,
      const ['name', 'full_name', 'fullName', 'company_name', 'companyName'],
    );
    if (requesterName.isNotEmpty) {
      return requesterName;
    }
  }

  final company = _asMap(item['company']);
  if (company != null) {
    final companyName = _pickText(
      company,
      const ['name', 'full_name', 'fullName', 'company_name', 'companyName'],
    );
    if (companyName.isNotEmpty) {
      return companyName;
    }
  }

  final direct = _pickText(
    item,
    const ['company_name', 'companyName', 'requester_name', 'requesterName'],
  );
  if (direct.isNotEmpty) {
    return direct;
  }

  return 'Công ty';
}

String _requestReviewerName(Map<String, dynamic> item) {
  final reviewer = _asMap(item['reviewer']);
  if (reviewer != null) {
    final reviewerName = _pickText(
      reviewer,
      const ['name', 'full_name', 'fullName', 'company_name', 'companyName'],
    );
    if (reviewerName.isNotEmpty) {
      return reviewerName;
    }
  }

  return _requestCompanyName(item);
}

String _approvalSummaryText(String statusLabel) {
  switch (statusLabel) {
    case 'Từ chối':
      return ' quản trị viên cấp cao nhất đã từ chối yêu cầu.';
    case 'Đã duyệt':
      return ' quản trị viên cấp cao nhất đã duyệt yêu cầu.';
    default:
      return ' quản trị viên cấp cao nhất đang xem xét yêu cầu.';
  }
}

Map<String, dynamic> _mergeRequestData(
  Map<String, dynamic> seed,
  Map<String, dynamic> detail,
) {
  final merged = Map<String, dynamic>.from(seed);
  detail.forEach((key, value) {
    final existing = merged[key];
    if (existing is Map<String, dynamic> && value is Map<String, dynamic>) {
      merged[key] = _mergeRequestData(existing, value);
    } else {
      if (value == null) {
        return;
      }
      if (value is String && value.trim().isEmpty) {
        return;
      }
      merged[key] = value;
    }
  });
  return merged;
}

String _requestField(Map<String, dynamic> item, List<String> keys,
    {String fallback = ''}) {
  final direct = _pickText(item, keys);
  if (direct.isNotEmpty) return direct;

  for (final nestedKey in const [
    'payload',
    'fields',
    'details',
    'data',
    'request'
  ]) {
    final nested = _asMap(item[nestedKey]);
    if (nested != null) {
      final value = _pickText(nested, keys);
      if (value.isNotEmpty) return value;
    }

    final nestedList = _asList(item[nestedKey]);
    if (nestedList != null) {
      for (final child in nestedList) {
        final childMap = _asMap(child);
        if (childMap == null) continue;
        final value = _pickText(childMap, keys);
        if (value.isNotEmpty) return value;

        final label =
            _pickText(childMap, const ['label', 'name', 'key', 'title']);
        if (keys.any((key) => _sameFieldKey(label, key))) {
          final childValue =
              _pickText(childMap, const ['value', 'text', 'content']);
          if (childValue.isNotEmpty) return childValue;
        }
      }
    }
  }

  for (final nested in _nestedMaps(item)) {
    final value = _pickText(nested, keys);
    if (value.isNotEmpty) return value;
  }

  return fallback;
}

String _pickText(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    if (item.containsKey(key)) {
      final value = _textFromValue(item[key]);
      if (value.isNotEmpty) return value;
    }
  }

  for (final entry in item.entries) {
    final entryKey = entry.key.toLowerCase();
    for (final key in keys) {
      if (_sameFieldKey(entryKey, key)) {
        final value = _textFromValue(entry.value);
        if (value.isNotEmpty) return value;
      }
    }
  }

  return '';
}

String _textFromValue(dynamic value) {
  if (value == null) return '';
  if (value is Map<String, dynamic>) {
    return _pickText(value,
        const ['name', 'title', 'full_name', 'fullName', 'value', 'label']);
  }
  return value.toString().trim();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

List<Map<String, dynamic>> _nestedMaps(Map<String, dynamic> item) {
  final maps = <Map<String, dynamic>>[];
  for (final value in item.values) {
    final map = _asMap(value);
    if (map != null) {
      maps.add(map);
    }
  }
  return maps;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) return decoded;
    } catch (_) {
      return null;
    }
  }
  return null;
}

bool _sameFieldKey(String first, String second) {
  return _normalizeFieldKey(first) == _normalizeFieldKey(second);
}

String _normalizeFieldKey(String value) {
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

DateTime? _parseDateTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return parsed;

  final match = RegExp(
    r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s+(\d{1,2}):(\d{1,2}))?',
  ).firstMatch(trimmed);
  if (match == null) return null;

  final day = int.tryParse(match.group(1) ?? '');
  final month = int.tryParse(match.group(2) ?? '');
  final year = int.tryParse(match.group(3) ?? '');
  final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
  final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
  if (day == null || month == null || year == null) return null;

  return DateTime(year, month, day, hour, minute);
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '--';
  return '${_two(value.day)}/${_two(value.month)}/${value.year} ${_two(value.hour)}:${_two(value.minute)}';
}

String _formatDateOnly(DateTime? value) {
  if (value == null) return '--';
  return '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

String _formatShortDate(DateTime? value) {
  if (value == null) return '--';
  return '${value.day} Th.${value.month}';
}

String _formatDayMonthTime(DateTime? value) {
  if (value == null) return '--';
  return '${_two(value.day)}/${_two(value.month)}';
}

String _formatCompactDateTime(DateTime? value) {
  if (value == null) return '';
  return '${_two(value.day)}/${_two(value.month)} ${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'NV';
  final first = parts.first.substring(0, 1);
  final last = parts.length == 1 ? '' : parts.last.substring(0, 1);
  return (first + last).toUpperCase();
}

enum _RequestDateRangeMode { day, week, month }

class _RequestDateRangeSelection {
  const _RequestDateRangeSelection({
    required this.date,
    required this.mode,
  });

  final DateTime date;
  final _RequestDateRangeMode mode;
}

class _RequestDateRangeDialog extends StatefulWidget {
  const _RequestDateRangeDialog({
    required this.initialDate,
    required this.initialMode,
    required this.firstDate,
    required this.lastDate,
    required this.startOfRange,
    required this.endOfRange,
  });

  final DateTime initialDate;
  final _RequestDateRangeMode initialMode;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime Function(DateTime, _RequestDateRangeMode) startOfRange;
  final DateTime Function(DateTime, _RequestDateRangeMode) endOfRange;

  @override
  State<_RequestDateRangeDialog> createState() =>
      _RequestDateRangeDialogState();
}

class _RequestDateRangeDialogState extends State<_RequestDateRangeDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late _RequestDateRangeMode _mode;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(widget.initialDate);
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _mode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 120;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          margin: EdgeInsets.fromLTRB(12, top, 12, 0),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickRangeButton(
                        label: 'Hôm nay',
                        selected: _mode == _RequestDateRangeMode.day,
                        onTap: () =>
                            _select(DateTime.now(), _RequestDateRangeMode.day),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickRangeButton(
                        label: 'Tuần này',
                        selected: _mode == _RequestDateRangeMode.week,
                        onTap: () =>
                            _select(DateTime.now(), _RequestDateRangeMode.week),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickRangeButton(
                        label: 'Tháng này',
                        selected: _mode == _RequestDateRangeMode.month,
                        onTap: () => _select(
                          DateTime.now(),
                          _RequestDateRangeMode.month,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    _MonthNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _canGoPrevious ? () => _moveMonth(-1) : null,
                    ),
                    Expanded(
                      child: Text(
                        '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3F4D5E),
                        ),
                      ),
                    ),
                    _MonthNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _canGoNext ? () => _moveMonth(1) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    _WeekdayLabel('Sun'),
                    _WeekdayLabel('M...'),
                    _WeekdayLabel('Tue'),
                    _WeekdayLabel('W...'),
                    _WeekdayLabel('Thu'),
                    _WeekdayLabel('Fri'),
                    _WeekdayLabel('Sat'),
                  ],
                ),
                const SizedBox(height: 14),
                _CalendarGrid(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  mode: _mode,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  startOfRange: widget.startOfRange,
                  endOfRange: widget.endOfRange,
                  onDateTap: (date) =>
                      _select(date, _RequestDateRangeMode.week),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canGoPrevious {
    final previous = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    return !previous
        .isBefore(DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  bool get _canGoNext {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _select(DateTime date, _RequestDateRangeMode mode) {
    Navigator.of(context).pop(
      _RequestDateRangeSelection(date: _normalize(date), mode: mode),
    );
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
  }

  static DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _monthName(int month) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _QuickRangeButton extends StatelessWidget {
  const _QuickRangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF20D77A),
          backgroundColor: selected ? const Color(0xFFEFFFF6) : Colors.white,
          side: const BorderSide(color: Color(0xFF20D77A), width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: EdgeInsets.zero,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 38),
      color: const Color(0xFF18AEEA),
      disabledColor: const Color(0xFFD5DCE5),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB8C1CC),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.mode,
    required this.firstDate,
    required this.lastDate,
    required this.startOfRange,
    required this.endOfRange,
    required this.onDateTap,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final _RequestDateRangeMode mode;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime Function(DateTime, _RequestDateRangeMode) startOfRange;
  final DateTime Function(DateTime, _RequestDateRangeMode) endOfRange;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final firstVisible = _firstVisibleDate(focusedMonth);
    final rangeStart = startOfRange(selectedDate, mode);
    final rangeEnd = endOfRange(selectedDate, mode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(6, (weekIndex) {
        return Padding(
          padding: EdgeInsets.only(top: weekIndex == 0 ? 0 : 16),
          child: Row(
            children: List<Widget>.generate(7, (dayIndex) {
              final index = weekIndex * 7 + dayIndex;
              final date = firstVisible.add(Duration(days: index));
              final disabled = date.isBefore(_normalize(firstDate)) ||
                  date.isAfter(_normalize(lastDate));
              final inRange =
                  !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
              final isStart = _isSameDate(date, rangeStart);
              final isEnd = _isSameDate(date, rangeEnd);

              return Expanded(
                child: _CalendarDayCell(
                  date: date,
                  isMuted: date.month != focusedMonth.month || disabled,
                  inRange: inRange,
                  isStart: isStart,
                  isEnd: isEnd,
                  onTap: disabled ? null : () => onDateTap(date),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  static DateTime _firstVisibleDate(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    return firstDay.subtract(Duration(days: firstDay.weekday % 7));
  }

  static DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isMuted,
    required this.inRange,
    required this.isStart,
    required this.isEnd,
    required this.onTap,
  });

  final DateTime date;
  final bool isMuted;
  final bool inRange;
  final bool isStart;
  final bool isEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = inRange
        ? Colors.white
        : isMuted
            ? const Color(0xFFDDE4EB)
            : const Color(0xFFCCD4DE);

    return SizedBox(
      height: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (inRange)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1FCB73),
                  borderRadius: BorderRadius.horizontal(
                    left: isStart ? const Radius.circular(22) : Radius.zero,
                    right: isEnd ? const Radius.circular(22) : Radius.zero,
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestFilterHeader extends StatelessWidget {
  const _RequestFilterHeader({
    required this.rangeLabel,
    required this.onTap,
  });

  final String rangeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rangeLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF93A0B6),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Color(0xFFB7C1D3),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    this.onTap,
    this.color = const Color(0xFF2E3D5A),
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 30,
        color: color,
      ),
    );
  }
}

class _RequestTabs extends StatelessWidget {
  const _RequestTabs({
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: const Color(0xFF20C46F),
      indicatorWeight: 3,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelColor: const Color(0xFF1FC36E),
      unselectedLabelColor: const Color(0xFFB2B9C8),
      dividerColor: Colors.transparent,
      tabs: [
        Tab(
          child: _RequestTabLabel(
            title: 'Yêu cầu',
            count: pendingCount.toString(),
            badgeColor: const Color(0xFFF6E9DC),
            badgeTextColor: const Color(0xFFD8A366),
          ),
        ),
        Tab(
          child: _RequestTabLabel(
            title: 'Chấp thuận',
            count: approvedCount.toString(),
            badgeColor: const Color(0xFFE6F7EE),
            badgeTextColor: const Color(0xFF27B672),
          ),
        ),
        Tab(
          child: _RequestTabLabel(
            title: 'Từ chối',
            count: rejectedCount.toString(),
            badgeColor: const Color(0xFFFDEAF2),
            badgeTextColor: const Color(0xFFE05993),
          ),
        ),
      ],
    );
  }
}

class _RequestTabLabel extends StatelessWidget {
  const _RequestTabLabel({
    required this.title,
    required this.count,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final String title;
  final String count;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: style),
        const SizedBox(width: 8),
        Container(
          width: 27,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRequestView extends StatelessWidget {
  const _EmptyRequestView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD7DEE8)),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 78,
              color: Color(0xFF25345B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B3A5A),
            ),
          ),
        ],
      ),
    );
  }
}
