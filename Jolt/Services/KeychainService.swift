import Foundation
import Security

/// KeychainService provides secure storage for sensitive data like auth tokens
class KeychainService {
    static let shared = KeychainService()

    private let service = "com.wiheads.victor.jolt.reminders"

    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
    }

    private init() {}

    // MARK: - Token Management

    func saveToken(_ token: String) {
        save(key: Keys.accessToken, value: token)
    }

    func getToken() -> String? {
        return get(key: Keys.accessToken)
    }

    func saveRefreshToken(_ token: String) {
        save(key: Keys.refreshToken, value: token)
    }

    func getRefreshToken() -> String? {
        return get(key: Keys.refreshToken)
    }

    func saveUserId(_ userId: String) {
        save(key: Keys.userId, value: userId)
    }

    func getUserId() -> String? {
        return get(key: Keys.userId)
    }

    func clearAll() {
        delete(key: Keys.accessToken)
        delete(key: Keys.refreshToken)
        delete(key: Keys.userId)
    }

    // MARK: - Generic Keychain Operations

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
