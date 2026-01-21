import Foundation
import SwiftUI
import PRNetworking
import PRModels
import PRSync
import Apollo

/// ViewModel for the reminder detail view that watches a single reminder for changes.
/// Uses Apollo GraphQL watcher to keep data in sync with the cache.
/// Supports offline mode with optimistic updates.
@MainActor
class ReminderDetailViewModel: ObservableObject {
    @Published var reminder: PRModels.Reminder?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let graphQL = GraphQLClient.shared
    private let syncEngine = SyncEngine.shared
    private var watcher: GraphQLWatcher?
    private let reminderId: UUID

    init(reminderId: UUID, initialReminder: PRModels.Reminder? = nil) {
        self.reminderId = reminderId
        self.reminder = initialReminder
    }

    deinit {
        watcher?.cancel()
    }

    // MARK: - Watch

    func startWatching() {
        let query = PRAPI.ReminderQuery(id: reminderId.uuidString)

        watcher = graphQL.watch(query: query) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let data):
                    if let reminderData = data.reminder {
                        self.reminder = self.convertReminder(reminderData)
                    }
                case .failure(let error):
                    print("❌ ReminderDetailViewModel watcher error: \(error)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopWatching() {
        watcher?.cancel()
        watcher = nil
    }

    func refetch() {
        watcher?.refetch()
    }

    // MARK: - API Operations (with offline support)

    func deleteReminder() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let queuePayload = DeleteReminderPayload(id: reminderId.uuidString.lowercased())
        let queuedMutation = QueuedMutation.deleteReminder(queuePayload)

        do {
            let mutation = PRAPI.DeleteReminderMutation(id: reminderId.uuidString.lowercased())
            _ = try await graphQL.performWithOfflineSupport(
                mutation: mutation,
                queuedMutation: queuedMutation,
                optimisticUpdate: { [weak self] in
                    guard let self = self else { return }
                    self.syncEngine.removeOptimisticReminder(id: self.reminderId)
                }
            )
            return true
        } catch let error as NetworkError where error.isOffline {
            // Offline - optimistic update applied, mutation queued
            return true
        } catch {
            errorMessage = "Failed to delete reminder: \(error.localizedDescription)"
            return false
        }
    }

    func completeReminder() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let queuePayload = CompleteReminderPayload(id: reminderId.uuidString.lowercased())
        let queuedMutation = QueuedMutation.completeReminder(queuePayload)

        do {
            let mutation = PRAPI.CompleteReminderMutation(id: reminderId.uuidString.lowercased())
            _ = try await graphQL.performWithOfflineSupport(
                mutation: mutation,
                queuedMutation: queuedMutation,
                optimisticUpdate: { [weak self] in
                    guard let self = self, var updatedReminder = self.reminder else { return }
                    updatedReminder.status = .completed
                    updatedReminder.completedAt = Date()
                    self.reminder = updatedReminder
                    self.syncEngine.updateOptimisticReminder(updatedReminder)
                }
            )
            return true
        } catch let error as NetworkError where error.isOffline {
            // Offline - optimistic update applied, mutation queued
            return true
        } catch {
            errorMessage = "Failed to complete reminder: \(error.localizedDescription)"
            return false
        }
    }

    func snoozeReminder(minutes: Int) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let queuePayload = SnoozeReminderPayload(id: reminderId.uuidString.lowercased(), minutes: minutes)
        let queuedMutation = QueuedMutation.snoozeReminder(queuePayload)

        do {
            let mutation = PRAPI.SnoozeReminderMutation(id: reminderId.uuidString.lowercased(), minutes: minutes)
            _ = try await graphQL.performWithOfflineSupport(
                mutation: mutation,
                queuedMutation: queuedMutation,
                optimisticUpdate: { [weak self] in
                    guard let self = self, var updatedReminder = self.reminder else { return }
                    updatedReminder.status = .snoozed
                    updatedReminder.snoozedUntil = Date().addingTimeInterval(Double(minutes) * 60)
                    updatedReminder.snoozeCount += 1
                    self.reminder = updatedReminder
                    self.syncEngine.updateOptimisticReminder(updatedReminder)
                }
            )
            return true
        } catch let error as NetworkError where error.isOffline {
            // Offline - optimistic update applied, mutation queued
            return true
        } catch {
            errorMessage = "Failed to snooze reminder: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Data Conversion

    private func convertReminder(_ data: PRAPI.ReminderQuery.Data.Reminder) -> PRModels.Reminder {
        let id = UUID(uuidString: data.id) ?? UUID()

        let priority = convertPriority(data.priority)
        let status = convertStatus(data.status)
        let recurrenceRule = data.recurrenceRule.map { convertRecurrenceRule($0) }

        return PRModels.Reminder(
            id: id,
            title: data.title,
            notes: data.notes,
            priority: priority,
            dueAt: data.dueAt.toDate() ?? Date(),
            allDay: data.allDay,
            recurrenceRule: recurrenceRule,
            recurrenceEnd: data.recurrenceEnd?.toDate(),
            status: status,
            completedAt: data.completedAt?.toDate(),
            snoozedUntil: data.snoozedUntil?.toDate(),
            snoozeCount: data.snoozeCount,
            localId: data.localId,
            version: data.version,
            createdAt: data.createdAt.toDate() ?? Date(),
            updatedAt: data.updatedAt.toDate() ?? Date(),
            listId: Self.defaultListId // TODO: Get from backend when list support is added
        )
    }

    // Default list ID (matches SyncEngine)
    private static let defaultListId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func convertPriority(_ priority: GraphQLEnum<PRAPI.Priority>) -> PRModels.Priority {
        switch priority.value {
        case .some(.low): return .low
        case .some(.normal): return .normal
        case .some(.high): return .high
        default: return .none
        }
    }

    private func convertStatus(_ status: GraphQLEnum<PRAPI.ReminderStatus>) -> PRModels.ReminderStatus {
        switch status.value {
        case .some(.active): return .active
        case .some(.completed): return .completed
        case .some(.snoozed): return .snoozed
        case .some(.dismissed): return .dismissed
        case .none: return .active
        }
    }

    private func convertRecurrenceRule(_ rule: PRAPI.ReminderQuery.Data.Reminder.RecurrenceRule) -> PRModels.RecurrenceRule {
        let frequency = convertFrequency(rule.frequency)

        return PRModels.RecurrenceRule(
            frequency: frequency,
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek,
            dayOfMonth: rule.dayOfMonth,
            monthOfYear: rule.monthOfYear,
            endAfterOccurrences: rule.endAfterOccurrences,
            endDate: rule.endDate?.toDate()
        )
    }

    private func convertFrequency(_ frequency: GraphQLEnum<PRAPI.Frequency>) -> PRModels.Frequency {
        switch frequency.value {
        case .some(.hourly): return .hourly
        case .some(.daily): return .daily
        case .some(.weekly): return .weekly
        case .some(.monthly): return .monthly
        case .some(.yearly): return .yearly
        case .none: return .daily
        }
    }
}

// MARK: - Date Conversion

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: self) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}
