import SwiftUI
import PRModels
import PRNetworking
import PRSync

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @StateObject private var viewModel: ReminderDetailViewModel

    @State private var showEditSheet = false
    @State private var showSnoozeSheet = false
    @State private var showDeleteConfirmation = false

    /// The current reminder from the watcher (reactive)
    private var reminder: PRModels.Reminder? {
        viewModel.reminder
    }

    init(reminder: PRModels.Reminder) {
        _viewModel = StateObject(wrappedValue: ReminderDetailViewModel(
            reminderId: reminder.id,
            initialReminder: reminder
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let reminder = reminder {
                    reminderContent(reminder)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(reminder?.title ?? "Reminder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if reminder != nil {
                        Menu {
                            Button(action: { showEditSheet = true }) {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let reminder = reminder {
                    EditReminderView(reminder: reminder)
                }
            }
            .sheet(isPresented: $showSnoozeSheet) {
                SnoozePickerView(viewModel: viewModel)
            }
            .confirmationDialog("Delete Reminder", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive, action: deleteReminder)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this reminder?")
            }
            .onAppear {
                viewModel.startWatching()
            }
            .onDisappear {
                viewModel.stopWatching()
            }
        }
    }

    @ViewBuilder
    private func reminderContent(_ reminder: PRModels.Reminder) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Notes Section (if present)
                if let notes = reminder.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Notes", systemImage: "note.text")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)

                        Text(notes)
                            .font(Theme.Typography.body)
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass()
                }

                // Details Section
                VStack(spacing: 0) {
                    // Priority
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "flag.fill")
                            .font(.body)
                            .foregroundStyle(priorityColor(for: reminder))
                            .frame(width: 24)

                        Text("Priority")
                            .font(Theme.Typography.body)

                        Spacer()

                        Text(reminder.priority.displayName)
                            .font(Theme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)

                    Divider()
                        .padding(.leading, 44)

                    // Due Date
                    DetailRow(
                        icon: "clock",
                        title: "Due",
                        value: formattedDueDate(for: reminder),
                        valueColor: reminder.isOverdue ? Theme.Colors.error : .primary
                    )

                    Divider()
                        .padding(.leading, 44)

                    // All Day
                    if reminder.allDay {
                        DetailRow(
                            icon: "sun.max",
                            title: "All Day",
                            value: "Yes"
                        )

                        Divider()
                            .padding(.leading, 44)
                    }

                    // Recurrence
                    if reminder.isRecurring {
                        DetailRow(
                            icon: "repeat",
                            title: "Repeats",
                            value: reminder.recurrenceRule?.displayString ?? "Unknown"
                        )

                        Divider()
                            .padding(.leading, 44)
                    }

                    // Status
                    DetailRow(
                        icon: statusIcon(for: reminder.status),
                        title: "Status",
                        value: statusDisplayName(for: reminder.status),
                        valueColor: statusColor(for: reminder.status)
                    )

                    // Snoozed info
                    if reminder.isSnoozed {
                        Divider()
                            .padding(.leading, 44)

                        DetailRow(
                            icon: "moon.zzz",
                            title: "Snoozed until",
                            value: formattedSnoozedUntil(for: reminder),
                            valueColor: .orange
                        )
                    }

                    // Snooze count (only show if > 0)
                    if reminder.snoozeCount > 0 {
                        Divider()
                            .padding(.leading, 44)

                        DetailRow(
                            icon: "bell.badge",
                            title: "Snooze count",
                            value: "\(reminder.snoozeCount) time\(reminder.snoozeCount == 1 ? "" : "s")"
                        )
                    }
                }
                .liquidGlass()

                // Metadata Section
                VStack(spacing: 0) {
                    DetailRow(
                        icon: "calendar.badge.plus",
                        title: "Created",
                        value: formattedTimestamp(reminder.createdAt)
                    )

                    Divider()
                        .padding(.leading, 44)

                    DetailRow(
                        icon: "pencil.circle",
                        title: "Updated",
                        value: formattedTimestamp(reminder.updatedAt)
                    )
                }
                .liquidGlass()

                // Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    // Snooze Button
                    Button(action: {
                        Haptics.medium()
                        showSnoozeSheet = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Snooze")
                        }
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    }
                    .disabled(viewModel.isLoading)

                    // Complete Button
                    Button(action: completeReminder) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("Mark as Done")
                        }
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.top, Theme.Spacing.md)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func priorityColor(for reminder: PRModels.Reminder) -> Color {
        switch reminder.priority {
        case .high: return Theme.Colors.priorityHigh
        case .normal: return Theme.Colors.priorityNormal
        case .low: return Theme.Colors.priorityLow
        case .none: return Theme.Colors.priorityNone
        }
    }

    private func formattedDueDate(for reminder: PRModels.Reminder) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: reminder.effectiveDueDate)
    }

    private func formattedSnoozedUntil(for reminder: PRModels.Reminder) -> String {
        guard let snoozedUntil = reminder.snoozedUntil else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: snoozedUntil)
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func statusIcon(for status: PRModels.ReminderStatus) -> String {
        switch status {
        case .active: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .snoozed: return "moon.zzz.fill"
        case .dismissed: return "xmark.circle.fill"
        }
    }

    private func statusDisplayName(for status: PRModels.ReminderStatus) -> String {
        switch status {
        case .active: return "Active"
        case .completed: return "Completed"
        case .snoozed: return "Snoozed"
        case .dismissed: return "Dismissed"
        }
    }

    private func statusColor(for status: PRModels.ReminderStatus) -> Color {
        switch status {
        case .active: return .primary
        case .completed: return .green
        case .snoozed: return .orange
        case .dismissed: return .secondary
        }
    }

    private func completeReminder() {
        Haptics.success()
        Task {
            let success = await viewModel.completeReminder()
            if success {
                dismiss()
            }
        }
    }

    private func deleteReminder() {
        Haptics.warning()
        Task {
            let success = await viewModel.deleteReminder()
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .font(Theme.Typography.body)

            Spacer()

            Text(value)
                .font(Theme.Typography.body)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Snooze Picker

struct SnoozePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @ObservedObject var viewModel: ReminderDetailViewModel

    @State private var customMinutes = 15
    @State private var showPremiumPrompt = false

    let quickOptions = [5, 15, 30, 60] // minutes

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Remind me again in...")
                    .font(Theme.Typography.headline)
                    .padding(.top, Theme.Spacing.lg)

                // Quick Options
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(quickOptions, id: \.self) { minutes in
                        QuickSnoozeButton(minutes: minutes, isLoading: viewModel.isLoading) {
                            snooze(minutes: minutes)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Divider()
                    .padding(.vertical, Theme.Spacing.md)

                // Custom Snooze (Premium)
                if subscriptionViewModel.isPremium {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack {
                            Text("Custom time:")
                                .font(Theme.Typography.body)

                            Spacer()

                            Picker("Minutes", selection: $customMinutes) {
                                ForEach(1...120, id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        Button(action: { snooze(minutes: customMinutes) }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Snooze for \(customMinutes) minutes")
                            }
                            .font(Theme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                } else {
                    // Premium Upsell
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)

                        Text("Unlock Custom Snooze")
                            .font(Theme.Typography.headline)

                        Text("Snooze for any amount of time you choose")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: { showPremiumPrompt = true }) {
                            Text("Upgrade to Premium")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.premiumGradient)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .liquidGlass()
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()
            }
            .navigationTitle("Snooze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumPrompt) {
                PremiumView()
            }
        }
        .presentationDetents([.medium])
    }

    private func snooze(minutes: Int) {
        Haptics.medium()
        Task {
            let success = await viewModel.snoozeReminder(minutes: minutes)
            if success {
                dismiss()
            }
        }
    }
}

struct QuickSnoozeButton: View {
    let minutes: Int
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            VStack(spacing: Theme.Spacing.xs) {
                Text("\(displayValue)")
                    .font(Theme.Typography.title2)
                Text(displayUnit)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .foregroundColor(.primary)
        .disabled(isLoading)
    }

    private var displayValue: String {
        if minutes >= 60 {
            return "\(minutes / 60)"
        }
        return "\(minutes)"
    }

    private var displayUnit: String {
        if minutes >= 60 {
            return minutes == 60 ? "hour" : "hours"
        }
        return "min"
    }
}

// MARK: - Edit Reminder View (wraps CreateReminderView for editing)

struct EditReminderView: View {
    let reminder: PRModels.Reminder

    var body: some View {
        CreateReminderView(editingReminder: reminder)
    }
}

#Preview {
    let previewReminder = PRModels.Reminder(
        id: UUID(),
        title: "Call the dentist",
        notes: "Remember to ask about the cleaning",
        priority: .high,
        dueAt: Date(),
        allDay: false,
        recurrenceRule: nil,
        recurrenceEnd: nil,
        status: .active,
        completedAt: nil,
        snoozedUntil: nil,
        snoozeCount: 0,
        localId: nil,
        version: 1,
        createdAt: Date(),
        updatedAt: Date(),
        listId: UUID()
    )
    ReminderDetailView(reminder: previewReminder)
        .environmentObject(SubscriptionViewModel())
}
