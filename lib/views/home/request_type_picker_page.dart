import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/location_option.dart';
import '../../services/request_type_service.dart';
import 'advance_reimbursement_request_page.dart';
import 'borrow_request_page.dart';
import 'business_trip_out_request_page.dart';
import 'device_change_request_page.dart';
import 'discipline_request_page.dart';
import 'early_late_request_page.dart';
import 'late_early_request_page.dart';
import 'leave_request_page.dart';
import 'meal_request_page.dart';
import 'overtime_request_page.dart';
import 'payment_expense_request_page.dart';
import 'payment_request_page.dart';
import 'proposal_request_page.dart';
import 'purchase_request_page.dart';
import 'resignation_request_page.dart';
import 'reward_request_page.dart';
import 'salary_advance_request_page.dart';
import 'shift_change_request_page.dart';
import 'shift_registration_request_page.dart';
import 'time_change_request_page.dart';

class RequestTypePickerPage extends StatefulWidget {
  const RequestTypePickerPage({
    super.key,
    this.filterForSalaryAdvance = false,
  });

  final bool filterForSalaryAdvance;

  @override
  State<RequestTypePickerPage> createState() => _RequestTypePickerPageState();
}

class _RequestTypePickerPageState extends State<RequestTypePickerPage> {
  final RequestTypeService _service = RequestTypeService();
  late Future<List<LocationOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchRequestTypes();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchRequestTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimarySectionAppBar(
        title: 'Yêu cầu',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        showBottomDivider: false,
      ),
      body: FutureBuilder<List<LocationOption>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7A8497),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <LocationOption>[];

          // Filter items if requesting only salary advance types
          final filteredItems = widget.filterForSalaryAdvance
              ? items.where((item) => _isSalaryAdvanceType(item.name)).toList()
              : items;

          if (filteredItems.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có loại yêu cầu',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A8497),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEDEFF3),
            ),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _RequestTypeTile(
                title: item.name,
                icon: _resolveIcon(item.name),
                onTap: () => _openRequestType(context, item),
              );
            },
          );
        },
      ),
    );
  }

  void _openRequestType(BuildContext context, LocationOption item) {
    final normalized = _normalizeTitle(item.name);

    // If filtering for salary advance, always return the item
    if (widget.filterForSalaryAdvance) {
      Navigator.of(context).pop(item);
      return;
    }

    if (normalized.contains('tam_ung_hoan_ung') ||
        normalized.contains('hoan_ung')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AdvanceReimbursementRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('tam_ung_luong')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SalaryAdvanceRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('di_muon') || normalized.contains('ve_som')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LateEarlyRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('di_som') || normalized.contains('ve_muon')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const EarlyLateRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('muon')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BorrowRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('khen_thuong')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const RewardRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('cong_tac') || normalized.contains('ra_ngoai')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BusinessTripOutRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('thiet_bi')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DeviceChangeRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('ky_luat')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DisciplineRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('thay_doi_gio') || normalized.contains('vao_ra')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TimeChangeRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('phieu_de_nghi')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProposalRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('suat_an')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MealRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('nghi_phep')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LeaveRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('lam_them') || normalized.contains('them_gio')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const OvertimeRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('thanh_toan_chi_phi')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaymentExpenseRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('thanh_toan')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaymentRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('mua_hang')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PurchaseRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('nghi_viec')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ResignationRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('dang_ky_ca')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ShiftRegistrationRequestPage(),
        ),
      );
      return;
    }

    if (normalized.contains('doi_ca')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ShiftChangeRequestPage(),
        ),
      );
      return;
    }

    Navigator.of(context).pop(item);
  }

  bool _isSalaryAdvanceType(String typeName) {
    final normalized = _normalizeTitle(typeName);
    return normalized.contains('tam_ung');
  }

  String _normalizeTitle(String value) {
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

  IconData _resolveIcon(String title) {
    final normalized = _normalizeTitle(title);

    if (normalized.contains('tam_ung_luong')) {
      return Icons.payments_outlined;
    }
    if (normalized.contains('tam_ung') || normalized.contains('hoan_ung')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (normalized.contains('khen_thuong')) {
      return Icons.emoji_events_outlined;
    }
    if (normalized.contains('muon')) {
      return Icons.handshake_outlined;
    }
    if (normalized.contains('cong_tac') || normalized.contains('ra_ngoai')) {
      return Icons.work_outline_rounded;
    }
    if (normalized.contains('thiet_bi')) {
      return Icons.phone_android_rounded;
    }
    if (normalized.contains('ky_luat')) {
      return Icons.thumb_down_alt_outlined;
    }
    if (normalized.contains('thay_doi_gio') || normalized.contains('vao_ra')) {
      return Icons.access_time_outlined;
    }
    if (normalized.contains('phieu_de_nghi')) {
      return Icons.description_outlined;
    }
    if (normalized.contains('suat_an')) {
      return Icons.restaurant_outlined;
    }
    if (normalized.contains('nghi_phep')) {
      return Icons.bed_outlined;
    }
    if (normalized.contains('lam_them_gio')) {
      return Icons.schedule_rounded;
    }
    if (normalized.contains('thanh_toan_chi_phi')) {
      return Icons.receipt_long_outlined;
    }
    if (normalized.contains('thanh_toan')) {
      return Icons.credit_card_outlined;
    }
    if (normalized.contains('mua_hang')) {
      return Icons.shopping_cart_outlined;
    }
    if (normalized.contains('nghi_viec')) {
      return Icons.power_settings_new_rounded;
    }
    if (normalized.contains('dang_ky_ca')) {
      return Icons.calendar_month_outlined;
    }
    if (normalized.contains('doi_ca')) {
      return Icons.swap_horiz_rounded;
    }
    if (normalized.contains('di_muon') || normalized.contains('ve_som')) {
      return Icons.login_rounded;
    }
    if (normalized.contains('di_som') || normalized.contains('ve_muon')) {
      return Icons.logout_rounded;
    }

    return Icons.list_alt_outlined;
  }
}

class _RequestTypeTile extends StatelessWidget {
  const _RequestTypeTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: const Color(0xFF344164),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2F3D5A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
