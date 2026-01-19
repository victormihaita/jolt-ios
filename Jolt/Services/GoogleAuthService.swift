import Foundation
import GoogleSignIn

/// GoogleAuthService handles Google Sign-In authentication
class GoogleAuthService: NSObject, ObservableObject {
    static let shared = GoogleAuthService()

    @Published var isSigningIn = false
    @Published var error: Error?

    private override init() {
        super.init()
    }

    /// Signs in with Google and returns the ID token
    func signIn() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.isSigningIn = true
                self.performSignIn(continuation: continuation)
            }
        }
    }

    @MainActor
    private func performSignIn(continuation: CheckedContinuation<String, Error>) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            isSigningIn = false
            continuation.resume(throwing: GoogleAuthError.noViewController)
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            self?.isSigningIn = false

            if let error = error {
                continuation.resume(throwing: error)
                return
            }

            guard let idToken = result?.user.idToken?.tokenString else {
                continuation.resume(throwing: GoogleAuthError.noToken)
                return
            }

            continuation.resume(returning: idToken)
        }
    }

    /// Handle the URL callback from Google Sign-In
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    /// Restore previous sign-in session if available
    func restorePreviousSignIn() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let idToken = user?.idToken?.tokenString
                continuation.resume(returning: idToken)
            }
        }
    }
}

enum GoogleAuthError: LocalizedError {
    case noViewController
    case noToken
    case cancelled
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "Unable to present sign-in screen"
        case .noToken:
            return "Failed to get authentication token"
        case .cancelled:
            return "Sign-in was cancelled"
        case .notConfigured:
            return "Google Sign-In is not configured"
        }
    }
}
