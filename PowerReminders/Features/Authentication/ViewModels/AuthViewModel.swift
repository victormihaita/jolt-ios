import Foundation
import SwiftUI
import Combine
import PRNetworking
import PRSync
import PRModels
import PRKeychain
import ApolloAPI

private let pendingReminderKey = "onboarding_pending_reminder"

@MainActor
class AuthViewModel: ObservableObject {
    enum AuthProvider {
        case google
        case apple
    }

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authenticatingProvider: AuthProvider?
    @Published var errorMessage: String?
    @Published var currentUser: PRModels.User?
    @Published var showRestoreAccountPrompt = false

    struct PendingAuthData {
        let accessToken: String
        let refreshToken: String
        let userId: String
        let user: PRModels.User
    }
    private var pendingAuthData: PendingAuthData?

    private let keychain = PRKeychain.KeychainService.shared
    private let graphQL = GraphQLClient.shared
    private var cancellables = Set<AnyCancellable>()

    var userEmail: String? {
        currentUser?.email
    }

    init() {
        // Observe SyncEngine's currentUser to stay in sync
        SyncEngine.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.currentUser = user
                }
            }
            .store(in: &cancellables)

        checkAuthentication()
    }

    func checkAuthentication() {
        if let _ = keychain.getToken() {
            isAuthenticated = true
            // SQLite cache persists across launches - show cached data immediately
            // SyncEngine watchers use .returnCacheDataAndFetch to update from network
            SyncEngine.shared.connect()

            // Request push token and register device for returning users
            Task {
                // First, request remote notifications if authorized (this triggers APNs token delivery)
                await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
                // Then register device (if token is already available from a previous session)
                await DeviceService.shared.onUserAuthenticated()
            }
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        authenticatingProvider = .google
        errorMessage = nil

        do {
            let idToken = try await GoogleAuthService.shared.signIn()
            let mutation = PRAPI.AuthenticateWithGoogleMutation(idToken: idToken)
            let result = try await graphQL.perform(mutation: mutation)

            let authData = result.authenticateWithGoogle

            let user = PRModels.User(
                id: UUID(uuidString: authData.user.id) ?? UUID(),
                email: authData.user.email,
                displayName: authData.user.displayName,
                avatarUrl: authData.user.avatarUrl,
                timezone: authData.user.timezone,
                isPremium: authData.user.isPremium,
                premiumUntil: authData.user.premiumUntil?.toDate()
            )

            if authData.accountPendingDeletion {
                pendingAuthData = PendingAuthData(
                    accessToken: authData.accessToken,
                    refreshToken: authData.refreshToken,
                    userId: authData.user.id,
                    user: user
                )
                isLoading = false
                authenticatingProvider = nil
                showRestoreAccountPrompt = true
                return
            }

            // Store tokens
            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            keychain.saveUserId(authData.user.id)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(authData.accessToken)

            // Update current user
            currentUser = user

            // Set RevenueCat user ID to sync subscription status
            await RevenueCatService.shared.setUserID(authData.user.id)

            // Connect SyncEngine to start watching data
            SyncEngine.shared.connect()

            isAuthenticated = true
            isLoading = false
            authenticatingProvider = nil

            // Request push token and register device for push notifications
            // First, request remote notifications if authorized (this triggers APNs token delivery)
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
            // Then register device (the token will arrive via AppDelegate callback)
            await DeviceService.shared.onUserAuthenticated()

            // Sync any pending reminder from onboarding
            await syncPendingOnboardingReminder()

            Haptics.success()
        } catch {
            print("❌ Auth error: \(error)")
            print("❌ Auth error type: \(type(of: error))")
            print("❌ Auth error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            authenticatingProvider = nil
            Haptics.error()
        }
    }

    func signInWithApple() async {
        isLoading = true
        authenticatingProvider = .apple
        errorMessage = nil

        do {
            let appleAuth = try await AppleAuthService.shared.signIn()

            let input = PRAPI.AuthenticateWithAppleInput(
                identityToken: appleAuth.identityToken,
                userIdentifier: appleAuth.userIdentifier,
                email: appleAuth.email.map { .some($0) } ?? .null,
                displayName: appleAuth.displayName.map { .some($0) } ?? .null
            )
            let mutation = PRAPI.AuthenticateWithAppleMutation(input: input)
            let result = try await graphQL.perform(mutation: mutation)

            let authData = result.authenticateWithApple

            let user = PRModels.User(
                id: UUID(uuidString: authData.user.id) ?? UUID(),
                email: authData.user.email,
                displayName: authData.user.displayName,
                avatarUrl: authData.user.avatarUrl,
                timezone: authData.user.timezone,
                isPremium: authData.user.isPremium,
                premiumUntil: authData.user.premiumUntil?.toDate()
            )

            if authData.accountPendingDeletion {
                pendingAuthData = PendingAuthData(
                    accessToken: authData.accessToken,
                    refreshToken: authData.refreshToken,
                    userId: authData.user.id,
                    user: user
                )
                isLoading = false
                authenticatingProvider = nil
                showRestoreAccountPrompt = true
                return
            }

            // Store tokens
            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            keychain.saveUserId(authData.user.id)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(authData.accessToken)

            // Update current user
            currentUser = user

            // Set RevenueCat user ID to sync subscription status
            await RevenueCatService.shared.setUserID(authData.user.id)

            // Connect SyncEngine to start watching data
            SyncEngine.shared.connect()

            isAuthenticated = true
            isLoading = false
            authenticatingProvider = nil

            // Request push token and register device for push notifications
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
            await DeviceService.shared.onUserAuthenticated()

            // Sync any pending reminder from onboarding
            await syncPendingOnboardingReminder()

            Haptics.success()
        } catch let error as AppleAuthError where error == .cancelled {
            // User cancelled - don't show error
            isLoading = false
            authenticatingProvider = nil
        } catch {
            print("❌ Apple Auth error: \(error)")
            print("❌ Apple Auth error type: \(type(of: error))")
            print("❌ Apple Auth error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            authenticatingProvider = nil
            Haptics.error()
        }
    }

    func signOut() {
        Task {
            await performSignOutCleanup()
        }
        Haptics.medium()
    }

    func deleteAccount() async -> Bool {
        do {
            let mutation = PRAPI.DeleteAccountMutation()
            let result = try await graphQL.perform(mutation: mutation)

            guard result.deleteAccount else {
                return false
            }

            await performSignOutCleanup()
            Haptics.success()
            return true
        } catch {
            print("Failed to delete account: \(error)")
            return false
        }
    }

    func restoreAccount() async {
        guard let pending = pendingAuthData else { return }

        isLoading = true

        do {
            // Store tokens
            keychain.saveToken(pending.accessToken)
            keychain.saveRefreshToken(pending.refreshToken)
            keychain.saveUserId(pending.userId)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(pending.accessToken)

            // Call restore account mutation
            let mutation = PRAPI.RestoreAccountMutation()
            _ = try await graphQL.perform(mutation: mutation)

            // Update current user
            currentUser = pending.user

            // Set RevenueCat user ID to sync subscription status
            await RevenueCatService.shared.setUserID(pending.userId)

            // Connect SyncEngine to start watching data
            SyncEngine.shared.connect()

            isAuthenticated = true
            isLoading = false
            showRestoreAccountPrompt = false
            pendingAuthData = nil

            // Request push token and register device for push notifications
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
            await DeviceService.shared.onUserAuthenticated()

            Haptics.success()
        } catch {
            print("Failed to restore account: \(error)")
            errorMessage = "Failed to restore account. Please try again."
            isLoading = false
            // Clear tokens since restore failed
            keychain.clearAll()
            graphQL.updateAuthToken(nil)
            showRestoreAccountPrompt = false
            pendingAuthData = nil
            Haptics.error()
        }
    }

    func declineRestore() async {
        guard let pending = pendingAuthData else { return }

        isLoading = true

        do {
            // Temporarily set up auth to call deleteAccount
            keychain.saveToken(pending.accessToken)
            keychain.saveRefreshToken(pending.refreshToken)
            graphQL.updateAuthToken(pending.accessToken)

            // Re-soft-delete the account
            let mutation = PRAPI.DeleteAccountMutation()
            _ = try await graphQL.perform(mutation: mutation)
        } catch {
            print("Failed to re-delete account: \(error)")
        }

        // Clean up regardless of success/failure
        keychain.clearAll()
        graphQL.updateAuthToken(nil)
        pendingAuthData = nil
        showRestoreAccountPrompt = false
        isLoading = false
    }

    private func performSignOutCleanup() async {
        // Unregister device first (requires auth token)
        await DeviceService.shared.onUserLogout()

        // Clear local state on main actor
        await MainActor.run {
            keychain.clearAll()
            graphQL.updateAuthToken(nil)
            SyncEngine.shared.disconnect()
            SyncEngine.shared.clearCache()
            isAuthenticated = false
            currentUser = nil
        }

        // Logout from RevenueCat
        await RevenueCatService.shared.logout()
    }

    func fetchCurrentUser() async {
        do {
            let query = PRAPI.MeQuery()
            let result = try await graphQL.fetch(query: query)

            currentUser = PRModels.User(
                id: UUID(uuidString: result.me.id) ?? UUID(),
                email: result.me.email,
                displayName: result.me.displayName,
                avatarUrl: result.me.avatarUrl,
                timezone: result.me.timezone,
                isPremium: result.me.isPremium,
                premiumUntil: result.me.premiumUntil?.toDate()
            )
        } catch let error as NetworkError {
            print("Failed to fetch user: \(error)")
            if case .unauthorized = error {
                signOut()
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func refreshTokenIfNeeded() async -> Bool {
        guard let refreshToken = keychain.getRefreshToken() else {
            return false
        }

        do {
            let mutation = PRAPI.RefreshTokenMutation(refreshToken: refreshToken)
            let result = try await graphQL.perform(mutation: mutation)

            let authData = result.refreshToken

            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            graphQL.updateAuthToken(authData.accessToken)

            return true
        } catch {
            signOut()
            return false
        }
    }

    // MARK: - Pending Onboarding Reminder Sync

    /// Syncs any pending reminder created during onboarding to the backend after sign-in.
    private func syncPendingOnboardingReminder() async {
        guard let data = UserDefaults.standard.data(forKey: pendingReminderKey),
              let pending = try? JSONDecoder().decode(PendingOnboardingReminder.self, from: data) else {
            return
        }

        do {
            var recurrenceInput: GraphQLNullable<PRAPI.RecurrenceRuleInput> = .null
            if let freqStr = pending.recurrenceFrequency,
               let frequency = Frequency(rawValue: freqStr) {
                let gqlFreq: GraphQLEnum<PRAPI.Frequency>
                switch frequency {
                case .hourly: gqlFreq = .init(.hourly)
                case .daily: gqlFreq = .init(.daily)
                case .weekly: gqlFreq = .init(.weekly)
                case .monthly: gqlFreq = .init(.monthly)
                case .yearly: gqlFreq = .init(.yearly)
                }
                recurrenceInput = .some(PRAPI.RecurrenceRuleInput(
                    frequency: gqlFreq,
                    interval: pending.recurrenceInterval ?? 1,
                    daysOfWeek: pending.recurrenceDaysOfWeek.map { .some($0) } ?? .null,
                    dayOfMonth: .null,
                    monthOfYear: .null,
                    endAfterOccurrences: .null,
                    endDate: .null
                ))
            }

            let gqlPriority: GraphQLEnum<PRAPI.Priority>
            switch pending.priority {
            case 3: gqlPriority = .init(.high)
            case 2: gqlPriority = .init(.normal)
            case 1: gqlPriority = .init(.low)
            default: gqlPriority = .init(.low)
            }

            let title = pending.parsedTitle.isEmpty ? pending.rawInput : pending.parsedTitle

            let dueAtStr: GraphQLNullable<String>
            if let date = pending.dueDate {
                dueAtStr = .some(ISO8601DateFormatter().string(from: date))
            } else {
                dueAtStr = .null
            }

            let input = PRAPI.CreateReminderInput(
                listId: .null,
                title: title,
                notes: .null,
                priority: .some(gqlPriority),
                dueAt: dueAtStr,
                allDay: pending.dueDate != nil ? .some(!pending.hasSpecificTime) : .null,
                recurrenceRule: recurrenceInput,
                isAlarm: .null,
                soundId: .null
            )

            let mutation = PRAPI.CreateReminderMutation(input: input)
            _ = try await graphQL.perform(mutation: mutation)
            SyncEngine.shared.refetch()
        } catch {
            print("Failed to sync onboarding reminder: \(error)")
        }

        // Clear pending reminder regardless of success
        UserDefaults.standard.removeObject(forKey: pendingReminderKey)
    }
}

// Extension to convert GraphQL DateTime to Date
private extension PRAPI.DateTime {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}
