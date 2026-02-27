import Foundation
import Security

nonisolated struct KeychainService: Sendable {
    static let serviceName = "com.teslaroutinesconnect"

    enum Key: String, Sendable {
        case accessToken = "tesla_access_token"
        case refreshToken = "tesla_refresh_token"
        case tokenExpiry = "tesla_token_expiry"
        case userEmail = "user_email"
        case encryptionKey = "data_encryption_key"
        case adminHash = "admin_auth_hash"
        case biometricToken = "biometric_token"
    }

    static func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func deleteAll() {
        Key.allKeys.forEach { delete($0) }
    }

    static func hasValidToken() -> Bool {
        guard let _ = load(.accessToken),
              let expiryString = load(.tokenExpiry),
              let expiry = Double(expiryString) else { return false }
        return Date().timeIntervalSince1970 < expiry
    }
}

extension KeychainService.Key {
    nonisolated static let allKeys: [KeychainService.Key] = [
        .accessToken, .refreshToken, .tokenExpiry,
        .userEmail, .encryptionKey, .adminHash, .biometricToken
    ]
}
