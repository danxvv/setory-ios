//
//  SuggestionResponseParser.swift
//  gymapp
//
//  Validates the suggested routine carried by an OpenRouter
//  chat-completion response (envelope decoding and status mapping live in
//  ChatCompletionResponse, shared with photo matching). Client-side
//  validation is the real gate on model output: not every model enforces
//  strict schemas, so unknown exercise IDs are dropped, set counts clamped,
//  and duplicates removed before anything reaches the UI. Pure statics so
//  every error shape unit-tests from JSON fixtures. The shared failure
//  taxonomy lives in AI/Shared/AIError.swift.
//

import Foundation

enum SuggestionResponseParser {
    /// Maps a completed HTTP exchange to a validated routine or a typed
    /// error. `validExerciseIds` are the local store's exercise IDs.
    static func routine(
        from data: Data,
        statusCode: Int,
        validExerciseIds: Set<String>
    ) throws -> SuggestedRoutine {
        let routine = try ChatCompletionResponse.decode(
            SuggestedRoutine.self,
            from: data,
            statusCode: statusCode
        )
        return try validated(routine, validExerciseIds: validExerciseIds)
    }

    /// Non-2xx statuses each map to a typed error; the response body's
    /// error object adds nothing the UI needs beyond the status itself.
    static func error(forStatusCode statusCode: Int) -> AIError? {
        ChatCompletionResponse.error(forStatusCode: statusCode)
    }

    /// Drops items with unknown exercise IDs, clamps target sets to the
    /// template range, and dedupes repeated exercises preserving first
    /// occurrence. Throws when nothing valid remains.
    static func validated(
        _ routine: SuggestedRoutine,
        validExerciseIds: Set<String>
    ) throws -> SuggestedRoutine {
        let range = RoutineTemplateItem.targetSetsRange
        var seen = Set<String>()
        var items: [SuggestedRoutine.Item] = []
        for item in routine.items {
            guard validExerciseIds.contains(item.exerciseId),
                  seen.insert(item.exerciseId).inserted
            else { continue }
            items.append(SuggestedRoutine.Item(
                exerciseId: item.exerciseId,
                targetSets: min(max(item.targetSets, range.lowerBound), range.upperBound)
            ))
        }
        guard !items.isEmpty else { throw AIError.emptySuggestion }
        var validated = routine
        validated.items = items
        return validated
    }
}
