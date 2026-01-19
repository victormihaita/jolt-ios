import Foundation
import SwiftUI
import JoltNetworking
import JoltSync
import JoltModels
import JoltKeychain

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: JoltModels.User?

    private let keychain = JoltKeychain.KeychainService.shared
    private let graphQL = GraphQLClient.shared

    var userEmail: String? {
        currentUser?.email
    }

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        if let _ = keychain.getToken() {
            isAuthenticated = true
            Task {
                await fetchCurrentUser()
            }
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let idToken = try await GoogleAuthService.shared.signIn()
            let mutation = JoltAPI.AuthenticateWithGoogleMutation(idToken: idToken)
            let result = try await graphQL.perform(mutation: mutation)

            let authData = result.authenticateWithGoogle

            // Store tokens
            keychain.saveToken(authData.accessToken)
            keychain.saveRefreshToken(authData.refreshToken)
            keychain.saveUserId(authData.user.id)

            // Update GraphQL client with new token
            graphQL.updateAuthToken(authData.accessToken)

            // Update current user
            currentUser = JoltModels.User(
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

            isAuthenticated = true
            isLoading = false

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

    func signOut() {
        // Clear local state
        keychain.clearAll()
        graphQL.updateAuthToken(nil)

        // Disconnect sync engine and clear cache
        SyncEngine.shared.disconnect()
        SyncEngine.shared.clearCache()

        // Logout from RevenueCat
        Task {
            await RevenueCatService.shared.logout()
        }

        isAuthenticated = false
        currentUser = nil
        Haptics.medium()
    }

    func fetchCurrentUser() async {
        do {
            let query = JoltAPI.MeQuery()
            let result = try await graphQL.fetch(query: query)

            currentUser = JoltModels.User(
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
            let mutation = JoltAPI.RefreshTokenMutation(refreshToken: refreshToken)
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
private extension JoltAPI.DateTime {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
}
