import SwiftUI
import Combine
import PRModels
import PRSync

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let syncEngine = SyncEngine.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var todayCount: Int {
        syncEngine.reminders.filter { reminder in
            reminder.status == .active && Calendar.current.isDateInToday(reminder.effectiveDueDate)
        }.count
    }

    var allCount: Int {
        syncEngine.reminders.filter { $0.status == .active || $0.status == .snoozed }.count
    }

    var scheduledCount: Int {
        syncEngine.reminders.filter { reminder in
            (reminder.status == .active || reminder.status == .snoozed) && reminder.dueAt > Date()
        }.count
    }

    var completedCount: Int {
        syncEngine.reminders.filter { $0.status == .completed }.count
    }

    var overdueCount: Int {
        syncEngine.reminders.filter { $0.isOverdue }.count
    }

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Observe SyncEngine changes and trigger view updates
        syncEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - List Management

    func createList(name: String, colorHex: String, iconName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await syncEngine.createList(
                name: name,
                colorHex: colorHex,
                iconName: iconName
            )
            print("📋 List created successfully")
        } catch {
            print("📋 Failed to create list: \(error)")
            errorMessage = "Failed to create list: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteList(_ list: ReminderList) async {
        guard !list.isDefault else {
            errorMessage = "Cannot delete the default list"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await syncEngine.deleteList(id: list.id)
            print("📋 List deleted successfully")
        } catch {
            print("📋 Failed to delete list: \(error)")
            errorMessage = "Failed to delete list: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func reorderLists(_ reorderedLists: [ReminderList]) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await syncEngine.reorderLists(ids: reorderedLists.map { $0.id })
            print("📋 Lists reordered successfully")
        } catch {
            print("📋 Failed to reorder lists: \(error)")
            errorMessage = "Failed to reorder lists: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
