import SwiftUI
import PRModels

struct OnboardingCreateReminderView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    private let exampleReminders = [
        "Call mom tomorrow at 3pm",
        "Water plants every Monday",
        "Buy groceries #high",
        "Meeting next Friday at 10am"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.accentColor)

                        Text("Create your first reminder")
                            .font(Theme.Typography.largeTitle)
                            .multilineTextAlignment(.center)

                        Text("Type naturally \u{2014} we'll handle the rest")
                            .font(Theme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Theme.Spacing.xxl)

                    // Input field
                    VStack(spacing: 0) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)

                            TextField("Try: 'Call mom tomorrow at 3pm'", text: $viewModel.reminderInput)
                                .font(Theme.Typography.body)
                                .focused($isFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    if viewModel.parsedReminder != nil {
                                        saveAndContinue()
                                    }
                                }

                            if !viewModel.reminderInput.isEmpty {
                                Button {
                                    Haptics.light()
                                    viewModel.reminderInput = ""
                                    viewModel.parsedReminder = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))

                        // Parsed preview
                        if let parsed = viewModel.parsedReminder, !viewModel.reminderInput.isEmpty {
                            OnboardingParsedPreview(parsed: parsed)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .onChange(of: viewModel.reminderInput) { _, newValue in
                        withAnimation(.snappy) {
                            viewModel.parseInput(newValue)
                        }
                    }

                    // Example chips
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Try these examples:")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: Theme.Spacing.sm) {
                            ForEach(exampleReminders, id: \.self) { example in
                                Button {
                                    Haptics.light()
                                    viewModel.reminderInput = example
                                    viewModel.parseInput(example)
                                } label: {
                                    Text(example)
                                        .font(Theme.Typography.caption)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(Theme.Colors.secondaryBackground)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }

            // Bottom buttons
            VStack(spacing: Theme.Spacing.md) {
                Button {
                    saveAndContinue()
                } label: {
                    Text("Save & Continue")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.parsedReminder != nil ? Color.accentColor : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                }
                .disabled(viewModel.parsedReminder == nil)

                Button {
                    viewModel.advanceToStep(.notifications)
                } label: {
                    Text("Skip")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 48)
        }
    }

    private func saveAndContinue() {
        Haptics.success()
        viewModel.saveReminderLocally()
        isFocused = false
        viewModel.advanceToStep(.notifications)
    }
}

// MARK: - Onboarding Parsed Preview

private struct OnboardingParsedPreview: View {
    let parsed: ParsedReminder

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(parsed.title)
                .font(Theme.Typography.headline)
                .lineLimit(2)

            HStack(spacing: Theme.Spacing.sm) {
                if let dueDate = parsed.dueDate {
                    Label(formattedDate(dueDate), systemImage: "calendar")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                if parsed.priority != .none {
                    Label(parsed.priority.displayName, systemImage: "flag.fill")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(priorityColor)
                }

                if let recurrence = parsed.recurrence {
                    Label(recurrence.displayString, systemImage: "repeat")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(parsed.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
        .padding(.top, Theme.Spacing.xs)
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
