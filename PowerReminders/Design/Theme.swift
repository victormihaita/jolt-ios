import SwiftUI

// MARK: - Power Reminders Theme
// Designed for Sam Beckman's tech-savvy audience
// Electric Cyan accent with true black dark mode

struct Theme {
    // MARK: - Colors

    struct Colors {
        // Primary - Electric Cyan
        static let primary = Color.accentColor
        static let primaryVariant = Color(hexString: "#00A5B5")

        // Secondary - Warm Coral
        static let secondary = Color(hexString: "#FF6B6B")
        static let secondaryDark = Color(hexString: "#FF8585")

        // Backgrounds
        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        static let groupedBackground = Color(uiColor: .systemGroupedBackground)

        // Surface colors for cards
        static let surface = Color("PRSurface", bundle: nil)
        static let surfaceElevated = Color("PRSurfaceElevated", bundle: nil)
        static let surfaceCard = Color("PRSurfaceCard", bundle: nil)

        // Priority colors (refined)
        static let priorityHigh = Color(hexString: "#FF4757")
        static let priorityNormal = Color(hexString: "#FFA502")
        static let priorityLow = Color(hexString: "#3742FA")
        static let priorityNone = Color(hexString: "#636E72")

        // Semantic/Status colors
        static let success = Color(hexString: "#00D9A5")
        static let warning = Color(hexString: "#FFB800")
        static let error = Color(hexString: "#FF5252")
        static let info = Color(hexString: "#4FC3F7")

        // Premium gradient (Indigo → Purple → Pink)
        static let premiumGradient = LinearGradient(
            colors: [
                Color(hexString: "#667EEA"),
                Color(hexString: "#764BA2"),
                Color(hexString: "#F093FB")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Filter card colors
        static let filterToday = Color(hexString: "#00C9E0")
        static let filterAll = Color(hexString: "#636E72")
        static let filterScheduled = Color(hexString: "#FFA502")
        static let filterCompleted = Color(hexString: "#00D9A5")
    }

    // MARK: - Typography

    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Spacing

    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    struct Shadows {
        static let subtle = ShadowStyle(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
        static let strong = ShadowStyle(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)

        static func glow(color: Color) -> ShadowStyle {
            ShadowStyle(color: color.opacity(0.3), radius: 20, x: 0, y: 4)
        }
    }

    // MARK: - Gradients

    struct Gradients {
        static func filter(for color: Color) -> LinearGradient {
            LinearGradient(
                colors: [
                    color.opacity(0.20),
                    color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static let card = LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func prShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.lg

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = Theme.CornerRadius.lg) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptic Feedback

struct Haptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Hex Extension

extension SwiftUI.Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
