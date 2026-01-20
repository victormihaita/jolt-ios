import Foundation

public struct ReminderList: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var sortOrder: Int
    public var isDefault: Bool
    public var reminderCount: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "list.bullet",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        reminderCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.reminderCount = reminderCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Creates the default "Reminders" list that cannot be deleted
    public static func createDefault() -> ReminderList {
        ReminderList(
            name: "Reminders",
            colorHex: "#007AFF",
            iconName: "list.bullet",
            sortOrder: 0,
            isDefault: true
        )
    }
}

// MARK: - Preset Colors

public extension ReminderList {
    /// Preset colors for list customization
    static let presetColors: [String] = [
        "#007AFF", // Blue (default)
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#00C7BE", // Teal
        "#FFCC00", // Yellow
        "#8E8E93"  // Gray
    ]

    /// Preset icons for list customization
    static let presetIcons: [String] = [
        "list.bullet",
        "briefcase.fill",
        "house.fill",
        "heart.fill",
        "cart.fill",
        "book.fill",
        "airplane",
        "figure.run",
        "leaf.fill",
        "star.fill",
        "gift.fill",
        "lightbulb.fill"
    ]
}

// MARK: - Color Helpers

import SwiftUI

public extension ReminderList {
    /// Returns the SwiftUI Color from the hex string
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

public extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
