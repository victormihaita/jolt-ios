import AppIntents
import PRModels
import PRSync

/// An AppIntents entity that represents a Power Reminders reminder.
///
/// This entity bridges the `PRModels.Reminder` type into the App Intents
/// framework so that Siri and Shortcuts can present reminders as selectable
/// options in intent parameters.
struct ReminderEntity: AppEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder"

    static var defaultQuery = ReminderEntityQuery()

    /// The unique identifier of the reminder.
    var id: UUID

    /// The reminder title displayed to the user.
    var title: String

    /// Optional notes attached to the reminder.
    var notes: String?

    /// The due date of the reminder, if any.
    var dueAt: Date?

    /// The priority level of the reminder.
    var priority: String

    /// The current status of the reminder (active, completed, snoozed, dismissed).
    var status: String

    var displayRepresentation: DisplayRepresentation {
        var subtitle: String?
        if let dueAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            subtitle = formatter.string(from: dueAt)
        }
        return DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: title),
            subtitle: subtitle.map { LocalizedStringResource(stringLiteral: $0) }
        )
    }

    /// Creates a `ReminderEntity` from a `PRModels.Reminder`.
    init(from reminder: PRModels.Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.notes = reminder.notes
        self.dueAt = reminder.dueAt
        self.priority = reminder.priority.displayName
        self.status = reminder.status.rawValue
    }

    init(
        id: UUID,
        title: String,
        notes: String? = nil,
        dueAt: Date? = nil,
        priority: String = "Normal",
        status: String = "ACTIVE"
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueAt = dueAt
        self.priority = priority
        self.status = status
    }
}

// MARK: - Entity Query

/// Queries active reminders from the SyncEngine for use in App Intents parameter resolution.
struct ReminderEntityQuery: EntityQuery {

    func entities(for identifiers: [UUID]) async throws -> [ReminderEntity] {
        let allReminders = await MainActor.run {
            SyncEngine.shared.reminders
        }
        return allReminders
            .filter { identifiers.contains($0.id) }
            .map { ReminderEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [ReminderEntity] {
        let allReminders = await MainActor.run {
            SyncEngine.shared.reminders
        }
        // Return active reminders sorted by due date, limited to 20
        return allReminders
            .filter { $0.status == .active || $0.status == .snoozed }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
            .prefix(20)
            .map { ReminderEntity(from: $0) }
    }
}

// MARK: - String Search Support

extension ReminderEntityQuery: EntityStringQuery {

    func entities(matching string: String) async throws -> [ReminderEntity] {
        let allReminders = await MainActor.run {
            SyncEngine.shared.reminders
        }
        let lowercased = string.lowercased()
        return allReminders
            .filter {
                $0.title.lowercased().contains(lowercased) ||
                ($0.notes?.lowercased().contains(lowercased) ?? false)
            }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
            .prefix(20)
            .map { ReminderEntity(from: $0) }
    }
}
