//
//  ExerciseCatalogSource.swift
//  gymapp
//

import Foundation

/// One exercise entry as delivered by a catalog content source. This shape
/// doubles as the payload contract for the future REST catalog endpoint
/// (`GET /exercises`), so field names and types must stay stable.
struct CatalogExercise: Equatable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let primaryMuscles: [Muscle]
    let secondaryMuscles: [Muscle]
    /// Nil when the entry carries no equipment metadata.
    let equipment: Equipment?
    /// Remote animation file name in the pinned dataset; nil = no media.
    let gifFileName: String?
    /// Canonical English description of the exercise.
    let summary: String
    /// Canonical English step-by-step instructions, in order.
    let instructions: [String]
    /// Description translations keyed by language code ("es").
    let localizedSummaries: [String: String]
    /// Instruction-step translations keyed by language code ("es").
    let localizedInstructions: [String: [String]]

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        primaryMuscles: [Muscle],
        secondaryMuscles: [Muscle],
        equipment: Equipment? = nil,
        gifFileName: String? = nil,
        summary: String,
        instructions: [String],
        localizedSummaries: [String: String] = [:],
        localizedInstructions: [String: [String]] = [:]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.gifFileName = gifFileName
        self.summary = summary
        self.instructions = instructions
        self.localizedSummaries = localizedSummaries
        self.localizedInstructions = localizedInstructions
    }
}

extension CatalogExercise: Codable {
    /// Media and localization fields decode leniently so hand-written test
    /// fixtures and future REST payloads may omit them.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            category: try container.decode(ExerciseCategory.self, forKey: .category),
            primaryMuscles: try container.decode([Muscle].self, forKey: .primaryMuscles),
            secondaryMuscles: try container.decode([Muscle].self, forKey: .secondaryMuscles),
            equipment: try container.decodeIfPresent(Equipment.self, forKey: .equipment),
            gifFileName: try container.decodeIfPresent(String.self, forKey: .gifFileName),
            summary: try container.decode(String.self, forKey: .summary),
            instructions: try container.decode([String].self, forKey: .instructions),
            localizedSummaries: try container.decodeIfPresent([String: String].self, forKey: .localizedSummaries) ?? [:],
            localizedInstructions: try container.decodeIfPresent([String: [String]].self, forKey: .localizedInstructions) ?? [:]
        )
    }
}

/// The full catalog payload: a version stamp that gates seeding plus the
/// exercise entries. `datasetCommit` records provenance for media URLs.
struct ExerciseCatalog: Codable, Equatable {
    let version: Int
    let datasetCommit: String?
    let exercises: [CatalogExercise]
}

/// Provides the exercise catalog to seeding. The bundled JSON implementation
/// is the current source; a future remote source returns the same catalog
/// from the REST API without changes to seeding or UI.
protocol ExerciseCatalogSource {
    func loadCatalog() throws -> ExerciseCatalog
}

/// Reads the catalog from `exercise-catalog.json` in the app bundle.
struct BundledCatalogSource: ExerciseCatalogSource {
    enum SourceError: Error {
        case resourceMissing
    }

    var bundle: Bundle = .main

    func loadCatalog() throws -> ExerciseCatalog {
        guard let url = bundle.url(forResource: "exercise-catalog", withExtension: "json") else {
            throw SourceError.resourceMissing
        }
        return try JSONDecoder().decode(ExerciseCatalog.self, from: Data(contentsOf: url))
    }
}
