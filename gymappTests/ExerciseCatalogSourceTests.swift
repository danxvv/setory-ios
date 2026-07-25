//
//  ExerciseCatalogSourceTests.swift
//  gymappTests
//

import Foundation
import Testing
@testable import gymapp

struct ExerciseCatalogSourceTests {
    @Test func bundledSourceDecodesFullCatalog() throws {
        let catalog = try BundledCatalogSource().loadCatalog()
        let entries = catalog.exercises

        #expect(catalog.version == CatalogSeeder.bundledCatalogVersion)
        #expect(catalog.datasetCommit == ExerciseMediaStore.datasetCommit)
        // The full Gym visual dataset; exact count may drift on upgrades.
        #expect(entries.count >= 1300)
        for entry in entries {
            #expect(!entry.id.isEmpty)
            #expect(entry.id.hasPrefix("gv"), "'\(entry.id)' is not a dataset id")
            #expect(!entry.name.isEmpty)
            #expect(!entry.primaryMuscles.isEmpty, "'\(entry.id)' violates the muscle-metadata contract")
            #expect(entry.equipment != nil, "'\(entry.id)' is missing equipment")
            #expect(entry.gifFileName?.isEmpty == false, "'\(entry.id)' is missing media")
            #expect(!entry.summary.isEmpty, "'\(entry.id)' is missing a summary")
            #expect(!entry.instructions.isEmpty, "'\(entry.id)' is missing instructions")
            #expect(entry.instructions.allSatisfy { !$0.isEmpty })
        }
        #expect(entries.contains { $0.category == .strength })
        #expect(entries.contains { $0.category == .cardio })
    }

    @Test func catalogIdsAreUnique() throws {
        let ids = try BundledCatalogSource().loadCatalog().exercises.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func legacyMappingTargetsExistInCatalog() throws {
        let mapping = try LegacyCatalogMigrator.loadBundledMapping()
        let catalogIds = Set(try BundledCatalogSource().loadCatalog().exercises.map(\.id))

        #expect(mapping.mapped.count == 38)
        #expect(Set(mapping.unmapped) == ["face-pull", "rowing-machine"])
        for (legacyId, datasetId) in mapping.mapped {
            #expect(catalogIds.contains(datasetId), "'\(legacyId)' maps to unknown id '\(datasetId)'")
        }
    }

    @Test func entriesDecodeWithoutOptionalMediaFields() throws {
        // REST payloads and fixtures may omit media/localization fields.
        let json = """
        {"id": "x", "name": "X", "category": "strength", "primaryMuscles": ["chest"],
         "secondaryMuscles": [], "summary": "s", "instructions": ["i"]}
        """
        let entry = try JSONDecoder().decode(CatalogExercise.self, from: Data(json.utf8))
        #expect(entry.equipment == nil)
        #expect(entry.gifFileName == nil)
        #expect(entry.localizedSummaries.isEmpty)
        #expect(entry.localizedInstructions.isEmpty)
    }

    @Test func missingResourceThrows() {
        let emptyBundle = Bundle(for: BundleToken.self)
        #expect(throws: BundledCatalogSource.SourceError.self) {
            try BundledCatalogSource(bundle: emptyBundle).loadCatalog()
        }
    }
}

/// Anchor class so tests can reference the test bundle (which has no exercise-catalog.json).
private final class BundleToken {}
