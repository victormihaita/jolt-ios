import SwiftUI
import PRSync
import PRNetworking
import PRModels

// Use PRModels types (aliased for convenience)
typealias JReminder = PRModels.Reminder
typealias JPriority = PRModels.Priority
typealias JReminderStatus = PRModels.ReminderStatus

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
                        .modifier(MatchedTransitionSourceModifier(id: "createReminder", namespace: namespace))
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
                    .modifier(MatchedTransitionSourceModifier(id: "settings", namespace: namespace))
                }
            }
            .fullScreenCover(isPresented: $showCreateSheet) {
                CreateReminderView()
                    .modifier(ZoomTransitionModifier(sourceID: "createReminder", namespace: namespace))
            }
            .fullScreenCover(isPresented: $showSettingsSheet) {
                SettingsView()
                    .modifier(ZoomTransitionModifier(sourceID: "settings", namespace: namespace))
            }
            .fullScreenCover(item: $selectedReminder) { reminder in
                CreateReminderView(editingReminder: reminder)
                    .modifier(ZoomTransitionModifier(sourceID: reminder.id, namespace: namespace))
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

    /// Get the list color for a reminder
    private func listColor(for reminder: JReminder) -> Color {
        let listId = reminder.listId
        
        guard let list = syncEngine.reminderLists.first(where: { $0.id == listId }) else {
            return .accentColor
        }
        return list.color
    }

    private var reminderList: some View {
        List {
            ForEach(filteredReminders) { reminder in
                ReminderRowView(reminder: reminder, listColor: listColor(for: reminder))
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
    var listColor: Color = .accentColor

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Priority indicator circle (matching the inline creation style)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [listColor, listColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: priorityIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(reminder.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: Theme.Spacing.sm) {
                    // Due date (only show if set)
                    if reminder.dueAt != nil {
                        Label(formattedDueDate, systemImage: reminder.isOverdue ? "exclamationmark.circle" : "clock")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(reminder.isOverdue ? Theme.Colors.error : .secondary)
                    } else {
                        Label("No date", systemImage: "calendar.badge.minus")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Alarm indicator
                    if reminder.isAlarm {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    // Recurrence indicator
                    if reminder.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Snoozed indicator
                    if reminder.isSnoozed {
                        Label("Snoozed", systemImage: "moon.zzz.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Snooze count badge
            if reminder.snoozeCount > 0 {
                Text("\(reminder.snoozeCount)×")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(listColor)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(listColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            listColor.opacity(0.08),
                            listColor.opacity(0.03)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .strokeBorder(listColor.opacity(0.1), lineWidth: 1)
        )
    }

    private var priorityIcon: String {
        switch reminder.priority {
        case .high: return "exclamationmark"
        case .normal: return "minus"
        case .low: return "arrow.down"
        case .none: return "circle"
        }
    }

    private var formattedDueDate: String {
        guard reminder.dueAt != nil else { return "No date" }
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

// MARK: - iOS 18 Transition Modifiers (Backwards Compatible)

struct MatchedTransitionSourceModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
            }
        } else {
            content
        }
    }
}

struct ZoomTransitionModifier<ID: Hashable>: ViewModifier {
    let sourceID: ID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}

#Preview {
    HomeView()
}
