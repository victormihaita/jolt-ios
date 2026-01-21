import Foundation
import RevenueCat
import PRNetworking

/// RevenueCatService handles all subscription and in-app purchase logic
class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var currentSubscription: CustomerInfo?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Whether RevenueCat has been configured
    private var isConfigured: Bool = false

    // Product identifiers
    enum ProductID {
        static let monthlySubscription = "monthly"
        static let yearlySubscription = "yearly"
        static let lifetimeAccess = "lifetime"
    }

    // Entitlement identifier
    private let premiumEntitlementID = "PR Pro"

    private override init() {
        super.init()
    }

    /// Configure RevenueCat with your API key
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        // RevenueCat API key
        let apiKey = "test_KrWrpjWEMFsyKSvqOLTDITucsbf"

        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true

        // Listen for customer info updates
        Purchases.shared.delegate = self

        // Fetch initial customer info
        Task {
            await checkSubscriptionStatus()
        }
    }

    /// Set the user ID after authentication
    func setUserID(_ userID: String) async {
        guard isConfigured else { return }
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userID)
            await updateSubscriptionStatus(customerInfo)
        } catch {
            print("RevenueCat login error: \(error)")
        }
    }

    /// Clear user ID on logout
    func logout() async {
        guard isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.logOut()
            await updateSubscriptionStatus(customerInfo)
        } catch {
            print("RevenueCat logout error: \(error)")
        }
    }

    /// Check current subscription status
    func checkSubscriptionStatus() async {
        guard isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(customerInfo)
        } catch {
            print("Error fetching customer info: \(error)")
        }
    }

    @MainActor
    private func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        self.currentSubscription = customerInfo
        self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
    }

    /// Fetch available offerings
    func fetchOfferings() async {
        guard isConfigured else {
            await MainActor.run {
                self.errorMessage = "Purchases not configured"
                self.isLoading = false
            }
            return
        }

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

    /// Purchase a package
    func purchase(_ package: Package) async -> Bool {
        guard isConfigured else { return false }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                await updateSubscriptionStatus(result.customerInfo)

                // Verify subscription with backend to sync premium status
                await verifySubscriptionWithBackend()

                await MainActor.run { isLoading = false }
                return true
            } else {
                await MainActor.run { isLoading = false }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        guard isConfigured else { return false }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(customerInfo)

            // Verify subscription with backend to sync premium status
            await verifySubscriptionWithBackend()

            await MainActor.run { isLoading = false }
            return isPremium
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    /// Verify subscription status with the backend
    /// This syncs the RevenueCat subscription status with the backend database
    func verifySubscriptionWithBackend() async {
        // Only verify with backend if user is authenticated
        guard KeychainService.shared.getToken() != nil else {
            print("⏭️ Skipping backend verification - user not authenticated")
            return
        }

        do {
            let mutation = PRAPI.VerifySubscriptionMutation()
            let result = try await GraphQLClient.shared.perform(mutation: mutation)

            await MainActor.run {
                self.isPremium = result.verifySubscription.isPremium
            }

            print("✅ Subscription verified with backend: isPremium=\(result.verifySubscription.isPremium)")
        } catch {
            print("⚠️ Failed to verify subscription with backend: \(error)")
            // Don't fail silently - the local RevenueCat status is still valid
        }
    }

    /// Get the current offering's monthly package
    var monthlyPackage: Package? {
        offerings?.current?.monthly
    }

    /// Get the current offering's annual package
    var annualPackage: Package? {
        offerings?.current?.annual
    }

    /// Get the current offering's lifetime package
    var lifetimePackage: Package? {
        offerings?.current?.lifetime
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateSubscriptionStatus(customerInfo)
        }
    }
}

// MARK: - Package Extension

extension Package {
    var priceString: String {
        return storeProduct.localizedPriceString
    }

    var durationString: String {
        switch packageType {
        case .monthly:
            return "month"
        case .annual:
            return "year"
        case .lifetime:
            return "lifetime"
        default:
            return ""
        }
    }

    var savingsPercentage: Int? {
        guard packageType == .annual,
              let monthlyProduct = RevenueCatService.shared.monthlyPackage?.storeProduct else {
            return nil
        }

        let monthlyPrice = monthlyProduct.price as Decimal
        let annualPrice = storeProduct.price as Decimal
        let yearlyMonthlyEquivalent = monthlyPrice * 12

        guard yearlyMonthlyEquivalent > 0 else { return nil }

        let savings = ((yearlyMonthlyEquivalent - annualPrice) / yearlyMonthlyEquivalent) * 100
        return Int(truncating: savings as NSDecimalNumber)
    }
}
