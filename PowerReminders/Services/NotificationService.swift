import UserNotifications
import UIKit
import PRNetworking
import PRModels

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Get the current notification authorization status
    func getNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Request authorization if not yet determined
    /// Call this when creating the first reminder
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await getNotificationStatus()

        print("🔔 NotificationService: Current status = \(status.rawValue)")

        switch status {
        case .authorized:
            // Already authorized - ensure we're registered for remote notifications
            print("🔔 NotificationService: Already authorized, registering for remote notifications")
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return true

        case .provisional:
            // Provisional authorization - upgrade to full authorization
            print("🔔 NotificationService: Provisional, requesting full authorization")
            return await requestAuthorization()

        case .denied:
            // User explicitly denied - don't prompt again
            print("🔔 NotificationService: Denied by user")
            return false

        case .notDetermined:
            // Haven't asked yet - show the prompt
            print("🔔 NotificationService: Not determined, requesting authorization")
            return await requestAuthorization()

        case .ephemeral:
            print("🔔 NotificationService: Ephemeral authorization")
            return true

        @unknown default:
            print("🔔 NotificationService: Unknown status")
            return false
        }
    }

    /// Re-register for remote notifications if authorized
    /// Call this when app becomes active (user may have enabled in Settings)
    func registerForRemoteNotificationsIfAuthorized() async {
        let status = await getNotificationStatus()
        if status == .authorized || status == .provisional {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            print("🔔 NotificationService: Requesting authorization with alert, sound, badge")
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Categories

    func registerCategories() {
        // Snooze actions
        let snooze5 = UNNotificationAction(
            identifier: "SNOOZE_5",
            title: "5 min",
            options: []
        )

        let snooze15 = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "15 min",
            options: []
        )

        let snooze30 = UNNotificationAction(
            identifier: "SNOOZE_30",
            title: "30 min",
            options: []
        )

        let snoozeCustom = UNNotificationAction(
            identifier: "SNOOZE_CUSTOM",
            title: "Custom...",
            options: [.foreground]
        )

        let complete = UNNotificationAction(
            identifier: "COMPLETE",
            title: "Done",
            options: []
        )

        let dismiss = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )

        let stopAlarm = UNNotificationAction(
            identifier: "STOP_ALARM",
            title: "Stop",
            options: []
        )

        // Main reminder category with all actions
        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER_ACTIONS",
            actions: [snooze5, snooze15, snoozeCustom, complete, dismiss],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Quick snooze category (for watch/widget)
        let quickSnoozeCategory = UNNotificationCategory(
            identifier: "QUICK_SNOOZE",
            actions: [snooze5, snooze15, snooze30, complete],
            intentIdentifiers: [],
            options: []
        )

        // Alarm category with stop action - uses Critical Alert to bypass DND
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_ACTIONS",
            actions: [stopAlarm, snooze5, snooze15, complete],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            reminderCategory,
            quickSnoozeCategory,
            alarmCategory
        ])
    }

    // MARK: - Schedule Notifications

    func scheduleNotification(for reminder: PRModels.Reminder) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.isAlarm ? "Alarm" : "Reminder"
        content.body = reminder.title
        content.userInfo = [
            "reminder_id": reminder.id.uuidString,
            "due_at": reminder.dueAt.ISO8601Format(),
            "is_alarm": reminder.isAlarm
        ]

        // Add notes as subtitle if present
        if let notes = reminder.notes, !notes.isEmpty {
            content.subtitle = notes
        }

        // Set thread identifier for grouping
        content.threadIdentifier = "reminders"

        // Configure based on alarm vs regular reminder
        if reminder.isAlarm {
            // Alarm-style notification with Critical Alert (bypasses DND)
            content.categoryIdentifier = "ALARM_ACTIONS"
            // Use critical sound (requires Critical Alert entitlement)
            content.sound = UNNotificationSound.criticalSoundNamed(
                UNNotificationSoundName("alarm_default.m4a"),
                withAudioVolume: 1.0
            )
            content.interruptionLevel = .critical
        } else {
            // Regular reminder notification
            content.categoryIdentifier = "REMINDER_ACTIONS"
            content.sound = .default
        }

        // Create trigger
        let triggerDate = reminder.effectiveDueDate
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled \(reminder.isAlarm ? "alarm" : "notification") for reminder: \(reminder.id)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func cancelNotification(for reminderID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderID.uuidString]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [reminderID.uuidString]
        )
    }

    func rescheduleNotification(for reminder: PRModels.Reminder, snoozedUntil: Date) async {
        // Cancel existing
        cancelNotification(for: reminder.id)

        // Create new content
        let content = UNMutableNotificationContent()
        content.title = "Reminder (Snoozed)"
        content.body = reminder.title
        content.sound = .default
        content.categoryIdentifier = "REMINDER_ACTIONS"
        content.userInfo = [
            "reminder_id": reminder.id.uuidString,
            "snoozed": true
        ]

        // Create trigger for snooze time
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: snoozedUntil
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Rescheduled notification for: \(snoozedUntil)")
        } catch {
            print("Failed to reschedule notification: \(error)")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        // Check if this is an alarm notification
        if let isAlarm = userInfo["is_alarm"] as? Bool, isAlarm,
           let reminderIDString = userInfo["reminder_id"] as? String,
           let reminderID = UUID(uuidString: reminderIDString) {
            // Start alarm sound/vibration
            await MainActor.run {
                AlarmManager.shared.startAlarm(for: reminderID)
            }
        }

        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard let reminderIDString = userInfo["reminder_id"] as? String,
              let reminderID = UUID(uuidString: reminderIDString) else {
            return
        }

        switch response.actionIdentifier {
        case "SNOOZE_5":
            AlarmManager.shared.stopAlarm()
            await handleSnooze(reminderID: reminderID, minutes: 5)

        case "SNOOZE_15":
            AlarmManager.shared.stopAlarm()
            await handleSnooze(reminderID: reminderID, minutes: 15)

        case "SNOOZE_30":
            AlarmManager.shared.stopAlarm()
            await handleSnooze(reminderID: reminderID, minutes: 30)

        case "SNOOZE_CUSTOM":
            AlarmManager.shared.stopAlarm()
            // Open app to custom snooze picker
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .showCustomSnooze,
                    object: nil,
                    userInfo: ["reminder_id": reminderID]
                )
            }

        case "COMPLETE":
            AlarmManager.shared.stopAlarm()
            await handleComplete(reminderID: reminderID)

        case "DISMISS":
            AlarmManager.shared.stopAlarm()
            await handleDismiss(reminderID: reminderID)

        case "STOP_ALARM":
            AlarmManager.shared.stopAlarm()
            await handleDismiss(reminderID: reminderID)

        case UNNotificationDefaultActionIdentifier:
            AlarmManager.shared.stopAlarm()
            // User tapped the notification - open app to reminder detail
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .openReminderDetail,
                    object: nil,
                    userInfo: ["reminder_id": reminderID]
                )
            }

        default:
            break
        }
    }

    // MARK: - Action Handlers

    private func handleSnooze(reminderID: UUID, minutes: Int) async {
        let mutation = PRAPI.SnoozeReminderMutation(id: reminderID.uuidString, minutes: minutes)

        do {
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            print("Snoozed reminder \(reminderID) for \(minutes) minutes")

            // Update local database
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .reminderSnoozed,
                    object: nil,
                    userInfo: ["reminder_id": reminderID, "minutes": minutes]
                )
            }

            Haptics.success()
        } catch {
            print("Failed to snooze reminder: \(error)")
            Haptics.error()
        }
    }

    private func handleComplete(reminderID: UUID) async {
        let mutation = PRAPI.CompleteReminderMutation(id: reminderID.uuidString)

        do {
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            print("Completed reminder \(reminderID)")

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .reminderCompleted,
                    object: nil,
                    userInfo: ["reminder_id": reminderID]
                )
            }

            Haptics.success()
        } catch {
            print("Failed to complete reminder: \(error)")
            Haptics.error()
        }
    }

    private func handleDismiss(reminderID: UUID) async {
        let mutation = PRAPI.DismissReminderMutation(id: reminderID.uuidString)

        do {
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            print("Dismissed reminder \(reminderID)")

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .reminderDismissed,
                    object: nil,
                    userInfo: ["reminder_id": reminderID]
                )
            }

            Haptics.medium()
        } catch {
            print("Failed to dismiss reminder: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showCustomSnooze = Notification.Name("showCustomSnooze")
    static let openReminderDetail = Notification.Name("openReminderDetail")
    static let reminderSnoozed = Notification.Name("reminderSnoozed")
    static let reminderCompleted = Notification.Name("reminderCompleted")
    static let reminderDismissed = Notification.Name("reminderDismissed")
    static let crossDeviceActionReceived = Notification.Name("crossDeviceActionReceived")
}
