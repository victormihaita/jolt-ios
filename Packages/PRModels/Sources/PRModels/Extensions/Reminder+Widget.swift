import Foundation
import PRCore

public extension Reminder {
    /// Converts a Reminder to a lightweight WidgetReminder for widget display.
    func toWidgetReminder() -> WidgetDataService.WidgetReminder {
        WidgetDataService.WidgetReminder(
            id: id,
            title: title,
            dueAt: effectiveDueDate,
            priority: priority.rawValue,
            isOverdue: isOverdue
        )
    }
}

public extension Array where Element == Reminder {
    /// Converts and filters reminders for widget display.
    /// Returns active/snoozed reminders sorted by due date, limited to specified count.
    func toWidgetReminders(limit: Int = 50) -> [WidgetDataService.WidgetReminder] {
        self
            .filter { $0.status == .active || $0.status == .snoozed }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
            .prefix(limit)
            .map { $0.toWidgetReminder() }
    }
}
