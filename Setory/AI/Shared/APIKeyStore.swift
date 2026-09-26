//
//  APIKeyStore.swift
//  Setory
//
//  Keychain-backed storage for the OpenRouter API key. The key never
//  touches UserDefaults, files, or logs. The protocol seam lets tests and
//  the -uitest-ai launch hook substitute an in-memory store — see
//  InMemoryAPIKeyStore in TestSupport.
//

import Foundation
import Security

protocol APIKeyStoring: Sendable {
    /// The stored key, or nil when none is configured.
    func read() -> String?
    /// Stores the key, replacing any previous value.
    func save(_ key: String)
    /// Removes the stored key; a missing key is not an error.
    func clear()
}

/// Generic-password Keychain item: service = bundle ID, one fixed account.
struct KeychainAPIKeyStore: APIKeyStoring {
    private static let account = "openrouter-api-key"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "Setory",
            kSecAttrAccount as String: Self.account,
        ]
    }

    func read() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ key: String) {
        let data = Data(key.utf8)
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            let update = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
            if updateStatus != errSecSuccess {
                assertionFailure("Keychain update failed: \(updateStatus)")
            }
        } else if addStatus != errSecSuccess {
            assertionFailure("Keychain add failed: \(addStatus)")
        }
    }

    func clear() {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            assertionFailure("Keychain delete failed: \(status)")
        }
    }
}
