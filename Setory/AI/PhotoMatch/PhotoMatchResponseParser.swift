//
//  PhotoMatchResponseParser.swift
//  Setory
//
//  Validates model output against the catalog that was sent. Unlike the
//  suggestion parser this never throws on an empty result: "no matches" is
//  a normal outcome the UI renders as its own state. Pure statics so every
//  shape unit-tests from JSON fixtures.
//

import Foundation

enum PhotoMatchResponseParser {
    static func matches(
        from data: Data,
        statusCode: Int,
        validExerciseIds: Set<String>
    ) throws -> PhotoMatchResult {
        let result = try ChatCompletionResponse.decode(
            PhotoMatchResult.self,
            from: data,
            statusCode: statusCode
        )
        return validated(result, validExerciseIds: validExerciseIds)
    }

    /// Drops matches with unknown exercise IDs and collapses duplicates,
    /// preserving the model's best-first ordering.
    static func validated(
        _ result: PhotoMatchResult,
        validExerciseIds: Set<String>
    ) -> PhotoMatchResult {
        var seen = Set<String>()
        var matches: [PhotoMatch] = []
        for match in result.matches {
            guard validExerciseIds.contains(match.exerciseId),
                  seen.insert(match.exerciseId).inserted
            else { continue }
            matches.append(match)
        }
        return PhotoMatchResult(matches: matches)
    }
}
