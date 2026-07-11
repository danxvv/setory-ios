//
//  ExerciseCatalogSourceTests.swift
//  gymappTests
//

import Foundation
import Testing
@testable import gymapp

struct ExerciseCatalogSourceTests {
    @Test func bundledSourceDecodesFullCatalog() throws {
        let entries = try BundledCatalogSource().loadCatalog()

        #expect(!entries.isEmpty)
        for entry in entries {
            #expect(!entry.id.isEmpty)
            #expect(!entry.name.isEmpty)
            #expect(!entry.primaryMuscles.isEmpty, "'\(entry.id)' violates the muscle-metadata contract")
            #expect(!entry.summary.isEmpty, "'\(entry.id)' is missing a summary")
            #expect(!entry.instructions.isEmpty, "'\(entry.id)' is missing instructions")
            #expect(entry.instructions.allSatisfy { !$0.isEmpty })
        }
        #expect(entries.contains { $0.category == .strength })
        #expect(entries.contains { $0.category == .cardio })
    }

    @Test func catalogIdsAreUnique() throws {
        let ids = try BundledCatalogSource().loadCatalog().map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func missingResourceThrows() {
        let emptyBundle = Bundle(for: BundleToken.self)
        #expect(throws: BundledCatalogSource.SourceError.self) {
            try BundledCatalogSource(bundle: emptyBundle).loadCatalog()
        }
    }
}

/// Anchor class so tests can reference the test bundle (which has no exercises.json).
private final class BundleToken {}
