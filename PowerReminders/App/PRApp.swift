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
        }
    }

    private func handleShowCustomSnooze(_ notification: Notification) {
        guard let reminderID = notification.userInfo?["reminder_id"] as? UUID else { return }
        if let reminder = syncEngine.reminders.first(where: { $0.id == reminderID }) {
            showCustomSnoozeForReminder = reminder
        }
    }
}
