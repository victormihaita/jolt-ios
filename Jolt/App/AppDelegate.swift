import UIKit
import UserNotifications
import GoogleSignIn
import JoltSync

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
        if let _ = userInfo["type"] as? String {
            // Silent sync notification
            Task {
                await SyncEngine.shared.performSync()
                completionHandler(.newData)
            }
        } else {
            completionHandler(.noData)
        }
    }
}
