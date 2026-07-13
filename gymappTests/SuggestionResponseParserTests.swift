//
//  SuggestionResponseParserTests.swift
//  gymappTests
//
//  Response decoding and validation against OpenRouter fixture shapes:
//  success envelopes, HTTP error statuses (401/402/429), the embedded
//  finish_reason == "error" case, malformed JSON, and the catalog-ID /
//  set-clamping / dedupe rules from the spec.
//

import Foundation
import Testing
@testable import gymapp

struct SuggestionResponseParserTests {
    private let catalogIds: Set<String> = ["bench-press", "squat", "plank"]

    /// A 200 envelope whose message content is `routine` JSON-encoded,
    /// mirroring how chat completions nest JSON inside a string.
    private func successEnvelope(routine: [String: Any]) throws -> Data {
        let content = String(decoding: try JSONSerialization.data(withJSONObject: routine), as: UTF8.self)
        let envelope: [String: Any] = [
            "id": "gen-123",
            "choices": [[
                "message": ["role": "assistant", "content": content],
                "finish_reason": "stop",
            ]],
        ]
        return try JSONSerialization.data(withJSONObject: envelope)
    }

    private func routineJSON(items: [[String: Any]]) -> [String: Any] {
        ["name": "Push Day", "rationale": "Balances recent leg work.", "items": items]
    }

    // MARK: - Success

    @Test func validResponseDecodes() throws {
        let data = try successEnvelope(routine: routineJSON(items: [
            ["exerciseId": "bench-press", "targetSets": 4],
            ["exerciseId": "plank", "targetSets": 3],
        ]))
        let routine = try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        #expect(routine.name == "Push Day")
        #expect(routine.rationale == "Balances recent leg work.")
        #expect(routine.items.map(\.exerciseId) == ["bench-press", "plank"])
        #expect(routine.items.map(\.targetSets) == [4, 3])
    }

    // MARK: - Validation

    @Test func unknownExerciseIdsAreDropped() throws {
        let data = try successEnvelope(routine: routineJSON(items: [
            ["exerciseId": "bench-press", "targetSets": 4],
            ["exerciseId": "nonexistent-exercise", "targetSets": 3],
        ]))
        let routine = try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        #expect(routine.items.map(\.exerciseId) == ["bench-press"])
    }

    @Test func targetSetsAreClampedToTemplateRange() throws {
        let data = try successEnvelope(routine: routineJSON(items: [
            ["exerciseId": "bench-press", "targetSets": 15],
            ["exerciseId": "squat", "targetSets": 0],
        ]))
        let routine = try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        #expect(routine.items.map(\.targetSets) == [10, 1])
    }

    @Test func repeatedExercisesKeepFirstOccurrence() throws {
        let data = try successEnvelope(routine: routineJSON(items: [
            ["exerciseId": "squat", "targetSets": 5],
            ["exerciseId": "bench-press", "targetSets": 3],
            ["exerciseId": "squat", "targetSets": 2],
        ]))
        let routine = try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        #expect(routine.items.map(\.exerciseId) == ["squat", "bench-press"])
        #expect(routine.items.first?.targetSets == 5)
    }

    @Test func entirelyInvalidItemsFailAsEmptySuggestion() throws {
        let data = try successEnvelope(routine: routineJSON(items: [
            ["exerciseId": "made-up", "targetSets": 3],
            ["exerciseId": "also-made-up", "targetSets": 4],
        ]))
        #expect(throws: SuggestionError.emptySuggestion) {
            try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        }
    }

    // MARK: - HTTP error statuses (OpenRouter error-body fixtures)

    private func errorBody(_ message: String, code: Int) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["error": ["message": message, "code": code]])
    }

    @Test func status401MapsToInvalidKey() throws {
        let data = try errorBody("No auth credentials found", code: 401)
        #expect(throws: SuggestionError.invalidKey) {
            try SuggestionResponseParser.routine(from: data, statusCode: 401, validExerciseIds: catalogIds)
        }
    }

    @Test func status402MapsToInsufficientCredits() throws {
        let data = try errorBody("Insufficient credits", code: 402)
        #expect(throws: SuggestionError.insufficientCredits) {
            try SuggestionResponseParser.routine(from: data, statusCode: 402, validExerciseIds: catalogIds)
        }
    }

    @Test func status429MapsToRateLimited() throws {
        let data = try errorBody("Rate limit exceeded", code: 429)
        #expect(throws: SuggestionError.rateLimited) {
            try SuggestionResponseParser.routine(from: data, statusCode: 429, validExerciseIds: catalogIds)
        }
    }

    @Test func otherErrorStatusesMapToBadResponse() throws {
        let data = try errorBody("Internal error", code: 500)
        #expect(throws: SuggestionError.badResponse) {
            try SuggestionResponseParser.routine(from: data, statusCode: 500, validExerciseIds: catalogIds)
        }
    }

    // MARK: - Embedded and malformed failures

    /// OpenRouter can report a provider failure inside a 200 response.
    @Test func embeddedFinishReasonErrorMapsToBadResponse() throws {
        let envelope: [String: Any] = [
            "choices": [[
                "message": ["role": "assistant", "content": ""],
                "finish_reason": "error",
                "error": ["code": 502, "message": "Provider returned error"],
            ]],
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        #expect(throws: SuggestionError.badResponse) {
            try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        }
    }

    @Test func topLevelErrorInA200MapsToBadResponse() throws {
        let data = try errorBody("Bad gateway", code: 502)
        #expect(throws: SuggestionError.badResponse) {
            try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        }
    }

    @Test func malformedJSONMapsToBadResponse() {
        let data = Data("not json at all".utf8)
        #expect(throws: SuggestionError.badResponse) {
            try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        }
    }

    @Test func contentThatIsNotARoutineMapsToBadResponse() throws {
        let envelope: [String: Any] = [
            "choices": [[
                "message": ["role": "assistant", "content": "Sorry, I can't help with that."],
                "finish_reason": "stop",
            ]],
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        #expect(throws: SuggestionError.badResponse) {
            try SuggestionResponseParser.routine(from: data, statusCode: 200, validExerciseIds: catalogIds)
        }
    }

    // MARK: - Error affordances

    @Test func keyAndCreditErrorsPointToSettings() {
        #expect(SuggestionError.invalidKey.pointsToSettings)
        #expect(SuggestionError.insufficientCredits.pointsToSettings)
        #expect(SuggestionError.missingAPIKey.pointsToSettings)
        #expect(!SuggestionError.network.pointsToSettings)
        #expect(!SuggestionError.emptySuggestion.pointsToSettings)
    }
}
