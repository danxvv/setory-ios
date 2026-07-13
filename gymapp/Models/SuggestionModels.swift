//
//  SuggestionModels.swift
//  gymapp
//
//  Wire types of the AI suggestion contract. SuggestionRequestPayload is
//  the user-message JSON sent to OpenRouter; SuggestedRoutine is the
//  structured-output JSON the model must return. Field names and the
//  Muscle/ExerciseCategory raw values are the stable serialization keys —
//  renaming them breaks the API contract, not just local code.
//

import Foundation

/// Everything the model needs to compose a routine: the local exercise
/// catalog, a summary of recent workout history, and the optional
/// free-text goal. Sent as the user message's JSON body.
struct SuggestionRequestPayload: Codable, Equatable, Sendable {
    struct CatalogEntry: Codable, Equatable, Sendable {
        let id: String
        /// ExerciseCategory raw value ("strength" / "cardio").
        let category: String
        /// Muscle raw values (e.g. "chest", "lower_back").
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
    }

    struct HistorySession: Codable, Equatable, Sendable {
        struct ExerciseEntry: Codable, Equatable, Sendable {
            let exerciseId: String
            let seriesCount: Int
        }

        /// Calendar day as "yyyy-MM-dd"; time of day carries no signal.
        let date: String
        let exercises: [ExerciseEntry]
        /// Muscle raw values worked that day, deduplicated.
        let musclesWorked: [String]
    }

    let catalog: [CatalogEntry]
    /// Newest first; empty when nothing has been logged yet.
    let recentSessions: [HistorySession]
    let goal: String?
}

/// The routine the model returns via structured outputs. `items` reference
/// catalog exercises by stable ID; muscle metadata is intentionally absent —
/// it is always resolved from the local Exercise records.
struct SuggestedRoutine: Codable, Equatable, Sendable {
    struct Item: Codable, Equatable, Sendable {
        let exerciseId: String
        var targetSets: Int
    }

    var name: String
    var rationale: String
    var items: [Item]
}
