import Foundation
import SwiftUI
import PRNetworking
import PRSync

enum ReminderFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
}

@MainActor
class ReminderListViewModel: ObservableObject {
    @Published var filter: ReminderFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let graphQL = GraphQLClient.shared

    // MARK: - API Operations

    func deleteReminder(_ id: UUID) async {
        do {
            let mutation = PRAPI.DeleteReminderMutation(id: id.uuidString)
            _ = try await graphQL.perform(mutation: mutation)
            // Trigger refetch to update UI immediately
            SyncEngine.shared.refetch()
        } catch {
            errorMessage = "Failed to delete reminder: \(error.localizedDescription)"
        }
    }

    func completeReminder(_ id: UUID) async {
        do {
            let mutation = PRAPI.CompleteReminderMutation(id: id.uuidString)
            _ = try await graphQL.perform(mutation: mutation)
            // Trigger refetch to update UI immediately
            SyncEngine.shared.refetch()
        } catch {
            errorMessage = "Failed to complete reminder: \(error.localizedDescription)"
        }
    }

    func snoozeReminder(_ id: UUID, minutes: Int) async {
        do {
            let mutation = PRAPI.SnoozeReminderMutation(id: id.uuidString, minutes: minutes)
            _ = try await graphQL.perform(mutation: mutation)
            // Trigger refetch to update UI immediately
            SyncEngine.shared.refetch()
        } catch {
            errorMessage = "Failed to snooze reminder: \(error.localizedDescription)"
        }
    }
}
