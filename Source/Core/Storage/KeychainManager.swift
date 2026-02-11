//
//  KeychainManager.swift
//  TaskLuid
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private enum Keys {
        static let accessToken = "com.luid.taskluid.accessToken"
        static let idToken = "com.luid.taskluid.idToken"
        static let refreshToken = "com.luid.taskluid.refreshToken"
        static let userId = "com.luid.taskluid.userId"
        static let userEmail = "com.luid.taskluid.userEmail"
        static let activeOrganizationId = "com.luid.taskluid.activeOrganizationId"
    }

    func saveAccessToken(_ token: String) -> Bool {
        save(token, forKey: Keys.accessToken)
    }

    func getAccessToken() -> String? {
        get(forKey: Keys.accessToken)
    }

    func saveIdToken(_ token: String) -> Bool {
        save(token, forKey: Keys.idToken)
    }

    func getIdToken() -> String? {
        get(forKey: Keys.idToken)
    }

    func saveRefreshToken(_ token: String) -> Bool {
        save(token, forKey: Keys.refreshToken)
    }

    func getRefreshToken() -> String? {
        get(forKey: Keys.refreshToken)
    }

    func saveUserId(_ userId: String) -> Bool {
        save(userId, forKey: Keys.userId)
    }

    func getUserId() -> String? {
        get(forKey: Keys.userId)
    }

    func saveUserEmail(_ email: String) -> Bool {
        save(email, forKey: Keys.userEmail)
    }

    func getUserEmail() -> String? {
        get(forKey: Keys.userEmail)
    }

    func saveActiveOrganizationId(_ organizationId: String) -> Bool {
        save(organizationId, forKey: Keys.activeOrganizationId)
    }

    func getActiveOrganizationId() -> String? {
        get(forKey: Keys.activeOrganizationId)
    }

    func clearAll() {
        _ = delete(forKey: Keys.accessToken)
        _ = delete(forKey: Keys.idToken)
        _ = delete(forKey: Keys.refreshToken)
        _ = delete(forKey: Keys.userId)
        _ = delete(forKey: Keys.userEmail)
        _ = delete(forKey: Keys.activeOrganizationId)
    }

    func hasAccessToken() -> Bool {
        getAccessToken() != nil
    }

    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        _ = delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecMissingEntitlement || status == -34018 {
            UserDefaults.standard.set(value, forKey: key)
            return true
        }
        return status == errSecSuccess
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        if status == errSecMissingEntitlement || status == -34018 || status == errSecItemNotFound {
            return UserDefaults.standard.string(forKey: key)
        }

        return nil
    }

    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: key)

        return status == errSecSuccess || status == errSecItemNotFound
    }
}
