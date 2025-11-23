//
//  KeychainManager.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.11.25.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let accessTokenKey = "com.dev.ObServe.accessToken"
    private let refreshTokenKey = "com.dev.ObServe.refreshToken"
    private let rememberMeKey = "com.dev.ObServe.rememberMe"

    private init() {}

    // MARK: - Token Storage

    func saveTokens(accessToken: String, refreshToken: String) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)
    }

    func loadTokens() -> (accessToken: String?, refreshToken: String?) {
        let accessToken = loadFromKeychain(key: accessTokenKey)
        let refreshToken = loadFromKeychain(key: refreshTokenKey)
        return (accessToken, refreshToken)
    }

    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }

    // MARK: - Remember Me Preference

    func saveRememberMe(_ rememberMe: Bool) {
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
    }

    func loadRememberMe() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }

    func clearRememberMe() {
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
    }

    // MARK: - Private Keychain Operations

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else {
            print("Failed to convert string to data for key: \(key)")
            return
        }

        // Delete any existing item first
        deleteFromKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to save to Keychain: \(status)")
        }
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
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

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
