import Foundation

public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case graphQLErrors([String])
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case premiumRequired
    case unknown
    case offline
    case conflictError(serverVersion: Int, localVersion: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .graphQLErrors(let errors):
            return errors.joined(separator: ", ")
        case .unauthorized:
            return "Please sign in again"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .premiumRequired:
            return "This feature requires a premium subscription"
        case .unknown:
            return "An unknown error occurred"
        case .offline:
            return "You're offline. Changes will sync when you reconnect."
        case .conflictError(let serverVersion, let localVersion):
            return "Conflict: server has version \(serverVersion), you have \(localVersion)"
        }
    }

    public var isAuthError: Bool {
        switch self {
        case .unauthorized, .forbidden:
            return true
        default:
            return false
        }
    }

    public var requiresReauth: Bool {
        if case .unauthorized = self {
            return true
        }
        return false
    }

    /// Whether this error indicates the device is offline
    public var isOffline: Bool {
        switch self {
        case .offline:
            return true
        case .networkError:
            return true
        default:
            return false
        }
    }

    /// Whether this error is retryable
    public var isRetryable: Bool {
        switch self {
        case .offline, .networkError, .serverError:
            return true
        default:
            return false
        }
    }
}
