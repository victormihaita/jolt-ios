import SwiftUI
import PRModels

struct QuickCaptureBar: View {
    @Binding var text: String
    let onSubmit: (ParsedReminder) -> Void

    @State private var parsedReminder: ParsedReminder?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input field
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                TextField("Try: 'Call mom tomorrow at 3pm'", text: $text)
                    .font(Theme.Typography.body)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        submitReminder()
                    }

                if !text.isEmpty {
                    Button(action: {
                        Haptics.light()
                        text = ""
                        parsedReminder = nil
                    }) {
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
            if let parsed = parsedReminder, !text.isEmpty {
                ParsedPreviewCard(parsed: parsed, onConfirm: submitReminder)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onChange(of: text) { _, newValue in
            withAnimation(.snappy) {
                if newValue.isEmpty {
                    parsedReminder = nil
                } else {
                    parsedReminder = NaturalLanguageParser.parse(newValue)
                }
            }
        }
    }

    private func submitReminder() {
        guard let parsed = parsedReminder, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        Haptics.success()
        onSubmit(parsed)
        text = ""
        parsedReminder = nil
        isFocused = false
    }
}

// MARK: - Parsed Preview Card

struct ParsedPreviewCard: View {
    let parsed: ParsedReminder
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(parsed.title)
                    .font(Theme.Typography.headline)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.sm) {
                    // Due date
                    if let dueDate = parsed.dueDate {
                        Label(formattedDate(dueDate), systemImage: "calendar")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Priority
                    if parsed.priority != .none {
                        Label(parsed.priority.displayName, systemImage: "flag.fill")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(priorityColor)
                    }

                    // Recurrence
                    if let recurrence = parsed.recurrence {
                        Label(recurrence.displayString, systemImage: "repeat")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Tags
                    ForEach(parsed.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onConfirm) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
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

#Preview {
    VStack {
        QuickCaptureBar(text: .constant("Call mom tomorrow at 3pm #high")) { parsed in
            print("Created: \(parsed.title)")
        }

        QuickCaptureBar(text: .constant("")) { _ in }
    }
    .padding()
}
