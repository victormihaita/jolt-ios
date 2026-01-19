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
}
