import AppIntents
import PRSync
import PRModels

/// App Intent that lists upcoming reminders from Zalt.
///
/// Returns active and snoozed reminders sorted by due date, presented
/// as a dialog message suitable for Siri voice output and Shortcuts display.
struct ListRemindersIntent: AppIntent {

    static var title: LocalizedStringResource = "List Reminders"

    static var description = IntentDescription(
        "Shows your upcoming reminders from Zalt.",
        categoryName: "Reminders"
    )

    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(
        title: "Filter",
        description: "Which reminders to show.",
        default: .upcoming
    )
    var filter: ReminderFilterAppEnum

    @Parameter(
        title: "Limit",
        description: "Maximum number of reminders to show.",
        default: 5
    )
    var limit: Int

    // MARK: - Perform

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reminders = await MainActor.run {
            SyncEngine.shared.reminders
        }

        let now = Date()
        let calendar = Calendar.current

        let filtered: [Reminder]
        switch filter {
        case .all:
            filtered = reminders
                .filter { $0.status == .active || $0.status == .snoozed }
                .sorted { $0.effectiveDueDate < $1.effectiveDueDate }

        case .today:
            filtered = reminders
                .filter { reminder in
                    guard reminder.status == .active || reminder.status == .snoozed else {
                        return false
                    }
                    guard let dueAt = reminder.dueAt else { return false }
                    return calendar.isDateInToday(dueAt)
                }
                .sorted { $0.effectiveDueDate < $1.effectiveDueDate }

        case .upcoming:
            filtered = reminders
                .filter { reminder in
                    guard reminder.status == .active || reminder.status == .snoozed else {
                        return false
                    }
                    return reminder.effectiveDueDate >= now
                }
                .sorted { $0.effectiveDueDate < $1.effectiveDueDate }

        case .overdue:
            filtered = reminders
                .filter { $0.isOverdue }
                .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
        }

        let capped = Array(filtered.prefix(limit))

        guard !capped.isEmpty else {
            return .result(dialog: "You have no \(filter.displayLabel) reminders.")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = []
        for reminder in capped {
            var line = "- \(reminder.title)"
            if let dueAt = reminder.dueAt {
                line += " (due \(formatter.string(from: dueAt)))"
            }
            if reminder.priority == .high {
                line += " [High Priority]"
            }
            lines.append(line)
        }

        let header: String
        if filtered.count > limit {
            header = "Here are your next \(capped.count) of \(filtered.count) \(filter.displayLabel) reminders:"
        } else {
            header = "You have \(capped.count) \(filter.displayLabel) reminder\(capped.count == 1 ? "" : "s"):"
        }

        let message = ([header] + lines).joined(separator: "\n")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Filter App Enum

/// Filter options for the List Reminders intent.
enum ReminderFilterAppEnum: String, AppEnum {

    case all
    case today
    case upcoming
    case overdue

    /// A human-readable label for the filter.
    var displayLabel: String {
        switch self {
        case .all: "active"
        case .today: "today's"
        case .upcoming: "upcoming"
        case .overdue: "overdue"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Reminder Filter"
    }

    static var caseDisplayRepresentations: [ReminderFilterAppEnum: DisplayRepresentation] {
        [
            .all: "All Active",
            .today: "Today",
            .upcoming: "Upcoming",
            .overdue: "Overdue"
        ]
    }
}
