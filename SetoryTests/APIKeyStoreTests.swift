//
//  APIKeyStoreTests.swift
//  SetoryTests
//
//  Contract semantics of APIKeyStoring, exercised through the in-memory
//  implementation (the Keychain variant is the same interface over
//  SecItem calls, which unit tests can't touch reliably).
//

import Testing
@testable import Setory

struct APIKeyStoreTests {
    private func makeStore() -> any APIKeyStoring {
        InMemoryAPIKeyStore()
    }

    @Test func readsNilBeforeAnySave() {
        #expect(makeStore().read() == nil)
    }

    @Test func savedKeyRoundTrips() {
        let store = makeStore()
        store.save("sk-or-v1-test")
        #expect(store.read() == "sk-or-v1-test")
    }

    @Test func savingAgainReplacesThePreviousKey() {
        let store = makeStore()
        store.save("first-key")
        store.save("second-key")
        #expect(store.read() == "second-key")
    }

    @Test func clearRemovesTheKey() {
        let store = makeStore()
        store.save("sk-or-v1-test")
        store.clear()
        #expect(store.read() == nil)
    }

    @Test func clearingAnEmptyStoreIsHarmless() {
        let store = makeStore()
        store.clear()
        #expect(store.read() == nil)
        store.save("sk-or-v1-test")
        #expect(store.read() == "sk-or-v1-test")
    }

    @Test func initialKeySeedsTheStore() {
        let store = InMemoryAPIKeyStore(key: "seeded")
        #expect(store.read() == "seeded")
    }
}
