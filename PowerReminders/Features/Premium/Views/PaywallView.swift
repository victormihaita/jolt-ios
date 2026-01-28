import SwiftUI
import RevenueCat
import PRSubscriptions

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

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
            .onPurchaseFailure { error in
                errorMessage = "Purchase Error:\n\nCode: \(error.code)\n\nDescription: \(error.localizedDescription)\n\nUnderlying: \(String(describing: error.userInfo))"
                showErrorAlert = true
            }
            .alert("Purchase Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
    }
}

// Type alias to avoid name collision with our wrapper
private typealias PaywallViewRC = RevenueCatUI.PaywallView

#Preview {
    PaywallView()
}
