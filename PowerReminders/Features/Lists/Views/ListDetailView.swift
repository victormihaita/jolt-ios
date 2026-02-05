import SwiftUI
import PRModels
import PRSync
import PRNetworking

struct ListDetailView: View {
    let list: ReminderList

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var selectedReminder: Reminder?
    @State private var showCreateReminder = false
    @State private var isCreatingReminder = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dueDate
    @State private var filterOption: FilterOption = .active

    private let graphQL = GraphQLClient.shared

    @Namespace private var namespace

    private var reminders: [Reminder] {
        var result = syncEngine.reminders.filter { $0.listId == list.id }

        // Apply status filter
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { $0.status == .active || $0.status == .snoozed }
        case .completed:
            result = result.filter { $0.status == .completed }
        case .overdue:
            result = result.filter { $0.isOverdue }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                (reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply sort
        switch sortOption {
        case .dueDate:
            result = result.sorted { r1, r2 in
                // Reminders without dates go to the end
                switch (r1.dueAt, r2.dueAt) {
                case (nil, nil): return r1.createdAt > r2.createdAt
                case (nil, _): return false
                case (_, nil): return true
                case (let d1?, let d2?): return d1 < d2
                }
            }
        case .priority:
            result = result.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .createdAt:
            result = result.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            result = result.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if reminders.isEmpty && searchText.isEmpty {
                    emptyState
                } else {
                    reminderList
                }
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search in \(list.name)")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                    }
                    .tint(list.color)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Sort options
                        Section("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    sortOption = option
                                }) {
                                    HStack {
                                        Text(option.title)
                                        Spacer()
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        // Filter options
                        Section("Filter") {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(action: {
                                    filterOption = option
                                }) {
                                    HStack {
                                        Text(option.title)
                                        Spacer()
                                        if filterOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                    .tint(list.color)
                }
            }
            .fullScreenCover(isPresented: $showCreateReminder) {
                CreateReminderView(preselectedListId: list.id)
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                CreateReminderView(editingReminder: reminder)
            }
        }
    }

    private var reminderList: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRowView(reminder: reminder, listColor: list.color)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isCreatingReminder {
                            withAnimation(.snappy) {
                                isCreatingReminder = false
                            }
                        }
                        selectedReminder = reminder
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteReminder(reminder)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)

                        if reminder.status != .completed {
                            Button {
                                completeReminder(reminder)
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if reminder.status != .completed {
                            Button {
                                snoozeReminder(reminder, minutes: 15)
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                            }
                            .tint(.orange)
                        }
                    }
                    .contextMenu {
                        Button {
                            selectedReminder = reminder
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        if reminder.status != .completed {
                            Button {
                                completeReminder(reminder)
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle")
                            }
                        }

                        if reminder.status != .completed {
                            Menu {
                                Button { snoozeReminder(reminder, minutes: 5) } label: { Text("5 minutes") }
                                Button { snoozeReminder(reminder, minutes: 15) } label: { Text("15 minutes") }
                                Button { snoozeReminder(reminder, minutes: 30) } label: { Text("30 minutes") }
                                Button { snoozeReminder(reminder, minutes: 60) } label: { Text("1 hour") }
                            } label: {
                                Label("Snooze", systemImage: "clock.arrow.circlepath")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteReminder(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: Theme.Spacing.md, bottom: Theme.Spacing.xs, trailing: Theme.Spacing.md))

            // Inline reminder creation row at the end
            InlineReminderInput(listId: list.id, isCreating: $isCreatingReminder, themeColor: list.color)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: Theme.Spacing.md, bottom: Theme.Spacing.xs, trailing: Theme.Spacing.md))
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                .font(.system(size: 60))
                .foregroundStyle(list.color.opacity(0.5))

            Text("No Reminders")
                .font(Theme.Typography.title2)

            Text("Create your first reminder below")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Inline reminder creation at bottom of empty state - auto-focus for fast input
            InlineReminderInput(listId: list.id, isCreating: $isCreatingReminder, autoFocus: true, themeColor: list.color)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteReminder(_ reminder: Reminder) {
        Haptics.medium()
        Task {
            do {
                let mutation = PRAPI.DeleteReminderMutation(id: reminder.id.uuidString.lowercased())
                _ = try await graphQL.perform(mutation: mutation)
                // Trigger refetch to update UI immediately
                SyncEngine.shared.refetch()
            } catch {
                print("Failed to delete reminder: \(error)")
            }
        }
    }

    private func completeReminder(_ reminder: Reminder) {
        Haptics.success()
        Task {
            do {
                let mutation = PRAPI.CompleteReminderMutation(id: reminder.id.uuidString.lowercased())
                _ = try await graphQL.perform(mutation: mutation)
                SyncEngine.shared.refetch()
            } catch {
                print("Failed to complete reminder: \(error)")
            }
        }
    }

    private func snoozeReminder(_ reminder: Reminder, minutes: Int) {
        Haptics.medium()
        Task {
            do {
                let mutation = PRAPI.SnoozeReminderMutation(id: reminder.id.uuidString.lowercased(), minutes: minutes)
                _ = try await graphQL.perform(mutation: mutation)
                SyncEngine.shared.refetch()
            } catch {
                print("Failed to snooze reminder: \(error)")
            }
        }
    }
}

// MARK: - Sort & Filter Options

private enum SortOption: CaseIterable {
    case dueDate, priority, createdAt, alphabetical

    var title: String {
        switch self {
        case .dueDate: return "Due Date"
        case .priority: return "Priority"
        case .createdAt: return "Created Date"
        case .alphabetical: return "Alphabetical"
        }
    }
}

private enum FilterOption: CaseIterable {
    case all, active, completed, overdue

    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        }
    }
}

#Preview {
    ListDetailView(list: ReminderList.createDefault())
}
