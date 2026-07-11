//
//  ExerciseCatalogSource.swift
//  gymapp
//

import Foundation

/// One exercise entry as delivered by a catalog content source. This shape
/// doubles as the payload contract for the future REST catalog endpoint
/// (`GET /exercises`), so field names and types must stay stable.
struct CatalogExercise: Codable, Equatable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let primaryMuscles: [Muscle]
    let secondaryMuscles: [Muscle]
    /// Canonical English description of the exercise.
    let summary: String
    /// Canonical English step-by-step instructions, in order.
    let instructions: [String]
}

/// Provides the exercise catalog to seeding. The bundled JSON implementation
/// is the current source; a future remote source returns the same entries
/// from the REST API without changes to seeding or UI.
protocol ExerciseCatalogSource {
    func loadCatalog() throws -> [CatalogExercise]
}

/// Reads the catalog from `exercises.json` in the app bundle.
struct BundledCatalogSource: ExerciseCatalogSource {
    enum SourceError: Error {
        case resourceMissing
    }

    var bundle: Bundle = .main

    func loadCatalog() throws -> [CatalogExercise] {
        guard let url = bundle.url(forResource: "exercises", withExtension: "json") else {
            throw SourceError.resourceMissing
        }
        return try JSONDecoder().decode([CatalogExercise].self, from: Data(contentsOf: url))
    }
}
