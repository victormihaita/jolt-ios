import Foundation
import SwiftUI
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isPremium = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Subscription products (fallback prices - actual prices fetched from RevenueCat)
    @Published var monthlyPrice: String = "$4.99"
    @Published var yearlyPrice: String = "$29.99"
    @Published var lifetimePrice: String = "$79.99"

    // Premium feature limits
    static let freeDeviceLimit = 2
    static let freeSnoozeOptions = [5, 15, 30] // minutes

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to RevenueCatService's premium status updates
        RevenueCatService.shared.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.isPremium = isPremium
            }
            .store(in: &cancellables)

        // Initial check
        checkSubscriptionStatus()
    }

    func checkSubscriptionStatus() {
        // Sync with RevenueCat service
        isPremium = RevenueCatService.shared.isPremium

        // Also verify with backend
        Task {
            await RevenueCatService.shared.verifySubscriptionWithBackend()
        }
    }

    func purchaseMonthly() async {
        isLoading = true
        defer { isLoading = false }

        if let package = RevenueCatService.shared.monthlyPackage {
            _ = await RevenueCatService.shared.purchase(package)
        }
    }

    func purchaseYearly() async {
        isLoading = true
        defer { isLoading = false }

        if let package = RevenueCatService.shared.annualPackage {
            _ = await RevenueCatService.shared.purchase(package)
        }
    }

    func purchaseLifetime() async {
        isLoading = true
        defer { isLoading = false }

        if let package = RevenueCatService.shared.lifetimePackage {
            _ = await RevenueCatService.shared.purchase(package)
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        _ = await RevenueCatService.shared.restorePurchases()
    }

    // MARK: - Feature Gating

    func canUseCustomSnooze() -> Bool {
        return isPremium
    }

    func canUseAdvancedRecurrence() -> Bool {
        return isPremium
    }

    func canAddDevice(currentCount: Int) -> Bool {
        return isPremium || currentCount < Self.freeDeviceLimit
    }

    func canUsePremiumSound(_ soundId: String) -> Bool {
        let premiumSounds = ["crystal", "zen_bowl", "nature_bird", "piano_note"]
        return isPremium || !premiumSounds.contains(soundId)
    }
}
