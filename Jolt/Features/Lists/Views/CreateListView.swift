import SwiftUI
import JoltModels

struct CreateListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColorHex: String = ReminderList.presetColors[0]
    @State private var selectedIconName: String = ReminderList.presetIcons[0]

    let onSave: (String, String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        listPreview
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // Name
                Section("Name") {
                    TextField("List Name", text: $name)
                        .font(Theme.Typography.body)
                }

                // Color Picker
                Section("Color") {
                    ListColorPicker(
                        selectedColorHex: $selectedColorHex,
                        colors: ReminderList.presetColors
                    )
                }

                // Icon Picker
                Section("Icon") {
                    ListIconPicker(
                        selectedIconName: $selectedIconName,
                        icons: ReminderList.presetIcons,
                        selectedColor: Color(hex: selectedColorHex) ?? .blue
                    )
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.success()
                        onSave(name, selectedColorHex, selectedIconName)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var listPreview: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: selectedIconName)
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: selectedColorHex) ?? .blue)
                .frame(width: 80, height: 80)
                .background((Color(hex: selectedColorHex) ?? .blue).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))

            Text(name.isEmpty ? "List Name" : name)
                .font(Theme.Typography.headline)
                .foregroundStyle(name.isEmpty ? .secondary : .primary)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Color Picker

struct ListColorPicker: View {
    @Binding var selectedColorHex: String
    let colors: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(colors, id: \.self) { colorHex in
                Button(action: {
                    Haptics.selection()
                    selectedColorHex = colorHex
                }) {
                    Circle()
                        .fill(Color(hex: colorHex) ?? .blue)
                        .frame(width: 44, height: 44)
                        .overlay {
                            if selectedColorHex == colorHex {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Icon Picker

struct ListIconPicker: View {
    @Binding var selectedIconName: String
    let icons: [String]
    let selectedColor: Color

    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(icons, id: \.self) { iconName in
                Button(action: {
                    Haptics.selection()
                    selectedIconName = iconName
                }) {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(selectedIconName == iconName ? .white : selectedColor)
                        .frame(width: 44, height: 44)
                        .background(selectedIconName == iconName ? selectedColor : selectedColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    CreateListView { name, color, icon in
        print("Created list: \(name) with color \(color) and icon \(icon)")
    }
}
