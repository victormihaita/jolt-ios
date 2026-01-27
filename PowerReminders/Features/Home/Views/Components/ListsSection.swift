import SwiftUI
import PRModels
import PRSync

struct ListsSection: View {
    let lists: [ReminderList]
    let reminderCountForList: (ReminderList) -> Int
    let namespace: Namespace.ID
    let onListTap: (ReminderList) -> Void
    let onCreateList: (String, String, String) -> Void
    let onDeleteList: (ReminderList) -> Void
    @Binding var isCreatingList: Bool
    @Binding var isEditingList: Bool

    // Create new list state
    @State private var newListName = ""
    @State private var newListColorHex = ReminderList.presetColors[0]
    @State private var newListIconName = ReminderList.presetIcons[0]
    @FocusState private var isNameFieldFocused: Bool

    // Edit list state
    @State private var listBeingEdited: ReminderList?
    @State private var editName = ""
    @State private var editColorHex = ""
    @State private var editIconName = ""
    @FocusState private var isEditFieldFocused: Bool
    @State private var isSubmittingEdit = false

    /// Calculate the minimum height needed for the list
    /// Each card is ~68pt, inline creator/editor is ~68pt
    private var listMinHeight: CGFloat {
        let rowHeight: CGFloat = 68
        let spacing: CGFloat = 8
        let itemCount = lists.count + 1 // +1 for new list button/creator
        let baseHeight = CGFloat(itemCount) * (rowHeight + spacing)
        // Add extra padding to ensure last item is fully visible
        return baseHeight + 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                Text("My Lists")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // List items with swipe actions
            List {
                ForEach(lists) { list in
                    if listBeingEdited?.id == list.id {
                        // Show inline editor for this list
                        InlineListEditor(
                            name: $editName,
                            colorHex: $editColorHex,
                            iconName: $editIconName,
                            isFocused: $isEditFieldFocused,
                            isSubmitting: isSubmittingEdit,
                            onSave: { submitEdit() },
                            onCancel: cancelEditing
                        )
                        .id("listRow-\(list.id.uuidString)")
                        .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: 0, bottom: Theme.Spacing.xs, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // Show normal list card
                        ListCard(
                            list: list,
                            count: reminderCountForList(list),
                            namespace: namespace,
                            onTap: {
                                onListTap(list)
                            }
                        )
                        .id("listRow-\(list.id.uuidString)")
                        .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: 0, bottom: Theme.Spacing.xs, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if !list.isDefault {
                                Button(role: .destructive) {
                                    Haptics.medium()
                                    onDeleteList(list)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if !list.isDefault {
                                Button {
                                    Haptics.light()
                                    startEditing(list)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
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
                    .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: 0, bottom: Theme.Spacing.xs, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    NewListCard(namespace: namespace) {
                        startCreation()
                    }
                    .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: 0, bottom: Theme.Spacing.xs, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(minHeight: listMinHeight)
            .environment(\.defaultMinListRowHeight, 10)
            .onChange(of: isNameFieldFocused) { _, isFocused in
                if !isFocused && isCreatingList {
                    cancelCreation()
                }
            }
            .onChange(of: isEditFieldFocused) { _, isFocused in
                if !isFocused && listBeingEdited != nil && !isSubmittingEdit {
                    cancelEditing()
                }
            }
        }
    }

    // MARK: - Create New List

    private func startCreation() {
        // Cancel any editing in progress
        cancelEditing()

        isCreatingList = true
        isNameFieldFocused = true
    }

    private func cancelCreation() {
        isCreatingList = false
        newListName = ""
        newListColorHex = ReminderList.presetColors[0]
        newListIconName = ReminderList.presetIcons[0]
        isNameFieldFocused = false
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

    // MARK: - Edit List

    private func startEditing(_ list: ReminderList) {
        // Cancel any creation in progress
        cancelCreation()

        listBeingEdited = list
        editName = list.name
        editColorHex = list.colorHex
        editIconName = list.iconName
        isEditingList = true
        isEditFieldFocused = true
    }

    private func cancelEditing() {
        listBeingEdited = nil
        editName = ""
        editColorHex = ""
        editIconName = ""
        isEditFieldFocused = false
        isSubmittingEdit = false
        isEditingList = false
    }

    private func submitEdit() {
        guard let list = listBeingEdited else { return }
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            cancelEditing()
            return
        }

        // Check if anything actually changed
        let hasChanges = trimmedName != list.name ||
                        editColorHex != list.colorHex ||
                        editIconName != list.iconName

        guard hasChanges else {
            cancelEditing()
            return
        }

        isSubmittingEdit = true
        isEditFieldFocused = false

        Task {
            do {
                _ = try await SyncEngine.shared.updateList(
                    id: list.id,
                    name: trimmedName,
                    colorHex: editColorHex,
                    iconName: editIconName
                )
                await MainActor.run {
                    Haptics.success()
                    cancelEditing()
                }
            } catch {
                await MainActor.run {
                    Haptics.error()
                    isSubmittingEdit = false
                    // Keep the editor open on error so user can retry
                }
                print("Failed to update list: \(error)")
            }
        }
    }
}

// MARK: - Inline List Editor

private struct InlineListEditor: View {
    @Binding var name: String
    @Binding var colorHex: String
    @Binding var iconName: String
    var isFocused: FocusState<Bool>.Binding
    let isSubmitting: Bool
    let onSave: () -> Void
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
                .onSubmit(onSave)
                .tint(selectedColor)
                .disabled(isSubmitting)

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
            .disabled(isSubmitting)
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
            .disabled(isSubmitting)
            .popover(isPresented: $showIconPicker) {
                IconPickerPopover(selectedIconName: $iconName, selectedColor: selectedColor)
                    .presentationCompactAdaptation(.popover)
            }

            // Save button
            if isSubmitting {
                ProgressView()
                    .frame(width: 28, height: 28)
            } else {
                Button(action: onSave) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isValid ? selectedColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
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

// MARK: - List Card

private struct ListCard: View {
    let list: ReminderList
    let count: Int
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: Theme.Spacing.md) {
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
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
    @Previewable @State var isEditing = false
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
            isCreatingList: $isCreating,
            isEditingList: $isEditing
        )
        .padding()
    }
}
