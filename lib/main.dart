import 'package:flutter/material.dart';

import 'core/routes/app_navigator.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'views/account/account_page.dart';
import 'views/account/company_directory_list_page.dart';
import 'views/account/company_settings_page.dart';
import 'views/account/employee_list_page.dart';
import 'views/account/management_settings_page.dart';
import 'views/account/region_settings_page.dart';
import 'views/home/attendance_home_page.dart';
import 'views/home/work_dashboard_page.dart';
import 'views/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'B2MSR',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) => const WorkDashboardPage(),
        AppRoutes.attendance: (_) => const AttendanceHomePage(),
        AppRoutes.account: (_) => const AccountPage(),
        AppRoutes.managementSettings: (_) => const ManagementSettingsPage(),
        AppRoutes.companySettings: (_) => const CompanySettingsPage(),
        AppRoutes.employeeSettings: (_) => const EmployeeListPage(),
        AppRoutes.regionSettings: (_) => const RegionSettingsPage(),
        AppRoutes.branchSettings: (_) => const CompanyDirectoryListPage(
              title: 'Chi nhánh',
              endpoint: '/company/branches',
              requiresRegionId: true,
            ),
        AppRoutes.departmentSettings: (_) => const CompanyDirectoryListPage(
              title: 'Phòng ban',
              endpoint: '/company/departments',
            ),
        AppRoutes.jobTitleSettings: (_) => const CompanyDirectoryListPage(
              title: 'Chức vụ',
              endpoint: '/company/job-titles',
            ),
      },
    );
  }
}
