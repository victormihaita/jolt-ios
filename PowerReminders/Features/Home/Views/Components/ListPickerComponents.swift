import SwiftUI
import PRModels

// MARK: - Color Picker Popover

struct ColorPickerPopover: View {
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

struct IconPickerPopover: View {
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
