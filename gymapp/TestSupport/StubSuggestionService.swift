//
//  StubSuggestionService.swift
//  gymapp
//
//  Deterministic RoutineSuggestionService for unit and UI tests: canned
//  success or failure after an optional delay (the delay keeps the
//  progress state visible and cancellation testable). Never touches the
//  network.
//

import Foundation

struct StubSuggestionService: RoutineSuggestionService {
    enum Outcome: Sendable {
        case success(SuggestedRoutine)
        case failure(SuggestionError)
    }

    var outcome: Outcome
    var delay: Duration = .zero

    func suggestRoutine(request: SuggestionRequestPayload) async throws -> SuggestedRoutine {
        if delay > .zero {
            // Task.sleep throws CancellationError on cancel, matching the
            // live client's cancellation behavior.
            try await Task.sleep(for: delay)
        }
        switch outcome {
        case .success(let routine):
            return routine
        case .failure(let error):
            throw error
        }
    }
}

/// Scenarios behind the `-uitest-ai <scenario>` launch argument.
extension StubSuggestionService {
    /// Catalog IDs here must exist in exercise-catalog.json so validation
    /// and the editor resolve them against the seeded store.
    static let uiTestRoutine = SuggestedRoutine(
        name: "AI Full Body",
        rationale: "Stub rationale: balances chest and legs for UI tests.",
        items: [
            .init(exerciseId: "gv0025", targetSets: 4),
            .init(exerciseId: "gv0043", targetSets: 3),
        ]
    )

    /// "error" fails with a network error; every other scenario (including
    /// "no-key", reachable once a key is saved in-session) succeeds.
    static func uiTestService(scenario: String) -> StubSuggestionService {
        switch scenario {
        case "error":
            StubSuggestionService(outcome: .failure(.network), delay: .milliseconds(500))
        default:
            StubSuggestionService(outcome: .success(uiTestRoutine), delay: .milliseconds(500))
        }
    }
}
