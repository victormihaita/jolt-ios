import SwiftUI
import RevenueCat
import JoltSubscriptions

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PaywallViewRC()
            .onPurchaseCompleted { _ in
                // Verify subscription with backend after successful purchase
                Task {
                    await RevenueCatService.shared.verifySubscriptionWithBackend()
                }
                dismiss()
            }
            .onRestoreCompleted { _ in
                // Verify subscription with backend after restore
                Task {
                    await RevenueCatService.shared.verifySubscriptionWithBackend()
                }
                dismiss()
            }
    }
}

// Type alias to avoid name collision with our wrapper
private typealias PaywallViewRC = RevenueCatUI.PaywallView

#Preview {
    PaywallView()
}
