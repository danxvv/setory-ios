//
//  ExerciseCatalog.swift
//  Setory
//

import Foundation

/// One exercise entry of the bundled catalog. Media and translation fields
/// are optional so hand-written test fixtures may omit them.
struct CatalogExercise: Codable, Equatable {
    var id: String
    var name: String
    var category: ExerciseCategory
    var primaryMuscles: [Muscle]
    var secondaryMuscles: [Muscle]
    var equipment: Equipment?
    /// Remote animation file name in the pinned dataset; nil = no media.
    var gifFileName: String?
    /// Canonical English description of the exercise.
    var summary: String
    /// Canonical English step-by-step instructions, in order.
    var instructions: [String]
    /// Translations keyed by language code ("es"). English stays canonical
    /// in `name`, `summary`, and `instructions`.
    var localizedNames: [String: String]?
    var localizedSummaries: [String: String]?
    var localizedInstructions: [String: [String]]?
}

/// The full catalog payload: a version stamp that gates seeding plus the
/// exercise entries. `datasetCommit` records provenance for media URLs.
struct ExerciseCatalog: Codable, Equatable {
    let version: Int
    let datasetCommit: String?
    let exercises: [CatalogExercise]
}
