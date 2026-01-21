import SwiftUI

public struct PRTheme {
    // MARK: - Colors

    public struct Colors {
        public static let primary = Color.blue
        public static let secondary = Color.gray
        public static let background = Color(.systemBackground)
        public static let secondaryBackground = Color(.secondarySystemBackground)

        public static let priorityHigh = Color.red
        public static let priorityNormal = Color.orange
        public static let priorityLow = Color.blue
        public static let priorityNone = Color.gray

        public static func priority(_ priority: Int) -> Color {
            switch priority {
            case 3: return priorityHigh
            case 2: return priorityNormal
            case 1: return priorityLow
            default: return priorityNone
            }
        }
    }

    // MARK: - Typography

    public struct Typography {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title.weight(.semibold)
        public static let title2 = Font.title2.weight(.semibold)
        public static let title3 = Font.title3.weight(.medium)
        public static let headline = Font.headline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let subheadline = Font.subheadline
        public static let footnote = Font.footnote
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
    }

    // MARK: - Spacing

    public struct Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    public struct CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
    }
}

// MARK: - Liquid Glass Modifier

public struct LiquidGlassModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PRTheme.CornerRadius.lg))
    }
}

public extension View {
    func liquidGlass() -> some View {
        modifier(LiquidGlassModifier())
    }
}
