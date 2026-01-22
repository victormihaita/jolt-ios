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

        // Note: We no longer request notification permissions here.
        // Permissions are requested when the user creates their first reminder
        // for a better user experience.

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Re-check notification permissions when app becomes active
        // This handles the case where user enabled notifications in iOS Settings
        print("📱 AppDelegate: applicationDidBecomeActive - checking notification permissions")
        Task {
            let status = await NotificationService.shared.getNotificationStatus()
            print("📱 AppDelegate: Current notification status = \(status)")
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
        }
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

        #if targetEnvironment(simulator)
        // Simulator cannot receive real push tokens - use a mock token for testing
        print("📱 Running on simulator - using mock push token for device registration")
        let mockToken = "simulator-mock-token-\(UUID().uuidString)"
        Task {
            await DeviceService.shared.registerPushToken(mockToken)
        }
        #endif
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

            // Stop alarm if playing (thread-safe)
            AlarmManager.shared.stopAlarm()

            // Post notification to update UI on main thread
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
