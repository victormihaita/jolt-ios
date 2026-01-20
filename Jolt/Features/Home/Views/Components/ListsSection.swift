import SwiftUI
import JoltModels

struct ListsSection: View {
    let lists: [ReminderList]
    let reminderCountForList: (ReminderList) -> Int
    let namespace: Namespace.ID
    let onListTap: (ReminderList) -> Void
    let onNewListTap: () -> Void
    let onDeleteList: (ReminderList) -> Void

    @State private var isEditMode = false

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
            .padding(.horizontal, Theme.Spacing.md)

            // List items
            VStack(spacing: 0) {
                ForEach(lists) { list in
                    ListRow(
                        list: list,
                        count: reminderCountForList(list),
                        isEditMode: isEditMode,
                        namespace: namespace,
                        onTap: { onListTap(list) },
                        onDelete: { onDeleteList(list) }
                    )

                    if list.id != lists.last?.id {
                        Divider()
                            .padding(.leading, Theme.Spacing.xl + Theme.Spacing.md)
                    }
                }

                Divider()
                    .padding(.leading, Theme.Spacing.xl + Theme.Spacing.md)

                // New List button
                Button(action: {
                    Haptics.light()
                    onNewListTap()
                }) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28, height: 28)

                        Text("New List")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Color.accentColor)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: "newList", in: namespace)
            }
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
        }
    }
}

// MARK: - List Row

private struct ListRow: View {
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
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                // List icon with color
                Image(systemName: list.iconName.isEmpty ? "list.bullet" : list.iconName)
                    .font(.title3)
                    .foregroundStyle(list.color)
                    .frame(width: 28, height: 28)
                    .background(list.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                // List name
                Text(list.name)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.primary)

                Spacer()

                // Reminder count
                Text("\(count)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)

                // Chevron
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: "list-\(list.id.uuidString)", in: namespace)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    ListsSection(
        lists: [
            ReminderList.createDefault(),
            ReminderList(name: "Work", colorHex: "#34C759", iconName: "briefcase.fill"),
            ReminderList(name: "Personal", colorHex: "#AF52DE", iconName: "heart.fill")
        ],
        reminderCountForList: { _ in Int.random(in: 0...10) },
        namespace: namespace,
        onListTap: { _ in },
        onNewListTap: {},
        onDeleteList: { _ in }
    )
    .padding()
}
