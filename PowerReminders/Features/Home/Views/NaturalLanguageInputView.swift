import SwiftUI
import PRModels

struct NaturalLanguageInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NaturalLanguageInputViewModel
    @FocusState private var isTextFieldFocused: Bool

    let onReminderCreated: (PRModels.Reminder) -> Void

    init(listId: UUID, onReminderCreated: @escaping (PRModels.Reminder) -> Void) {
        _viewModel = StateObject(wrappedValue: NaturalLanguageInputViewModel(listId: listId))
        self.onReminderCreated = onReminderCreated
    }

    var body: some View {
        ZStack {
            // Blurred background
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap - user might tap accidentally
                }

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        Haptics.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)

                Spacer()
                    .frame(height: Theme.Spacing.xl)

                // Main input area
                VStack(spacing: Theme.Spacing.lg) {
                    // Text input field
                    VStack(spacing: Theme.Spacing.sm) {
                        TextField("What do you need to remember?", text: $viewModel.inputText, axis: .vertical)
                            .font(.system(size: 24, weight: .medium))
                            .lineLimit(1...4)
                            .focused($isTextFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                submitReminder()
                            }
                            .padding(.horizontal, Theme.Spacing.lg)

                        // Hint text
                        if viewModel.inputText.isEmpty {
                            Text("Try: \"Buy milk tomorrow at 3pm #high\"")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }

                    // Parsed preview card
                    if let parsed = viewModel.parsedReminder, !viewModel.inputText.isEmpty {
                        NaturalLanguagePreviewCard(parsed: parsed)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .transition(.opacity)
                    }
                }

                Spacer()

                // Submit button
                Button(action: submitReminder) {
                    HStack(spacing: Theme.Spacing.sm) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Add Reminder")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                }
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .onAppear {
            // Auto-focus the text field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .animation(.snappy, value: viewModel.parsedReminder?.title)
        .animation(.snappy, value: viewModel.errorMessage)
    }

    private func submitReminder() {
        guard viewModel.canSubmit else { return }

        Haptics.medium()

        Task {
            if let reminder = await viewModel.createReminder() {
                Haptics.success()
                dismiss()
                // Small delay to let dismiss animation start
                try? await Task.sleep(nanoseconds: 100_000_000)
                onReminderCreated(reminder)
            }
        }
    }
}

// MARK: - Preview Card

struct NaturalLanguagePreviewCard: View {
    let parsed: ParsedReminder

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Title
            Text(parsed.title.isEmpty ? "Untitled" : parsed.title)
                .font(Theme.Typography.headline)
                .foregroundStyle(parsed.title.isEmpty ? .tertiary : .primary)

            // Metadata badges
            HStack(spacing: Theme.Spacing.sm) {
                // Due date
                if let dueDate = parsed.dueDate {
                    MetadataBadge(
                        icon: "calendar",
                        text: formattedDate(dueDate),
                        color: .blue
                    )
                } else {
                    MetadataBadge(
                        icon: "calendar",
                        text: "Today",
                        color: .secondary
                    )
                }

                // Priority
                if parsed.priority != .none {
                    MetadataBadge(
                        icon: "flag.fill",
                        text: parsed.priority.displayName,
                        color: priorityColor
                    )
                }

                // Recurrence
                if let recurrence = parsed.recurrence {
                    MetadataBadge(
                        icon: "repeat",
                        text: recurrence.displayString,
                        color: .purple
                    )
                }
            }

            // Tags
            if !parsed.tags.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(parsed.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    if parsed.tags.count > 3 {
                        Text("+\(parsed.tags.count - 3)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
    }

    private var priorityColor: Color {
        switch parsed.priority {
        case .high: return Theme.Colors.priorityHigh
        case .normal: return Theme.Colors.priorityNormal
        case .low: return Theme.Colors.priorityLow
        case .none: return Theme.Colors.priorityNone
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow, \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Metadata Badge

struct MetadataBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(Theme.Typography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NaturalLanguageInputView(listId: UUID()) { reminder in
        print("Created reminder: \(reminder.title)")
    }
}
