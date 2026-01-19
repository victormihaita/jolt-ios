import Foundation
import RevenueCat
@_exported import RevenueCatUI
import JoltCore

public final class SubscriptionService: NSObject, ObservableObject {
    public static let shared = SubscriptionService()

    @Published public private(set) var isPremium = false
    @Published public private(set) var offerings: Offerings?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    public func configure(apiKey: String) {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self

        Task {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - User Management

    public func setUserID(_ userID: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userID)
            await updateSubscriptionStatus(customerInfo)
        } catch {
            JoltLogger.error("RevenueCat login error: \(error)", category: .subscription)
        }
    }

    public func logout() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            await updateSubscriptionStatus(customerInfo)
        } catch {
            JoltLogger.error("RevenueCat logout error: \(error)", category: .subscription)
        }
    }

    // MARK: - Subscription Status

    public func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(customerInfo)
        } catch {
            JoltLogger.error("Error fetching customer info: \(error)", category: .subscription)
        }
    }

    @MainActor
    private func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements[JoltConstants.Premium.entitlementID]?.isActive == true
    }

    // MARK: - Offerings

    public func fetchOfferings() async {
        await MainActor.run { isLoading = true }

        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offerings = offerings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Purchase

    public func purchase(_ package: Package) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                await updateSubscriptionStatus(result.customerInfo)
                await MainActor.run { isLoading = false }
                return true
            } else {
                await MainActor.run { isLoading = false }
                return false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            return false
        }
    }

    // MARK: - Restore

    public func restorePurchases() async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(customerInfo)
            await MainActor.run { isLoading = false }
            return isPremium
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            return false
        }
    }

    // MARK: - Convenience

    public var monthlyPackage: Package? {
        offerings?.current?.monthly
    }

    public var annualPackage: Package? {
        offerings?.current?.annual
    }

    public var lifetimePackage: Package? {
        offerings?.current?.lifetime
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateSubscriptionStatus(customerInfo)
        }
    }
}
