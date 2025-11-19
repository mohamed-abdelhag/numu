import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure notification categories for reminders
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let dismissAction = UNNotificationAction(
        identifier: "DISMISS_ACTION",
        title: "Dismiss",
        options: []
      )
      
      let reminderCategory = UNNotificationCategory(
        identifier: "REMINDER_CATEGORY",
        actions: [dismissAction],
        intentIdentifiers: [],
        options: .customDismissAction
      )
      
      UNUserNotificationCenter.current().setNotificationCategories([reminderCategory])
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle notification responses
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Handle notification tap - Flutter plugin will handle navigation
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      // User tapped the notification
      // The flutter_local_notifications plugin will handle this
    } else if response.actionIdentifier == "DISMISS_ACTION" {
      // User dismissed the notification
    }
    
    completionHandler()
  }
  
  // Handle notification presentation while app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
