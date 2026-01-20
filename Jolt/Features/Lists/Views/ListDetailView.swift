import SwiftUI
import JoltModels
import JoltSync

struct ListDetailView: View {
    let list: ReminderList

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var syncEngine = SyncEngine.shared

    @State private var selectedReminder: Reminder?
    @State private var showNaturalLanguageInput = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dueDate
    @State private var filterOption: FilterOption = .active

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
            result = result.sorted { $0.dueAt < $1.dueAt }
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
            ZStack {
                if reminders.isEmpty && searchText.isEmpty {
                    emptyState
                } else {
                    reminderList
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            Haptics.medium()
                            showNaturalLanguageInput = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(list.color)
                                .clipShape(Circle())
                                .shadow(color: list.color.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                    }
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
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Sort options
                        Section("Sort By") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    sortOption = option
                                }) {
                                    Label(option.title, systemImage: sortOption == option ? "checkmark" : "")
                                }
                            }
                        }

                        // Filter options
                        Section("Filter") {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(action: {
                                    filterOption = option
                                }) {
                                    Label(option.title, systemImage: filterOption == option ? "checkmark" : "")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                }
            }
            .fullScreenCover(isPresented: $showNaturalLanguageInput) {
                NaturalLanguageInputView(listId: list.id) { reminder in
                    selectedReminder = reminder
                }
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                ReminderDetailView(reminder: reminder)
            }
        }
    }

    private var reminderList: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRowView(reminder: reminder)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedReminder = reminder
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteReminder(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            completeReminder(reminder)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                .font(.system(size: 60))
                .foregroundStyle(list.color.opacity(0.5))

            Text("No Reminders")
                .font(Theme.Typography.title2)

            Text("Tap the + button to add a reminder to this list.")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
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
