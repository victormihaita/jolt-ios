import AppIntents

/// Provides pre-built App Shortcuts that appear in the Shortcuts app
/// and can be invoked via Siri with natural language phrases.
struct PowerRemindersShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateReminderIntent(),
            phrases: [
                "Create a reminder in \(.applicationName)",
                "Add a reminder to \(.applicationName)",
                "Remind me in \(.applicationName)",
                "New reminder in \(.applicationName)"
            ],
            shortTitle: "Create Reminder",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: ListRemindersIntent(),
            phrases: [
                "Show my reminders in \(.applicationName)",
                "What are my reminders in \(.applicationName)",
                "List reminders in \(.applicationName)",
                "What's coming up in \(.applicationName)"
            ],
            shortTitle: "My Reminders",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: CompleteReminderIntent(),
            phrases: [
                "Complete a reminder in \(.applicationName)",
                "Mark reminder done in \(.applicationName)",
                "Finish a reminder in \(.applicationName)"
            ],
            shortTitle: "Complete Reminder",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: SnoozeReminderIntent(),
            phrases: [
                "Snooze a reminder in \(.applicationName)",
                "Snooze reminder in \(.applicationName)",
                "Delay a reminder in \(.applicationName)"
            ],
            shortTitle: "Snooze Reminder",
            systemImageName: "clock.badge.questionmark"
        )
    }
}
