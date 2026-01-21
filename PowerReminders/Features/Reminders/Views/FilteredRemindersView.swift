import SwiftUI
import PRModels
import PRSync

struct FilteredRemindersView: View {
    let filterType: SmartFilterType

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var selectedReminder: Reminder?
    @State private var searchText = ""

    @Namespace private var namespace

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
                reminder.dueAt > Date()
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

        // Sort by due date
        return result.sorted { $0.dueAt < $1.dueAt }
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
                ReminderDetailView(reminder: reminder)
                    .modifier(ZoomTransitionModifier(sourceID: reminder.id, namespace: namespace))
            }
        }
    }

    private var reminderList: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRowView(reminder: reminder)
                    .contentShape(Rectangle())
                    .modifier(MatchedTransitionSourceModifier(id: reminder.id, namespace: namespace))
                    .onTapGesture {
                        selectedReminder = reminder
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteReminder(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        if filterType != .completed {
                            Button {
                                completeReminder(reminder)
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if filterType != .completed {
                            Button {
                                // Show snooze options
                                selectedReminder = reminder
                            } label: {
                                Label("Snooze", systemImage: "clock.arrow.circlepath")
                            }
                            .tint(.orange)
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
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
            // TODO: Call delete mutation via ViewModel
        }
    }

    private func completeReminder(_ reminder: Reminder) {
        Haptics.success()
        Task {
            // TODO: Call complete mutation via ViewModel
        }
    }
}

#Preview {
    FilteredRemindersView(filterType: .today)
}
