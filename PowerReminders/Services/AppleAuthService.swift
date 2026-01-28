import Foundation
import AuthenticationServices

/// AppleAuthService handles Sign in with Apple authentication
@MainActor
class AppleAuthService: NSObject, ObservableObject {
    static let shared = AppleAuthService()

    @Published var isSigningIn = false
    @Published var error: Error?

    private var continuation: CheckedContinuation<AppleAuthResult, Error>?

    private override init() {
        super.init()
    }

    /// Signs in with Apple and returns the identity token and user info
    func signIn() async throws -> AppleAuthResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.isSigningIn = true
            self.performSignIn()
        }
    }

    private func performSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            self.isSigningIn = false

            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self.continuation?.resume(throwing: AppleAuthError.invalidCredential)
                self.continuation = nil
                return
            }

            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                self.continuation?.resume(throwing: AppleAuthError.noToken)
                self.continuation = nil
                return
            }

            // Extract user info (only available on first sign-in)
            var displayName: String?
            if let fullName = appleIDCredential.fullName {
                let givenName = fullName.givenName ?? ""
                let familyName = fullName.familyName ?? ""
                let name = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
                if !name.isEmpty {
                    displayName = name
                }
            }

            let result = AppleAuthResult(
                identityToken: identityToken,
                userIdentifier: appleIDCredential.user,
                email: appleIDCredential.email,
                displayName: displayName
            )

            self.continuation?.resume(returning: result)
            self.continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.isSigningIn = false

            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.continuation?.resume(throwing: AppleAuthError.cancelled)
                case .failed:
                    self.continuation?.resume(throwing: AppleAuthError.failed)
                case .invalidResponse:
                    self.continuation?.resume(throwing: AppleAuthError.invalidResponse)
                case .notHandled:
                    self.continuation?.resume(throwing: AppleAuthError.notHandled)
                case .unknown:
                    self.continuation?.resume(throwing: AppleAuthError.unknown)
                case .notInteractive:
                    self.continuation?.resume(throwing: AppleAuthError.notInteractive)
                case .matchedExcludedCredential:
                    self.continuation?.resume(throwing: AppleAuthError.matchedExcludedCredential)
                @unknown default:
                    self.continuation?.resume(throwing: error)
                }
            } else {
                self.continuation?.resume(throwing: error)
            }
            self.continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleAuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window from the first connected scene
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Supporting Types

struct AppleAuthResult {
    let identityToken: String
    let userIdentifier: String
    let email: String?
    let displayName: String?
}

enum AppleAuthError: LocalizedError {
    case noToken
    case invalidCredential
    case cancelled
    case failed
    case invalidResponse
    case notHandled
    case unknown
    case notInteractive
    case matchedExcludedCredential

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "Failed to get authentication token"
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .cancelled:
            return "Sign-in was cancelled"
        case .failed:
            return "Sign-in failed"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Request not handled"
        case .unknown:
            return "An unknown error occurred"
        case .notInteractive:
            return "Sign-in requires user interaction"
        case .matchedExcludedCredential:
            return "Credential was excluded"
        }
    }
}
