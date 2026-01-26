import Foundation
import PRCore

public extension Reminder {
    /// Converts a Reminder to a lightweight WidgetReminder for widget display.
    /// Returns nil if the reminder has no scheduled date.
    func toWidgetReminder() -> WidgetDataService.WidgetReminder? {
        guard dueAt != nil else { return nil }
        return WidgetDataService.WidgetReminder(
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
    /// Returns active/snoozed reminders with dates, sorted by due date, limited to specified count.
    /// Reminders without dates are excluded from widget display.
    func toWidgetReminders(limit: Int = 50) -> [WidgetDataService.WidgetReminder] {
        self
            .filter { $0.status == .active || $0.status == .snoozed }
            .filter { $0.dueAt != nil }  // Only include reminders with dates
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
            .prefix(limit)
            .compactMap { $0.toWidgetReminder() }
    }
}
