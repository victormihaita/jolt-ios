import AppIntents
import WidgetKit
import PRCore
import PRNetworking

/// App intent that marks a reminder as complete from the widget.
/// Calls the GraphQL CompleteReminderMutation and updates local widget data.
struct CompleteReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Reminder"
    static var description = IntentDescription("Marks a reminder as complete")

    @Parameter(title: "Reminder ID")
    var reminderID: String

    init() {}

    init(reminderID: String) {
        self.reminderID = reminderID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: reminderID) else { return .result() }

        // Call GraphQL mutation to complete the reminder on the server
        // PRAPI.UUID is a String typealias, so pass the string directly
        let mutation = PRAPI.CompleteReminderMutation(id: reminderID.lowercased())
        _ = try? await GraphQLClient.shared.perform(mutation: mutation)

        // Update widget data locally by removing the completed reminder
        var reminders = WidgetDataService.shared.loadReminders()
        reminders.removeAll { $0.id == uuid }
        WidgetDataService.shared.updateWidget(with: reminders)

        return .result()
    }
}
