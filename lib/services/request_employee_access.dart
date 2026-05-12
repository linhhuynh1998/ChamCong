import '../models/employee_profile.dart';

class RequestEmployeeAccess {
  const RequestEmployeeAccess._();

  static bool canSelectEmployee(EmployeeProfile? profile) {
    final role = profile?.role.trim().toLowerCase() ?? '';
    return const <String>{
      'admin',
      'administrator',
      'company',
      'company_admin',
      'owner',
      'manager',
      'super_admin',
      'superadmin',
      'hr',
      'quan ly',
      'quan_ly',
      'quản lý',
      'quản_lý',
    }.contains(role);
  }

  static String employeeName(EmployeeProfile profile) {
    return profile.name.trim().isEmpty ? 'Nhân viên' : profile.name;
  }
}
