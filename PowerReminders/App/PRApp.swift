import SwiftUI
import PRModels
import PRSync

@main
struct PRApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @AppStorage("appearance") private var appearance = 0 // 0: System, 1: Light, 2: Dark

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(subscriptionViewModel)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @ObservedObject private var syncEngine = SyncEngine.shared
    @ObservedObject private var notificationManager = InAppNotificationManager.shared
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    // Pending notification actions (stored until reminders are loaded)
    @State private var pendingOpenReminderID: UUID?
    @State private var pendingSnoozeReminderID: UUID?

    var body: some View {
        // Main app content
        Group {
            if !onboardingCompleted {
                // Existing authenticated user who never started onboarding (app upgrade) → skip
                if authViewModel.isAuthenticated
                    && UserDefaults.standard.integer(forKey: "onboarding_current_step") == OnboardingStep.welcome.rawValue {
                    Color.clear
                        .onAppear { onboardingCompleted = true }
                } else {
                    OnboardingContainerView()
                }
            } else if authViewModel.isAuthenticated {
                NewHomeView()
            } else {
                WelcomeView()
            }
        }
        .animation(.iOSTransition, value: authViewModel.isAuthenticated)
        // Handle tap on notification → show in-app banner
        .onReceive(NotificationCenter.default.publisher(for: .openReminderDetail)) { notification in
            handleOpenReminderDetail(notification)
        }
        // Handle custom snooze action from notification
        .onReceive(NotificationCenter.default.publisher(for: .showCustomSnooze)) { notification in
            handleShowCustomSnooze(notification)
        }
        // When reminders change, check for pending actions and clean up stale notifications
        .onChange(of: syncEngine.reminders) { _, newReminders in
            processPendingActions(reminders: newReminders)

            // Clean up stale notifications (e.g., when app was terminated and
            // cross-device silent push wasn't delivered)
            Task {
                let activeIDs = Set(newReminders.filter { $0.status == .active || $0.status == .snoozed }.map { $0.id })
                await NotificationService.shared.cleanupStaleNotifications(activeReminderIDs: activeIDs)
            }
        }
        // Schedule local notifications for exact timing (server push is backup)
        .onAppear {
            setupLocalNotificationScheduling()
        }
    }

    private func setupLocalNotificationScheduling() {
        // Schedule local notification when reminder is created
        SyncEngine.shared.onReminderCreated = { reminder in
            Task {
                await NotificationService.shared.scheduleNotification(for: reminder)
            }
        }

        // Reschedule local notification when reminder is updated
        SyncEngine.shared.onReminderUpdated = { reminder in
            Task {
                // Cancel old notification first
                NotificationService.shared.cancelNotification(for: reminder.id)
                // Only reschedule if reminder is still active or snoozed
                if reminder.status == .active || reminder.status == .snoozed {
                    await NotificationService.shared.scheduleNotification(for: reminder)
                }
            }
        }
    }

    private func handleOpenReminderDetail(_ notification: Notification) {
        guard let reminderID = notification.userInfo?["reminder_id"] as? UUID else { return }
        // Show in-app banner instead of opening edit page
        if let reminder = syncEngine.reminders.first(where: { $0.id == reminderID }) {
            showBannerForReminder(reminder)
        } else {
            // Store pending action - will be processed when reminders load
            pendingOpenReminderID = reminderID
        }
    }

    private func handleShowCustomSnooze(_ notification: Notification) {
        guard let reminderID = notification.userInfo?["reminder_id"] as? UUID else { return }
        if let reminder = syncEngine.reminders.first(where: { $0.id == reminderID }) {
            showBannerForReminder(reminder, snoozeExpanded: true)
        } else {
            // Store pending action - will be processed when reminders load
            pendingSnoozeReminderID = reminderID
        }
    }

    private func processPendingActions(reminders: [PRModels.Reminder]) {
        // Process pending open reminder action — show banner
        if let pendingID = pendingOpenReminderID,
           let reminder = reminders.first(where: { $0.id == pendingID }) {
            pendingOpenReminderID = nil
            showBannerForReminder(reminder)
        }

        // Process pending snooze action — show banner with snooze expanded
        if let pendingID = pendingSnoozeReminderID,
           let reminder = reminders.first(where: { $0.id == pendingID }) {
            pendingSnoozeReminderID = nil
            showBannerForReminder(reminder, snoozeExpanded: true)
        }
    }

    private func showBannerForReminder(_ reminder: PRModels.Reminder, snoozeExpanded: Bool = false) {
        InAppNotificationManager.shared.show(
            title: reminder.title,
            subtitle: reminder.notes ?? "",
            reminderID: reminder.id,
            dueAt: reminder.dueAt,
            soundID: reminder.soundId,
            isAlarm: reminder.isAlarm,
            snoozeExpanded: snoozeExpanded
        )
    }
}
