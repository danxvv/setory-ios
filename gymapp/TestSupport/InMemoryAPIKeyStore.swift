//
//  InMemoryAPIKeyStore.swift
//  gymapp
//
//  Non-persistent APIKeyStoring for unit tests and the -uitest-ai /
//  -uitest-photo-match launch hooks. Lives in TestSupport so the shipped
//  binary never carries a substitute for the Keychain.
//

#if DEBUG

import Foundation

/// A class so every reader sees writes made through shared references.
final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var key: String?

    init(key: String? = nil) {
        self.key = key
    }

    func read() -> String? {
        lock.withLock { key }
    }

    func save(_ key: String) {
        lock.withLock { self.key = key }
    }

    func clear() {
        lock.withLock { key = nil }
    }
}

#endif
