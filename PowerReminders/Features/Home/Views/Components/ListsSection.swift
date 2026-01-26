import SwiftUI
import PRModels

struct ListsSection: View {
    let lists: [ReminderList]
    let reminderCountForList: (ReminderList) -> Int
    let namespace: Namespace.ID
    let onListTap: (ReminderList) -> Void
    let onCreateList: (String, String, String) -> Void
    let onDeleteList: (ReminderList) -> Void
    @Binding var isCreatingList: Bool

    @State private var isEditMode = false
    @State private var newListName = ""
    @State private var newListColorHex = ReminderList.presetColors[0]
    @State private var newListIconName = ReminderList.presetIcons[0]
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                Text("My Lists")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    Haptics.light()
                    withAnimation(.snappy) {
                        isEditMode.toggle()
                    }
                }) {
                    Text(isEditMode ? "Done" : "Edit")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // List items as individual cards
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(lists) { list in
                    ListCard(
                        list: list,
                        count: reminderCountForList(list),
                        isEditMode: isEditMode,
                        namespace: namespace,
                        onTap: {
                            cancelCreation()
                            onListTap(list)
                        },
                        onDelete: { onDeleteList(list) }
                    )
                }

                // New List creation row or button
                if isCreatingList {
                    InlineListCreator(
                        name: $newListName,
                        colorHex: $newListColorHex,
                        iconName: $newListIconName,
                        isFocused: $isNameFieldFocused,
                        onSubmit: submitNewList,
                        onCancel: cancelCreation
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    NewListCard(namespace: namespace) {
                        startCreation()
                    }
                }
            }
        }
    }

    private func startCreation() {
        withAnimation(.snappy) {
            isCreatingList = true
        }
        // Delay focus to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNameFieldFocused = true
        }
    }

    private func cancelCreation() {
        withAnimation(.snappy) {
            isCreatingList = false
            newListName = ""
            newListColorHex = ReminderList.presetColors[0]
            newListIconName = ReminderList.presetIcons[0]
            isNameFieldFocused = false
        }
    }

    private func submitNewList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            cancelCreation()
            return
        }

        Haptics.success()
        onCreateList(trimmedName, newListColorHex, newListIconName)
        cancelCreation()
    }
}

// MARK: - Inline List Creator

private struct InlineListCreator: View {
    @Binding var name: String
    @Binding var colorHex: String
    @Binding var iconName: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var showColorPicker = false
    @State private var showIconPicker = false

    private var selectedColor: Color {
        Color(hex: colorHex) ?? .blue
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon preview
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [selectedColor, selectedColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: iconName.isEmpty ? "list.bullet" : iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Name text field
            TextField("List name", text: $name)
                .font(.system(size: 17, weight: .medium))
                .focused(isFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .tint(selectedColor)

            // Color picker button
            Button(action: {
                Haptics.light()
                showColorPicker = true
            }) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showColorPicker) {
                ColorPickerPopover(selectedColorHex: $colorHex)
                    .presentationCompactAdaptation(.popover)
            }

            // Icon picker button
            Button(action: {
                Haptics.light()
                showIconPicker = true
            }) {
                Image(systemName: iconName.isEmpty ? "list.bullet" : iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selectedColor)
                    .frame(width: 28, height: 28)
                    .background(selectedColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showIconPicker) {
                IconPickerPopover(selectedIconName: $iconName, selectedColor: selectedColor)
                    .presentationCompactAdaptation(.popover)
            }

            // Done button
            Button(action: onSubmit) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isValid ? selectedColor : Color.secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            selectedColor.opacity(0.12),
                            selectedColor.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .strokeBorder(selectedColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Color Picker Popover

private struct ColorPickerPopover: View {
    @Binding var selectedColorHex: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 40), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Color")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(ReminderList.presetColors, id: \.self) { colorHex in
                    Button(action: {
                        Haptics.selection()
                        selectedColorHex = colorHex
                        dismiss()
                    }) {
                        Circle()
                            .fill(Color(hex: colorHex) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay {
                                if selectedColorHex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 220)
    }
}

// MARK: - Icon Picker Popover

private struct IconPickerPopover: View {
    @Binding var selectedIconName: String
    let selectedColor: Color
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 40), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Icon")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(ReminderList.presetIcons, id: \.self) { iconName in
                    Button(action: {
                        Haptics.selection()
                        selectedIconName = iconName
                        dismiss()
                    }) {
                        Image(systemName: iconName)
                            .font(.body)
                            .foregroundStyle(selectedIconName == iconName ? .white : selectedColor)
                            .frame(width: 40, height: 40)
                            .background(
                                selectedIconName == iconName
                                    ? selectedColor
                                    : selectedColor.opacity(0.15)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 220)
    }
}

// MARK: - List Card

private struct ListCard: View {
    let list: ReminderList
    let count: Int
    let isEditMode: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: {
            guard !isEditMode else { return }
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Delete button (edit mode)
                if isEditMode && !list.isDefault {
                    Button(action: {
                        Haptics.medium()
                        onDelete()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                // List icon with colored background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    list.color,
                                    list.color.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                // List name
                Text(list.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                // Reminder count badge
                Text("\(count)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())

                // Chevron
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                list.color.opacity(0.08),
                                list.color.opacity(0.03)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .strokeBorder(list.color.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(MatchedTransitionSourceModifier(id: "list-\(list.id.uuidString)", namespace: namespace))
    }
}

// MARK: - New List Card

private struct NewListCard: View {
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Plus icon
                ZStack {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 36, height: 36)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text("New List")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(Color.secondary.opacity(0.3))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(MatchedTransitionSourceModifier(id: "newList", namespace: namespace))
    }
}

#Preview {
    @Previewable @Namespace var namespace
    @Previewable @State var isCreating = false
    ScrollView {
        ListsSection(
            lists: [
                ReminderList.createDefault(),
                ReminderList(name: "Work", colorHex: "#34C759", iconName: "briefcase.fill"),
                ReminderList(name: "Personal", colorHex: "#AF52DE", iconName: "heart.fill"),
                ReminderList(name: "Shopping", colorHex: "#FF9500", iconName: "cart.fill"),
                ReminderList(name: "Health", colorHex: "#FF2D55", iconName: "heart.text.square.fill")
            ],
            reminderCountForList: { _ in Int.random(in: 0...10) },
            namespace: namespace,
            onListTap: { _ in },
            onCreateList: { name, color, icon in
                print("Create list: \(name), \(color), \(icon)")
            },
            onDeleteList: { _ in },
            isCreatingList: $isCreating
        )
        .padding()
    }
}
