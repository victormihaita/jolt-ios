import Foundation
import UserNotifications
import JoltCore
import JoltModels

public final class NotificationService: NSObject, ObservableObject {
    public static let shared = NotificationService()

    @Published public private(set) var isAuthorized = false

    public var onSnoozeRequested: ((UUID, Int) -> Void)?
    public var onCompleteRequested: ((UUID) -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Authorization

    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: options)

            await MainActor.run {
                isAuthorized = granted
            }

            if granted {
                await registerNotificationCategories()
            }

            return granted
        } catch {
            JoltLogger.error("Failed to request notification authorization: \(error)", category: .notifications)
            return false
        }
    }

    public func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Notification Categories

    private func registerNotificationCategories() async {
        let snooze5Action = UNNotificationAction(
            identifier: JoltConstants.Notifications.actionSnooze5,
            title: "5 min",
            options: []
        )

        let snooze15Action = UNNotificationAction(
            identifier: JoltConstants.Notifications.actionSnooze15,
            title: "15 min",
            options: []
        )

        let customSnoozeAction = UNNotificationAction(
            identifier: JoltConstants.Notifications.actionSnoozeCustom,
            title: "Custom",
            options: [.foreground]
        )

        let completeAction = UNNotificationAction(
            identifier: JoltConstants.Notifications.actionComplete,
            title: "Done",
            options: [.destructive]
        )

        let reminderCategory = UNNotificationCategory(
            identifier: JoltConstants.Notifications.categoryReminder,
            actions: [snooze5Action, snooze15Action, customSnoozeAction, completeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([reminderCategory])
    }

    // MARK: - Schedule Notifications

    public func scheduleNotification(for reminder: Reminder) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes {
            content.body = notes
        }
        content.sound = .default
        content.categoryIdentifier = JoltConstants.Notifications.categoryReminder
        content.userInfo = ["reminderId": reminder.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.dueAt
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            JoltLogger.debug("Scheduled notification for reminder: \(reminder.id)", category: .notifications)
        } catch {
            JoltLogger.error("Failed to schedule notification: \(error)", category: .notifications)
        }
    }

    public func cancelNotification(for reminderId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderId.uuidString]
        )
    }

    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let reminderIdString = userInfo["reminderId"] as? String,
              let reminderId = UUID(uuidString: reminderIdString) else {
            return
        }

        switch response.actionIdentifier {
        case JoltConstants.Notifications.actionSnooze5:
            onSnoozeRequested?(reminderId, 5)
        case JoltConstants.Notifications.actionSnooze15:
            onSnoozeRequested?(reminderId, 15)
        case JoltConstants.Notifications.actionComplete:
            onCompleteRequested?(reminderId)
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - open app to reminder
            break
        default:
            break
        }
    }
}
