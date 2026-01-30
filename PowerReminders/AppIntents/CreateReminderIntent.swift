import AppIntents
import PRNetworking
import PRSync
import PRModels

/// App Intent that creates a new reminder in Zalt via the GraphQL API.
///
/// Supports Siri phrases like "Create a reminder in Zalt" and
/// can be added to Shortcuts for automation workflows.
struct CreateReminderIntent: AppIntent {

    static var title: LocalizedStringResource = "Create Reminder"

    static var description = IntentDescription(
        "Creates a new reminder in Zalt.",
        categoryName: "Reminders"
    )

    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "Title", description: "The title of the reminder.")
    var reminderTitle: String

    @Parameter(title: "Notes", description: "Optional notes for the reminder.")
    var notes: String?

    @Parameter(
        title: "Due Date",
        description: "When the reminder is due. Leave empty for no due date."
    )
    var dueDate: Date?

    @Parameter(
        title: "Priority",
        description: "The priority level of the reminder.",
        default: .normal
    )
    var priority: ReminderPriorityAppEnum

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let graphQL = GraphQLClient.shared

        let dueAtString: GraphQLNullable<String> = if let dueDate {
            .some(ISO8601DateFormatter().string(from: dueDate))
        } else {
            .null
        }

        let graphQLPriority: PRAPI.Priority = switch priority {
        case .none: .none
        case .low: .low
        case .normal: .normal
        case .high: .high
        }

        let input = PRAPI.CreateReminderInput(
            title: reminderTitle,
            notes: notes.map { .some($0) } ?? .null,
            priority: .some(.init(graphQLPriority)),
            dueAt: dueAtString
        )

        let mutation = PRAPI.CreateReminderMutation(input: input)
        _ = try await graphQL.perform(mutation: mutation)

        // Trigger SyncEngine to refetch so the UI updates immediately
        SyncEngine.shared.refetch()

        let confirmationMessage: String
        if let dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            confirmationMessage = "Created reminder \"\(reminderTitle)\" due \(formatter.string(from: dueDate))."
        } else {
            confirmationMessage = "Created reminder \"\(reminderTitle)\"."
        }

        return .result(dialog: IntentDialog(stringLiteral: confirmationMessage))
    }
}

// MARK: - Priority App Enum

/// Maps Zalt priority levels to an AppIntents-compatible enum.
enum ReminderPriorityAppEnum: String, AppEnum {

    case none
    case low
    case normal
    case high

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Priority"
    }

    static var caseDisplayRepresentations: [ReminderPriorityAppEnum: DisplayRepresentation] {
        [
            .none: "None",
            .low: "Low",
            .normal: "Normal",
            .high: "High"
        ]
    }
}
