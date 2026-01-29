import ActivityKit
import Foundation

/// Attributes defining the static and dynamic data for a reminder Live Activity.
/// The Live Activity appears on the lock screen and Dynamic Island when a reminder
/// is approaching its due time (5 minutes before).
///
/// NOTE: This definition is duplicated in the widget extension target
/// (Widget/LiveActivity/ReminderActivityAttributes.swift) because the main app
/// and widget extension are separate compilation targets. Both must have an
/// identical definition of this type for ActivityKit to work correctly.
struct ReminderActivityAttributes: ActivityAttributes {

    /// Dynamic state that updates over the lifetime of the Live Activity.
    public struct ContentState: Codable, Hashable {
        /// The reminder's display title.
        var reminderTitle: String
        /// The date/time when the reminder is due.
        var dueAt: Date
        /// Whether the reminder has passed its due time.
        var isOverdue: Bool
        /// Priority raw value (0 = none, 1 = low, 2 = normal, 3 = high).
        var priority: Int
    }

    /// The unique identifier of the reminder this activity tracks.
    var reminderId: String
}
