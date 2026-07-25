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
//  every error shape unit-tests from JSON fixtures.
//

import Foundation

/// Every way a suggestion can fail, each with a localized message.
/// Key- and credit-related cases steer the user to AI Settings.
enum SuggestionError: Error, Equatable, LocalizedError {
    case missingAPIKey
    case network
    case invalidKey
    case insufficientCredits
    case rateLimited
    case badResponse
    case emptySuggestion

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            String(localized: "An OpenRouter API key is required.")
        case .network:
            String(localized: "Couldn't reach OpenRouter. Check your connection and try again.")
        case .invalidKey:
            String(localized: "Your API key appears to be invalid. Update it in AI Settings.")
        case .insufficientCredits:
            String(localized: "Your OpenRouter account is out of credits. Add credits or update the key in AI Settings.")
        case .rateLimited:
            String(localized: "Too many requests right now. Try again in a moment.")
        case .badResponse:
            String(localized: "OpenRouter returned an unexpected response. Try again.")
        case .emptySuggestion:
            String(localized: "The model didn't suggest any usable exercises. Try again.")
        }
    }

    /// True for failures the user fixes in AI Settings rather than by retrying.
    var pointsToSettings: Bool {
        switch self {
        case .missingAPIKey, .invalidKey, .insufficientCredits: true
        case .network, .rateLimited, .badResponse, .emptySuggestion: false
        }
    }
}

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
    static func error(forStatusCode statusCode: Int) -> SuggestionError? {
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
        guard !items.isEmpty else { throw SuggestionError.emptySuggestion }
        var validated = routine
        validated.items = items
        return validated
    }
}
