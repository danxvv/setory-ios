//
//  AIModelPreferenceTests.swift
//  SetoryTests
//
//  Characterizes the shared model preference after it moved out of
//  OpenRouterSuggestionService. The defaults key is user-visible state: a
//  stored override must keep resolving across the move, so the key string
//  itself is asserted, not just the resolution logic.
//

import Foundation
import Testing
@testable import Setory

struct AIModelPreferenceTests {
    /// A scratch suite per test so an override set in AI Settings on this
    /// simulator can't leak in.
    private func makeDefaults(_ name: String) throws -> (UserDefaults, () -> Void) {
        let suiteName = "AIModelPreferenceTests-\(name)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (defaults, { defaults.removePersistentDomain(forName: suiteName) })
    }

    /// The stored key must not drift: changing it would silently orphan every
    /// existing user's model override.
    @Test func defaultsKeyIsStable() {
        #expect(AIModelPreference.overrideDefaultsKey == "aiModelOverride")
        #expect(AIModelPreference.defaultModel == "openai/gpt-5.4-mini")
    }

    @Test func unsetOverrideResolvesToDefault() throws {
        let (defaults, cleanup) = try makeDefaults("unset")
        defer { cleanup() }
        #expect(AIModelPreference.resolvedModel(defaults: defaults) == AIModelPreference.defaultModel)
    }

    @Test func emptyOverrideResolvesToDefault() throws {
        let (defaults, cleanup) = try makeDefaults("empty")
        defer { cleanup() }
        defaults.set("", forKey: AIModelPreference.overrideDefaultsKey)
        #expect(AIModelPreference.resolvedModel(defaults: defaults) == AIModelPreference.defaultModel)
    }

    @Test func whitespaceOnlyOverrideResolvesToDefault() throws {
        let (defaults, cleanup) = try makeDefaults("whitespace")
        defer { cleanup() }
        defaults.set("  \n\t ", forKey: AIModelPreference.overrideDefaultsKey)
        #expect(AIModelPreference.resolvedModel(defaults: defaults) == AIModelPreference.defaultModel)
    }

    @Test func setOverrideWins() throws {
        let (defaults, cleanup) = try makeDefaults("set")
        defer { cleanup() }
        defaults.set("vendor/some-model", forKey: AIModelPreference.overrideDefaultsKey)
        #expect(AIModelPreference.resolvedModel(defaults: defaults) == "vendor/some-model")
    }

    @Test func overrideIsTrimmed() throws {
        let (defaults, cleanup) = try makeDefaults("trim")
        defer { cleanup() }
        defaults.set("  vendor/padded-model  ", forKey: AIModelPreference.overrideDefaultsKey)
        #expect(AIModelPreference.resolvedModel(defaults: defaults) == "vendor/padded-model")
    }
}
