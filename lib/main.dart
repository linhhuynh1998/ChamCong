import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'services/firebase_messaging_service.dart';

import 'core/routes/app_navigator.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'views/account/account_page.dart';
import 'views/account/app_info_page.dart';
import 'views/account/company_switch_page.dart';
import 'views/account/company_directory_list_page.dart';
import 'views/account/company_settings_page.dart';
import 'views/account/employee_list_page.dart';
import 'views/account/management_settings_page.dart';
import 'views/account/notifications_page.dart';
import 'views/account/notification_settings_page.dart';
import 'views/account/region_settings_page.dart';
import 'views/account/security_center_page.dart';
import 'views/account/shift_list_page.dart';
import 'views/account/language_settings_page.dart';
import 'views/home/attendance_home_page.dart';
import 'views/home/request_management_page.dart';
import 'views/home/work_dashboard_page.dart';
import 'views/login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint('[Main] Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('[Main] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[Main] Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      debugPrint('[FCM] Initializing Firebase Messaging...');
      final fcmService = FirebaseMessagingService();
      await fcmService.initialize(
        onNotificationTap: (data) {
          debugPrint('[FCM Handler] Notification tapped: $data');
          _handleNotificationTap(data);
        },
      );
      debugPrint('[FCM] Firebase Messaging initialized');
    } catch (e) {
      debugPrint('[FCM] Error initializing Firebase Messaging: $e');
    }
  }

  /// Handle notification tap based on notification type
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    debugPrint('[FCM Handler] Processing notification type: $type');

    switch (type) {
      case 'request_status_update':
        _handleRequestStatusNotification(data);
        break;
      case 'new_request':
        _handleNewRequestNotification(data);
        break;
      default:
        // Default: open notifications page
        final navigator = AppNavigator.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamed(AppRoutes.notifications);
        }
    }
  }

  /// Handle request status update notification (approval/rejection)
  void _handleRequestStatusNotification(Map<String, dynamic> data) {
    final requestId = data['request_id']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';

    debugPrint('[FCM Handler] Request status update - ID: $requestId, Status: $status');

    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator != null) {
      // Navigate to request management page to view request status
      navigator.pushNamed(AppRoutes.requestManagement);
    }
  }

  /// Handle new request notification (for managers)
  void _handleNewRequestNotification(Map<String, dynamic> data) {
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

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
        AppRoutes.requestManagement: (_) => const RequestManagementPage(),
        AppRoutes.account: (_) => const AccountPage(),
        AppRoutes.managementSettings: (_) => const ManagementSettingsPage(),
        AppRoutes.companySettings: (_) => const CompanySettingsPage(),
        AppRoutes.employeeSettings: (_) => const EmployeeListPage(),
        AppRoutes.shiftSettings: (_) => const ShiftListPage(),
        AppRoutes.languageSettings: (_) => const LanguageSettingsPage(),
        AppRoutes.notifications: (_) => const NotificationsPage(),
        AppRoutes.notificationSettings: (_) => const NotificationSettingsPage(),
        AppRoutes.companySwitch: (_) => const CompanySwitchPage(),
        AppRoutes.appInfo: (_) => const AppInfoPage(),
        AppRoutes.securityCenter: (_) => const SecurityCenterPage(),
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
