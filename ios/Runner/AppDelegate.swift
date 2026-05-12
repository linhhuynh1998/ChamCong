import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("[FCM][iOS] didFinishLaunchingWithOptions")

    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self

    // Always register for remote notifications on launch.
    // Permission prompt is requested in Dart (FirebaseMessaging.requestPermission).
    DispatchQueue.main.async {
      UIApplication.shared.registerForRemoteNotifications()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("[FCM][iOS] didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken as NSData)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[FCM][iOS] Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
