import SwiftUI
import PRModels
import PRNetworking
import PRSync

struct CreateReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel

    var editingReminder: PRModels.Reminder?
    var preselectedListId: UUID?

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var dueTime = Date()
    @State private var allDay = false
    @State private var priority: PRModels.Priority = .normal
    @State private var recurrenceEnabled = false
    @State private var recurrenceRule: PRModels.RecurrenceRule?
    @State private var selectedListId: UUID?
    @State private var showRecurrencePicker = false
    @State private var showListPicker = false
    @State private var showPremiumPaywall = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Available lists from SyncEngine
    private var availableLists: [ReminderList] {
        let lists = SyncEngine.shared.reminderLists
        return lists.isEmpty ? [ReminderList.createDefault()] : lists
    }

    private let graphQL = GraphQLClient.shared
    private var isEditing: Bool { editingReminder != nil }

    private var selectedList: ReminderList? {
        availableLists.first { $0.id == selectedListId }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    TextField("Reminder title", text: $title)
                        .font(Theme.Typography.headline)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Date & Time section
                Section("When") {
                    Toggle("All day", isOn: $allDay)

                    DatePicker(
                        "Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )

                    if !allDay {
                        DatePicker(
                            "Time",
                            selection: $dueTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // Recurrence section
                Section("Repeat") {
                    Toggle("Repeat", isOn: $recurrenceEnabled)

                    if recurrenceEnabled {
                        Button {
                            showRecurrencePicker = true
                        } label: {
                            HStack {
                                Text("Frequency")
                                Spacer()
                                Text(recurrenceRule?.displayString ?? "Daily")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)

                        // Premium badge for advanced recurrence
                        if let rule = recurrenceRule, isAdvancedRecurrence(rule) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Premium feature")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Priority section
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(PRModels.Priority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(colorForPriority(p))
                                    .frame(width: 8, height: 8)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // List section
                Section("List") {
                    Button {
                        showListPicker = true
                    } label: {
                        HStack {
                            if let list = selectedList {
                                Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                                    .foregroundStyle(list.color)
                                Text(list.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select List")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(Theme.Typography.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(isEditing ? "Save" : "Add") {
                            if isEditing {
                                updateReminder()
                            } else {
                                createReminder()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showRecurrencePicker) {
                RecurrencePickerView(rule: $recurrenceRule)
            }
            .sheet(isPresented: $showPremiumPaywall) {
                PremiumView()
            }
            .sheet(isPresented: $showListPicker) {
                ListPickerSheet(
                    lists: availableLists,
                    selectedListId: $selectedListId
                )
                .presentationDetents([.medium])
            }
            .onAppear {
                loadExistingReminder()
                // Set preselected list if provided
                if let preselectedListId {
                    selectedListId = preselectedListId
                } else if selectedListId == nil {
                    // Default to first list
                    selectedListId = availableLists.first?.id
                }
            }
            .onChange(of: recurrenceEnabled) { _, newValue in
                if newValue && recurrenceRule == nil {
                    // Set a default recurrence rule when toggle is enabled
                    recurrenceRule = PRModels.RecurrenceRule(frequency: .daily, interval: 1)
                }
            }
        }
    }

    private func loadExistingReminder() {
        guard let reminder = editingReminder else { return }
        title = reminder.title
        notes = reminder.notes ?? ""
        dueDate = reminder.dueAt
        dueTime = reminder.dueAt
        allDay = reminder.allDay
        priority = reminder.priority
        recurrenceEnabled = reminder.recurrenceRule != nil
        recurrenceRule = reminder.recurrenceRule
        selectedListId = reminder.listId
    }

    private func colorForPriority(_ priority: PRModels.Priority) -> Color {
        switch priority {
        case .high: return Theme.Colors.priorityHigh
        case .normal: return Theme.Colors.priorityNormal
        case .low: return Theme.Colors.priorityLow
        case .none: return Theme.Colors.priorityNone
        }
    }

    private func isAdvancedRecurrence(_ rule: PRModels.RecurrenceRule) -> Bool {
        // Advanced recurrence: hourly, or with custom days of week, or interval > 1
        return rule.frequency == .hourly ||
               rule.daysOfWeek != nil ||
               rule.interval > 1
    }

    private func createReminder() {
        // Combine date and time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        if !allDay {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
        }
        let finalDueDate = calendar.date(from: components) ?? dueDate

        // Check premium for advanced recurrence
        if let rule = recurrenceRule, isAdvancedRecurrence(rule), !subscriptionViewModel.isPremium {
            showPremiumPaywall = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Use selected list ID or default list ID
                let listIdToUse = selectedListId ?? availableLists.first(where: { $0.isDefault })?.id ?? availableLists.first?.id

                let input = PRAPI.CreateReminderInput(
                    listId: listIdToUse.map { .some($0.uuidString.lowercased()) } ?? .null,
                    title: title,
                    notes: notes.isEmpty ? .null : .some(notes),
                    priority: .some(.init(graphQLPriority(from: priority))),
                    dueAt: iso8601String(from: finalDueDate),
                    allDay: allDay,
                    recurrenceRule: recurrenceEnabled && recurrenceRule != nil
                        ? .some(graphQLRecurrenceRuleInput(from: recurrenceRule!))
                        : .null
                )

                let mutation = PRAPI.CreateReminderMutation(input: input)
                print("✨ CreateReminderView: Performing mutation with listId: \(listIdToUse?.uuidString ?? "nil")...")
                let result = try await graphQL.perform(mutation: mutation)
                print("✨ CreateReminderView: Mutation completed, reminder id: \(result.createReminder.id)")

                await MainActor.run {
                    Haptics.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create reminder: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateReminder() {
        guard let reminder = editingReminder else { return }

        // Combine date and time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        if !allDay {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
        }
        let finalDueDate = calendar.date(from: components) ?? dueDate

        // Check premium for advanced recurrence
        if let rule = recurrenceRule, isAdvancedRecurrence(rule), !subscriptionViewModel.isPremium {
            showPremiumPaywall = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let input = PRAPI.UpdateReminderInput(
                    listId: selectedListId.map { .some($0.uuidString.lowercased()) } ?? .null,
                    title: .some(title),
                    notes: notes.isEmpty ? .null : .some(notes),
                    priority: .some(.init(graphQLPriority(from: priority))),
                    dueAt: .some(iso8601String(from: finalDueDate)),
                    allDay: .some(allDay),
                    recurrenceRule: recurrenceEnabled && recurrenceRule != nil
                        ? .some(graphQLRecurrenceRuleInput(from: recurrenceRule!))
                        : .null
                )

                let mutation = PRAPI.UpdateReminderMutation(
                    id: reminder.id.uuidString.lowercased(),
                    input: input
                )
                _ = try await graphQL.perform(mutation: mutation)

                await MainActor.run {
                    Haptics.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update reminder: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - GraphQL Type Conversions

    private func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func graphQLPriority(from priority: PRModels.Priority) -> PRAPI.Priority {
        switch priority {
        case .none: return .none
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        }
    }

    private func graphQLFrequency(from frequency: PRModels.Frequency) -> PRAPI.Frequency {
        switch frequency {
        case .hourly: return .hourly
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }

    private func graphQLRecurrenceRuleInput(from rule: PRModels.RecurrenceRule) -> PRAPI.RecurrenceRuleInput {
        PRAPI.RecurrenceRuleInput(
            frequency: .init(graphQLFrequency(from: rule.frequency)),
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek != nil ? .some(rule.daysOfWeek!) : .null,
            dayOfMonth: rule.dayOfMonth != nil ? .some(rule.dayOfMonth!) : .null,
            monthOfYear: rule.monthOfYear != nil ? .some(rule.monthOfYear!) : .null,
            endAfterOccurrences: rule.endAfterOccurrences != nil ? .some(rule.endAfterOccurrences!) : .null,
            endDate: rule.endDate != nil ? .some(iso8601String(from: rule.endDate!)) : .null
        )
    }
}

// MARK: - Recurrence Picker

struct RecurrencePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rule: PRModels.RecurrenceRule?

    @State private var frequency: PRModels.Frequency = .daily
    @State private var interval = 1
    @State private var selectedDays: Set<Int> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    Picker("Repeat", selection: $frequency) {
                        ForEach(PRModels.Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)

                    Stepper("Every \(interval) \(frequencyUnit)", value: $interval, in: 1...99)
                }

                if frequency == .weekly {
                    Section("On days") {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                toggleDay(day)
                            } label: {
                                HStack {
                                    Text(dayName(for: day))
                                    Spacer()
                                    if selectedDays.contains(day) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveRule()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadExistingRule()
            }
        }
    }

    private var frequencyUnit: String {
        switch frequency {
        case .hourly: return interval == 1 ? "hour" : "hours"
        case .daily: return interval == 1 ? "day" : "days"
        case .weekly: return interval == 1 ? "week" : "weeks"
        case .monthly: return interval == 1 ? "month" : "months"
        case .yearly: return interval == 1 ? "year" : "years"
        }
    }

    private func dayName(for day: Int) -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day]
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        Haptics.selection()
    }

    private func loadExistingRule() {
        guard let existing = rule else { return }
        frequency = existing.frequency
        interval = existing.interval
        if let days = existing.daysOfWeek {
            selectedDays = Set(days)
        }
    }

    private func saveRule() {
        rule = PRModels.RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: frequency == .weekly && !selectedDays.isEmpty ? Array(selectedDays).sorted() : nil
        )
    }
}

// MARK: - List Picker Sheet

struct ListPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lists: [ReminderList]
    @Binding var selectedListId: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    Button {
                        Haptics.selection()
                        selectedListId = list.id
                        dismiss()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                                .font(.title3)
                                .foregroundStyle(list.color)
                                .frame(width: 28, height: 28)
                                .background(list.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            Text(list.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedListId == list.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateReminderView()
        .environmentObject(SubscriptionViewModel())
}
