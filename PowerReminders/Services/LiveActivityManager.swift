import ActivityKit
import Foundation
import PRModels

/// Manages Live Activities for reminders, displaying countdown timers on the
/// lock screen and Dynamic Island when a reminder is approaching its due time.
///
/// Live Activities are started 5 minutes before a reminder is due and remain
/// active until the reminder is completed, snoozed, or dismissed.
@MainActor
final class LiveActivityManager {

    /// Shared singleton instance.
    static let shared = LiveActivityManager()

    /// Maps reminder IDs to their scheduled timer for deferred activity starts.
    private var scheduledTimers: [UUID: Timer] = [:]

    /// The lead time before a reminder's due date to start the Live Activity.
    private static let leadTimeSeconds: TimeInterval = 5 * 60 // 5 minutes

    private init() {}

    // MARK: - Start Activity

    /// Starts a Live Activity for the given reminder if conditions are met.
    ///
    /// Conditions:
    /// - Live Activities are enabled on the device.
    /// - The reminder has a due date.
    /// - No existing Live Activity is already tracking this reminder.
    ///
    /// - Parameter reminder: The reminder to display as a Live Activity.
    func startActivity(for reminder: Reminder) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        guard let dueAt = reminder.dueAt else {
            return
        }

        // Do not start a duplicate activity
        let existingActivity = findActivity(for: reminder.id)
        if existingActivity != nil {
            return
        }

        let attributes = ReminderActivityAttributes(
            reminderId: reminder.id.uuidString
        )

        let isOverdue = dueAt < Date()

        let state = ReminderActivityAttributes.ContentState(
            reminderTitle: reminder.title,
            dueAt: dueAt,
            isOverdue: isOverdue,
            priority: reminder.priority.rawValue
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: dueAt.addingTimeInterval(30 * 60)),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity for reminder \(reminder.id): \(error)")
        }
    }

    // MARK: - End Activity

    /// Ends the Live Activity associated with the given reminder ID.
    ///
    /// - Parameter reminderId: The UUID of the reminder whose activity should end.
    func endActivity(for reminderId: UUID) {
        // Cancel any scheduled timer
        scheduledTimers[reminderId]?.invalidate()
        scheduledTimers.removeValue(forKey: reminderId)

        guard let activity = findActivity(for: reminderId) else {
            return
        }

        let finalState = activity.content.state

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }

    // MARK: - Update Activity

    /// Updates the Live Activity state for a given reminder.
    ///
    /// - Parameters:
    ///   - reminderId: The UUID of the reminder to update.
    ///   - isOverdue: Whether the reminder is now overdue.
    func updateActivity(for reminderId: UUID, isOverdue: Bool) {
        guard let activity = findActivity(for: reminderId) else {
            return
        }

        var updatedState = activity.content.state
        updatedState.isOverdue = isOverdue

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    // MARK: - Schedule Activity Start

    /// Schedules a Live Activity to start 5 minutes before the reminder's due date.
    ///
    /// If the reminder is due in less than 5 minutes, the activity starts immediately.
    /// If the reminder has no due date, this method does nothing.
    ///
    /// - Parameter reminder: The reminder to schedule.
    func scheduleActivityStart(for reminder: Reminder) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        guard let dueAt = reminder.dueAt else {
            return
        }

        // Cancel any previously scheduled timer for this reminder
        scheduledTimers[reminder.id]?.invalidate()
        scheduledTimers.removeValue(forKey: reminder.id)

        let now = Date()
        let startTime = dueAt.addingTimeInterval(-Self.leadTimeSeconds)
        let delay = startTime.timeIntervalSince(now)

        if delay <= 0 {
            // Due within 5 minutes or already overdue -- start immediately
            startActivity(for: reminder)
        } else {
            // Schedule the start for 5 minutes before due
            let timer = Timer.scheduledTimer(
                withTimeInterval: delay,
                repeats: false
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.startActivity(for: reminder)
                    self?.scheduledTimers.removeValue(forKey: reminder.id)
                }
            }
            scheduledTimers[reminder.id] = timer
        }
    }

    // MARK: - End All Activities

    /// Ends all active Live Activities for reminders. Typically called on logout.
    func endAllActivities() {
        // Cancel all scheduled timers
        for (_, timer) in scheduledTimers {
            timer.invalidate()
        }
        scheduledTimers.removeAll()

        // End all running activities
        for activity in Activity<ReminderActivityAttributes>.activities {
            let finalState = activity.content.state
            Task {
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }
    }

    // MARK: - Private Helpers

    /// Finds an active Live Activity for the given reminder ID.
    ///
    /// - Parameter reminderId: The UUID of the reminder.
    /// - Returns: The matching `Activity`, or `nil` if none exists.
    private func findActivity(for reminderId: UUID) -> Activity<ReminderActivityAttributes>? {
        Activity<ReminderActivityAttributes>.activities.first { activity in
            activity.attributes.reminderId == reminderId.uuidString
        }
    }
}
