import AppIntents
import PRNetworking
import PRSync
import PRModels

/// App Intent that marks a reminder as completed in Power Reminders.
///
/// Users can pick from their active reminders via the entity query,
/// then complete them through Siri or Shortcuts.
struct CompleteReminderIntent: AppIntent {

    static var title: LocalizedStringResource = "Complete Reminder"

    static var description = IntentDescription(
        "Marks a reminder as completed in Power Reminders.",
        categoryName: "Reminders"
    )

    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "Reminder", description: "The reminder to complete.")
    var target: ReminderEntity

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let graphQL = GraphQLClient.shared

        let mutation = PRAPI.CompleteReminderMutation(id: target.id.uuidString.lowercased())
        _ = try await graphQL.perform(mutation: mutation)

        SyncEngine.shared.refetch()

        return .result(
            dialog: "Completed reminder \"\(target.title)\"."
        )
    }
}

/// App Intent that snoozes a reminder for a specified number of minutes.
struct SnoozeReminderIntent: AppIntent {

    static var title: LocalizedStringResource = "Snooze Reminder"

    static var description = IntentDescription(
        "Snoozes a reminder for a specified duration in Power Reminders.",
        categoryName: "Reminders"
    )

    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "Reminder", description: "The reminder to snooze.")
    var target: ReminderEntity

    @Parameter(
        title: "Duration",
        description: "How long to snooze the reminder.",
        default: .fifteenMinutes
    )
    var duration: SnoozeDurationAppEnum

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let graphQL = GraphQLClient.shared

        let mutation = PRAPI.SnoozeReminderMutation(
            id: target.id.uuidString.lowercased(),
            minutes: duration.minutes
        )
        _ = try await graphQL.perform(mutation: mutation)

        SyncEngine.shared.refetch()

        return .result(
            dialog: "Snoozed \"\(target.title)\" for \(duration.displayLabel)."
        )
    }
}

// MARK: - Snooze Duration Enum

/// Predefined snooze durations available in Shortcuts and Siri.
enum SnoozeDurationAppEnum: String, AppEnum {

    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case tomorrow

    /// The number of minutes corresponding to each duration.
    var minutes: Int {
        switch self {
        case .fiveMinutes: 5
        case .fifteenMinutes: 15
        case .thirtyMinutes: 30
        case .oneHour: 60
        case .twoHours: 120
        case .tomorrow: 1440
        }
    }

    /// A human-readable label for the duration.
    var displayLabel: String {
        switch self {
        case .fiveMinutes: "5 minutes"
        case .fifteenMinutes: "15 minutes"
        case .thirtyMinutes: "30 minutes"
        case .oneHour: "1 hour"
        case .twoHours: "2 hours"
        case .tomorrow: "tomorrow"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Snooze Duration"
    }

    static var caseDisplayRepresentations: [SnoozeDurationAppEnum: DisplayRepresentation] {
        [
            .fiveMinutes: "5 Minutes",
            .fifteenMinutes: "15 Minutes",
            .thirtyMinutes: "30 Minutes",
            .oneHour: "1 Hour",
            .twoHours: "2 Hours",
            .tomorrow: "Tomorrow"
        ]
    }
}
