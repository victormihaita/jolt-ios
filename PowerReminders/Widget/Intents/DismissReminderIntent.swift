import AppIntents
import WidgetKit
import PRCore
import PRNetworking

/// App intent that dismisses a reminder from the widget.
/// Calls the GraphQL DismissReminderMutation and removes the reminder from widget data.
struct DismissReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss Reminder"
    static var description = IntentDescription("Dismisses a reminder")

    @Parameter(title: "Reminder ID")
    var reminderID: String

    init() {}

    init(reminderID: String) {
        self.reminderID = reminderID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: reminderID) else { return .result() }

        // Call GraphQL mutation to dismiss the reminder on the server
        // PRAPI.UUID is a String typealias, so pass the string directly
        let mutation = PRAPI.DismissReminderMutation(id: reminderID.lowercased())
        _ = try? await GraphQLClient.shared.perform(mutation: mutation)

        // Update widget data locally by removing the dismissed reminder
        var reminders = WidgetDataService.shared.loadReminders()
        reminders.removeAll { $0.id == uuid }
        WidgetDataService.shared.updateWidget(with: reminders)

        return .result()
    }
}
