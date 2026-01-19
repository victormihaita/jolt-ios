import Foundation
import Security
import JoltCore

/// Service for securely storing sensitive data in the iOS Keychain
public final class KeychainService {
    public static let shared = KeychainService()

    private let service = JoltConstants.Keychain.serviceName

    private init() {}

    // MARK: - Token Management

    public func saveToken(_ token: String) {
        save(token, forKey: JoltConstants.Keychain.accessTokenKey)
    }

    public func getToken() -> String? {
        get(JoltConstants.Keychain.accessTokenKey)
    }

    public func saveRefreshToken(_ token: String) {
        save(token, forKey: JoltConstants.Keychain.refreshTokenKey)
    }

    public func getRefreshToken() -> String? {
        get(JoltConstants.Keychain.refreshTokenKey)
    }

    public func saveUserId(_ userId: String) {
        save(userId, forKey: JoltConstants.Keychain.userIdKey)
    }

    public func getUserId() -> String? {
        get(JoltConstants.Keychain.userIdKey)
    }

    public func clearAll() {
        delete(JoltConstants.Keychain.accessTokenKey)
        delete(JoltConstants.Keychain.refreshTokenKey)
        delete(JoltConstants.Keychain.userIdKey)
    }

    // MARK: - Generic Operations

    public func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newItem as CFDictionary, nil)
        if status != errSecSuccess {
            JoltLogger.error("Failed to save keychain item: \(status)", category: .auth)
        }
    }

    public func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    public func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
