import SwiftUI

// This ViewModifier is no longer used — the notification banner is now displayed
// via OverlayWindowManager using a dedicated UIWindow above all app content.
// Kept to avoid Xcode project file churn.

struct NotificationBannerOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func notificationBannerOverlay() -> some View {
        modifier(NotificationBannerOverlay())
    }
}
