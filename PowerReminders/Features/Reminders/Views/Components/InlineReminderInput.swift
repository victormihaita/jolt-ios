import SwiftUI
import PRModels
import PRNetworking
import PRSync

/// Inline reminder creation component that matches the list creation UX pattern.
/// Displays as a "New Reminder" row that expands into an input field when tapped.
struct InlineReminderInput: View {
    let listId: UUID
    @Binding var isCreating: Bool
    /// When true, auto-starts in creation mode and stays focused (no cancel button).
    /// Used when the list is empty - user must create a reminder or go back.
    var autoFocus: Bool = false
    /// Theme color for the input - defaults to accent color
    var themeColor: Color = .accentColor

    @State private var inputText = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool

    private let graphQL = GraphQLClient.shared

    /// When autoFocus is enabled, we don't allow canceling - user must create or go back
    private var allowsCancel: Bool { !autoFocus }

    var body: some View {
        Group {
            if isCreating || autoFocus {
                creatorView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                NewReminderRow(themeColor: themeColor, onTap: startCreation)
            }
        }
        .onAppear {
            if autoFocus {
                // Auto-focus when in autoFocus mode (empty list)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }

    /// Inline creator view - kept in parent to ensure @FocusState works correctly with onSubmit
    private var creatorView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Priority indicator circle
            Circle()
                .fill(themeColor.opacity(0.2))
                .frame(width: 8, height: 8)

            // Text field - MUST be in same view as @FocusState for onSubmit to work reliably
            TextField("What do you need to remember?", text: $inputText)
                .font(.system(size: 16, weight: .medium))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    print("📝 TextField.onSubmit triggered!")
                    submitReminder()
                }
                .disabled(isSubmitting)

            // Cancel button - only shown when allowed (not in empty list state)
            if allowsCancel {
                Button(action: cancelCreation) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
            }

            // Submit button
            if isSubmitting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button {
                    print("📝 Checkmark button tapped!")
                    submitReminder()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isInputValid ? themeColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(!isInputValid)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeColor.opacity(0.12),
                            themeColor.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .strokeBorder(themeColor.opacity(0.2), lineWidth: 1)
        )
        .tint(themeColor)
    }

    private var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startCreation() {
        withAnimation(.snappy) {
            isCreating = true
        }
        // Delay focus to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
        }
    }

    private func cancelCreation() {
        withAnimation(.snappy) {
            isCreating = false
            inputText = ""
            isFocused = false
        }
    }

    private func submitReminder() {
        print("📝 InlineReminderInput.submitReminder() called")
        print("📝 inputText: '\(inputText)'")

        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            print("📝 Input is empty, canceling")
            // Only cancel if we allow it (not in autoFocus mode)
            if allowsCancel {
                cancelCreation()
            }
            return
        }

        print("📝 Setting isSubmitting = true")
        isSubmitting = true
        // Dismiss keyboard immediately to prevent any focus-related issues
        isFocused = false

        // Parse natural language for date/time/priority
        let parsed = NaturalLanguageParser.parse(trimmedInput)
        print("📝 Parsed title: '\(parsed.title)', dueDate: \(String(describing: parsed.dueDate))")

        Task {
            do {
                print("📝 Creating reminder input for listId: \(listId.uuidString.lowercased())")
                let input = PRAPI.CreateReminderInput(
                    listId: .some(listId.uuidString.lowercased()),
                    title: parsed.title.isEmpty ? trimmedInput : parsed.title,
                    notes: .null,
                    priority: .some(.init(graphQLPriority(from: parsed.priority))),
                    dueAt: parsed.dueDate.map { .some(iso8601String(from: $0)) } ?? .null,
                    allDay: parsed.dueDate != nil ? .some(!parsed.hasSpecificTime) : .null,
                    recurrenceRule: parsed.recurrence.map { .some(graphQLRecurrenceRuleInput(from: $0)) } ?? .null,
                    isAlarm: .null,
                    soundId: parsed.dueDate != nil ? .some(NotificationSoundSettings.shared.selectedSound) : .null
                )

                print("📝 Performing CreateReminderMutation...")
                let mutation = PRAPI.CreateReminderMutation(input: input)
                let result = try await graphQL.perform(mutation: mutation)
                print("📝 Mutation succeeded! Reminder ID: \(result.createReminder.id)")

                // Trigger SyncEngine to refetch reminders so the list updates immediately
                print("📝 Triggering SyncEngine.refetch()")
                SyncEngine.shared.refetch()

                await MainActor.run {
                    print("📝 Clearing input and resetting state")
                    Haptics.success()
                    isSubmitting = false
                    inputText = ""
                    // If autoFocus mode (empty list), keep focused for quick entry
                    // Otherwise, collapse the input
                    if autoFocus {
                        print("📝 autoFocus mode - keeping focused")
                        isFocused = true
                    } else {
                        print("📝 Normal mode - collapsing input")
                        isCreating = false
                    }
                }
            } catch {
                print("📝 ERROR: Failed to create reminder: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    Haptics.error()
                    print("Failed to create reminder: \(error)")
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

// MARK: - New Reminder Row (Collapsed State)

private struct NewReminderRow: View {
    let themeColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Plus icon in circle
                ZStack {
                    Circle()
                        .strokeBorder(themeColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeColor)
                }

                Text("New Reminder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeColor)

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(themeColor.opacity(0.3))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var isCreating = false
    VStack(spacing: Theme.Spacing.md) {
        InlineReminderInput(listId: UUID(), isCreating: $isCreating, themeColor: .blue)

        // Preview the creating state with different colors
        InlineReminderInput(listId: UUID(), isCreating: .constant(true), themeColor: .orange)

        InlineReminderInput(listId: UUID(), isCreating: .constant(true), themeColor: .purple)
    }
    .padding()
}
