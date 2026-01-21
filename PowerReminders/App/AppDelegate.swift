import UIKit
import UserNotifications
import GoogleSignIn
import PRSync

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure RevenueCat for in-app purchases
        RevenueCatService.shared.configure()

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // Register notification categories for actionable notifications
        NotificationService.shared.registerCategories()

        // Request notification permissions
        Task {
            await NotificationService.shared.requestAuthorization()
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In callback
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNs Device Token: \(tokenString)")

        // Register token with backend
        Task {
            await DeviceService.shared.registerPushToken(tokenString)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle background notification
        guard let type = userInfo["type"] as? String else {
            completionHandler(.noData)
            return
        }

        switch type {
        case "sync":
            // Silent sync notification
            Task {
                await SyncEngine.shared.performSync()
                completionHandler(.newData)
            }

        case "cross_device_action":
            // Handle cross-device action (snooze/complete/dismiss from another device)
            handleCrossDeviceAction(userInfo: userInfo, completionHandler: completionHandler)

        default:
            completionHandler(.noData)
        }
    }

    // MARK: - Cross-Device Action Handling

    private func handleCrossDeviceAction(
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let action = userInfo["action"] as? String,
              let reminderIDString = userInfo["reminder_id"] as? String,
              let reminderID = UUID(uuidString: reminderIDString) else {
            completionHandler(.noData)
            return
        }

        print("📱 Cross-device action received: \(action) for reminder \(reminderID)")

        switch action {
        case "snooze", "complete", "dismiss", "delete":
            // Remove notification from notification center
            NotificationService.shared.cancelNotification(for: reminderID)

            // Stop alarm if playing
            AlarmManager.shared.stopAlarm()

            // Post notification to update UI
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .crossDeviceActionReceived,
                    object: nil,
                    userInfo: [
                        "action": action,
                        "reminder_id": reminderID
                    ]
                )
            }

            // Sync to get latest data
            Task {
                await SyncEngine.shared.performSync()
                completionHandler(.newData)
            }

        default:
            completionHandler(.noData)
        }
    }
}
