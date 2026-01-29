import AppIntents
import WidgetKit
import PRCore
import PRNetworking

/// App intent that snoozes a reminder for 15 minutes from the widget.
/// Calls the GraphQL SnoozeReminderMutation and updates local widget data.
struct SnoozeReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Reminder"
    static var description = IntentDescription("Snoozes a reminder for 15 minutes")

    @Parameter(title: "Reminder ID")
    var reminderID: String

    /// Default snooze duration in minutes.
    private static let snoozeDurationMinutes = 15

    init() {}

    init(reminderID: String) {
        self.reminderID = reminderID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: reminderID) else { return .result() }

        // Call GraphQL mutation to snooze the reminder on the server
        // PRAPI.UUID is a String typealias, so pass the string directly
        let mutation = PRAPI.SnoozeReminderMutation(
            id: reminderID.lowercased(),
            minutes: Self.snoozeDurationMinutes
        )
        _ = try? await GraphQLClient.shared.perform(mutation: mutation)

        // Update widget data locally: push dueAt forward and clear overdue flag
        var reminders = WidgetDataService.shared.loadReminders()
        if let index = reminders.firstIndex(where: { $0.id == uuid }) {
            let existing = reminders[index]
            let newDueAt = Date().addingTimeInterval(
                TimeInterval(Self.snoozeDurationMinutes * 60)
            )
            reminders[index] = WidgetDataService.WidgetReminder(
                id: existing.id,
                title: existing.title,
                dueAt: newDueAt,
                priority: existing.priority,
                isOverdue: false
            )
        }
        WidgetDataService.shared.updateWidget(with: reminders)

        return .result()
    }
}
