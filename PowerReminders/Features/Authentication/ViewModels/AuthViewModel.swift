import Foundation
import SwiftUI
import Combine
import PRNetworking
import PRSync
import PRModels
import PRKeychain
import ApolloAPI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: PRModels.User?

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
        errorMessage = nil

        do {
            let idToken = try await GoogleAuthService.shared.signIn()
            let mutation = PRAPI.AuthenticateWithGoogleMutation(idToken: idToken)
            let result = try await graphQL.perform(mutation: mutation)

            let authData = result.authenticateWithGoogle

            // Store tokens
            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            keychain.saveUserId(authData.user.id)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(authData.accessToken)

            // Update current user
            currentUser = PRModels.User(
                id: UUID(uuidString: authData.user.id) ?? UUID(),
                email: authData.user.email,
                displayName: authData.user.displayName,
                avatarUrl: authData.user.avatarUrl,
                timezone: authData.user.timezone,
                isPremium: authData.user.isPremium,
                premiumUntil: authData.user.premiumUntil?.toDate()
            )

            // Set RevenueCat user ID to sync subscription status
            await RevenueCatService.shared.setUserID(authData.user.id)

            // Connect SyncEngine to start watching data
            SyncEngine.shared.connect()

            isAuthenticated = true
            isLoading = false

            // Request push token and register device for push notifications
            // First, request remote notifications if authorized (this triggers APNs token delivery)
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
            // Then register device (the token will arrive via AppDelegate callback)
            await DeviceService.shared.onUserAuthenticated()

            Haptics.success()
        } catch {
            print("❌ Auth error: \(error)")
            print("❌ Auth error type: \(type(of: error))")
            print("❌ Auth error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            Haptics.error()
        }
    }

    func signInWithApple() async {
        isLoading = true
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

            // Store tokens
            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            keychain.saveUserId(authData.user.id)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(authData.accessToken)

            // Update current user
            currentUser = PRModels.User(
                id: UUID(uuidString: authData.user.id) ?? UUID(),
                email: authData.user.email,
                displayName: authData.user.displayName,
                avatarUrl: authData.user.avatarUrl,
                timezone: authData.user.timezone,
                isPremium: authData.user.isPremium,
                premiumUntil: authData.user.premiumUntil?.toDate()
            )

            // Set RevenueCat user ID to sync subscription status
            await RevenueCatService.shared.setUserID(authData.user.id)

            // Connect SyncEngine to start watching data
            SyncEngine.shared.connect()

            isAuthenticated = true
            isLoading = false

            // Request push token and register device for push notifications
            await NotificationService.shared.registerForRemoteNotificationsIfAuthorized()
            await DeviceService.shared.onUserAuthenticated()

            Haptics.success()
        } catch let error as AppleAuthError where error == .cancelled {
            // User cancelled - don't show error
            isLoading = false
        } catch {
            print("❌ Apple Auth error: \(error)")
            print("❌ Apple Auth error type: \(type(of: error))")
            print("❌ Apple Auth error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            Haptics.error()
        }
    }

    func signOut() {
        // Unregister device from push notifications BEFORE clearing credentials
        // We need the auth token to make the API call
        Task {
            // Unregister device first (requires auth token)
            await DeviceService.shared.onUserLogout()

            // Now clear local state on main actor
            await MainActor.run {
                keychain.clearAll()
                graphQL.updateAuthToken(nil)

                // Disconnect sync engine and clear cache
                SyncEngine.shared.disconnect()
                SyncEngine.shared.clearCache()

                isAuthenticated = false
                currentUser = nil
            }

            // Logout from RevenueCat (doesn't need auth token)
            await RevenueCatService.shared.logout()
        }

        Haptics.medium()
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
}

// Extension to convert GraphQL DateTime to Date
private extension PRAPI.DateTime {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}
