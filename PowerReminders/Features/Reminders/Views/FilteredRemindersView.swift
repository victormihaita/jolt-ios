import SwiftUI
import PRModels
import PRSync
import PRNetworking

struct FilteredRemindersView: View {
    let filterType: SmartFilterType

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var selectedReminder: Reminder?
    @State private var searchText = ""

    @Namespace private var namespace

    private let graphQL = GraphQLClient.shared

    private var reminders: [Reminder] {
        var result: [Reminder]

        switch filterType {
        case .today:
            result = syncEngine.reminders.filter { reminder in
                (reminder.status == .active || reminder.status == .snoozed) &&
                Calendar.current.isDateInToday(reminder.effectiveDueDate)
            }
        case .all:
            result = syncEngine.reminders.filter { $0.status == .active || $0.status == .snoozed }
        case .scheduled:
            result = syncEngine.reminders.filter { reminder in
                (reminder.status == .active || reminder.status == .snoozed) &&
                reminder.dueAt != nil &&
                reminder.dueAt! > Date()
            }
        case .completed:
            result = syncEngine.reminders.filter { $0.status == .completed }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                (reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Sort by due date (reminders without dates go to end)
        return result.sorted { r1, r2 in
            switch (r1.dueAt, r2.dueAt) {
            case (nil, nil): return r1.createdAt > r2.createdAt
            case (nil, _): return false
            case (_, nil): return true
            case (let d1?, let d2?): return d1 < d2
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if reminders.isEmpty && searchText.isEmpty {
                    emptyState
                } else if reminders.isEmpty {
                    noSearchResults
                } else {
                    reminderList
                }
            }
            .navigationTitle(filterType.title)
            .navigationBarTitleDisplayMode(.large)
            .tint(filterType.color)
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                CreateReminderView(editingReminder: reminder)
                    .modifier(ZoomTransitionModifier(sourceID: reminder.id, namespace: namespace))
            }
        }
    }

    /// Get the list color for a reminder
    private func listColor(for reminder: Reminder) -> Color {
        let listId = reminder.listId
        
        guard let list = syncEngine.reminderLists.first(where: { $0.id == listId }) else {
            return filterType.color
        }
        return list.color
    }

    private var reminderList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(reminders) { reminder in
                    ReminderRowView(reminder: reminder, listColor: listColor(for: reminder))
                        .contentShape(Rectangle())
                        .modifier(MatchedTransitionSourceModifier(id: reminder.id, namespace: namespace))
                        .onTapGesture {
                            selectedReminder = reminder
                        }
                        .contextMenu {
                            if filterType != .completed {
                                Button {
                                    completeReminder(reminder)
                                } label: {
                                    Label("Done", systemImage: "checkmark.circle")
                                }
                            }

                            Button(role: .destructive) {
                                deleteReminder(reminder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: filterType.icon)
                .font(.system(size: 60))
                .foregroundStyle(filterType.color.opacity(0.5))

            Text(emptyTitle)
                .font(Theme.Typography.title2)

            Text(emptyMessage)
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var noSearchResults: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Results")
                .font(Theme.Typography.title2)

            Text("No reminders match '\(searchText)'")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var emptyTitle: String {
        switch filterType {
        case .today: return "Nothing Due Today"
        case .all: return "No Reminders"
        case .scheduled: return "No Scheduled Reminders"
        case .completed: return "No Completed Reminders"
        }
    }

    private var emptyMessage: String {
        switch filterType {
        case .today: return "You're all caught up! Enjoy your day."
        case .all: return "Create your first reminder to get started."
        case .scheduled: return "All your reminders have already passed."
        case .completed: return "Complete some reminders to see them here."
        }
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
                // Trigger refetch to update UI immediately
                SyncEngine.shared.refetch()
            } catch {
                print("Failed to complete reminder: \(error)")
            }
        }
    }
}

#Preview {
    FilteredRemindersView(filterType: .today)
}
