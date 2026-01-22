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

    // State for notification-triggered navigation
    @State private var notificationReminder: PRModels.Reminder?
    @State private var showCustomSnoozeForReminder: PRModels.Reminder?

    // Pending notification actions (stored until reminders are loaded)
    @State private var pendingOpenReminderID: UUID?
    @State private var pendingSnoozeReminderID: UUID?

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                NewHomeView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        // Handle tap on notification → open reminder detail
        .onReceive(NotificationCenter.default.publisher(for: .openReminderDetail)) { notification in
            handleOpenReminderDetail(notification)
        }
        // Handle custom snooze action from notification
        .onReceive(NotificationCenter.default.publisher(for: .showCustomSnooze)) { notification in
            handleShowCustomSnooze(notification)
        }
        // When reminders change, check for pending actions
        .onChange(of: syncEngine.reminders) { _, newReminders in
            processPendingActions(reminders: newReminders)
        }
        // Present reminder detail when triggered by notification
        .fullScreenCover(item: $notificationReminder) { reminder in
            ReminderDetailView(reminder: reminder)
                .environmentObject(subscriptionViewModel)
        }
        // Present snooze picker when triggered by notification
        .sheet(item: $showCustomSnoozeForReminder) { reminder in
            NotificationSnoozePickerView(reminder: reminder)
                .environmentObject(subscriptionViewModel)
        }
    }

    private func handleOpenReminderDetail(_ notification: Notification) {
        guard let reminderID = notification.userInfo?["reminder_id"] as? UUID else { return }
        // Look up reminder from sync engine
        if let reminder = syncEngine.reminders.first(where: { $0.id == reminderID }) {
            notificationReminder = reminder
        } else {
            // Store pending action - will be processed when reminders load
            pendingOpenReminderID = reminderID
        }
    }

    private func handleShowCustomSnooze(_ notification: Notification) {
        guard let reminderID = notification.userInfo?["reminder_id"] as? UUID else { return }
        if let reminder = syncEngine.reminders.first(where: { $0.id == reminderID }) {
            showCustomSnoozeForReminder = reminder
        } else {
            // Store pending action - will be processed when reminders load
            pendingSnoozeReminderID = reminderID
        }
    }

    private func processPendingActions(reminders: [PRModels.Reminder]) {
        // Process pending open reminder action
        if let pendingID = pendingOpenReminderID,
           let reminder = reminders.first(where: { $0.id == pendingID }) {
            pendingOpenReminderID = nil
            notificationReminder = reminder
        }

        // Process pending snooze action
        if let pendingID = pendingSnoozeReminderID,
           let reminder = reminders.first(where: { $0.id == pendingID }) {
            pendingSnoozeReminderID = nil
            showCustomSnoozeForReminder = reminder
        }
    }
}
