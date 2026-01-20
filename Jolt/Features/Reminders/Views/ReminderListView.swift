import SwiftUI
import JoltSync
import JoltNetworking
import JoltModels

// Use JoltModels types
typealias JReminder = JoltModels.Reminder
typealias JPriority = JoltModels.Priority
typealias JReminderStatus = JoltModels.ReminderStatus

// MARK: - Home View (Single-Screen Architecture per UX Design)

struct HomeView: View {
    @ObservedObject private var syncEngine = SyncEngine.shared
    @StateObject private var viewModel = ReminderListViewModel()

    @State private var showCreateSheet = false
    @State private var showSettingsSheet = false
    @State private var selectedReminder: JReminder?
    @State private var searchText = ""

    @Namespace private var namespace

    /// Filtered active reminders from the sync engine (GraphQL cache is source of truth)
    private var reminders: [JReminder] {
        let all = syncEngine.reminders
        let filtered = all.filter { $0.status == .active || $0.status == .snoozed }
        print("📋 HomeView.reminders: total=\(all.count), filtered=\(filtered.count)")
        return filtered
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if reminders.isEmpty && searchText.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "All clear!",
                        message: "You have no reminders yet.\nCreate your first one below.",
                        action: { showCreateSheet = true }
                    )
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
                            showCreateSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .matchedTransitionSource(id: "createReminder", in: namespace) { source in
                            source.clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                        .padding(.trailing, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Reminders")
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Haptics.light()
                        showSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
            }
            .fullScreenCover(isPresented: $showCreateSheet) {
                CreateReminderView()
                    .navigationTransition(.zoom(sourceID: "createReminder", in: namespace))
            }
            .fullScreenCover(isPresented: $showSettingsSheet) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                ReminderDetailView(reminder: reminder)
                    .navigationTransition(.zoom(sourceID: reminder.id, in: namespace))
            }
            .refreshable {
                syncEngine.refetch()
            }
            .onAppear {
                print("📋 HomeView.onAppear - reminders count: \(syncEngine.reminders.count)")
                // Connect SyncEngine when view appears (starts watchers)
                syncEngine.connect()
            }
            .onChange(of: syncEngine.reminders.count) { oldCount, newCount in
                print("📋 HomeView.onChange - reminders count changed: \(oldCount) -> \(newCount)")
            }
        }
    }

    private var reminderList: some View {
        List {
            ForEach(filteredReminders) { reminder in
                ReminderRowView(reminder: reminder)
                    .contentShape(Rectangle())
                    .matchedTransitionSource(id: reminder.id, in: namespace)
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
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            showSnoozeOptions(for: reminder)
                        } label: {
                            Label("Snooze", systemImage: "clock.arrow.circlepath")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filteredReminders: [JReminder] {
        var result = reminders

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                (reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply category filter
        switch viewModel.filter {
        case .all:
            break
        case .today:
            result = result.filter { Calendar.current.isDateInToday($0.effectiveDueDate) }
        case .upcoming:
            result = result.filter { $0.effectiveDueDate > Date() }
        case .overdue:
            result = result.filter { $0.isOverdue }
        }

        // Sort by due date
        return result.sorted { $0.dueAt < $1.dueAt }
    }

    private func deleteReminder(_ reminder: JReminder) {
        Haptics.medium()
        Task {
            await viewModel.deleteReminder(reminder.id)
            // Mutation triggers refetch notification, watchers will update automatically
        }
    }

    private func completeReminder(_ reminder: JReminder) {
        Haptics.success()
        Task {
            await viewModel.completeReminder(reminder.id)
            // Mutation triggers refetch notification, watchers will update automatically
        }
    }

    private func showSnoozeOptions(for reminder: JReminder) {
        selectedReminder = reminder
        // The detail view will show snooze options
    }
}

// MARK: - Reminder Row

struct ReminderRowView: View {
    let reminder: JReminder

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(reminder.title)
                    .font(Theme.Typography.headline)
                    .lineLimit(2)

                HStack(spacing: Theme.Spacing.sm) {
                    // Due date
                    Label(formattedDueDate, systemImage: "clock")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(reminder.isOverdue ? Theme.Colors.error : .secondary)

                    // Recurrence indicator
                    if reminder.isRecurring {
                        Label(reminder.recurrenceRule?.displayString ?? "", systemImage: "repeat")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Snoozed indicator
                    if reminder.isSnoozed {
                        Label("Snoozed", systemImage: "moon.zzz")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            if reminder.snoozeCount > 0 {
                Text("\(reminder.snoozeCount)x")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var priorityColor: Color {
        switch reminder.priority {
        case .high: return Theme.Colors.priorityHigh
        case .normal: return Theme.Colors.priorityNormal
        case .low: return Theme.Colors.priorityLow
        case .none: return Theme.Colors.priorityNone
        }
    }

    private var formattedDueDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: reminder.effectiveDueDate, relativeTo: Date())
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(Theme.Typography.title2)

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action {
                Button(action: action) {
                    Text("Create Reminder")
                        .font(Theme.Typography.headline)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

#Preview {
    HomeView()
}
