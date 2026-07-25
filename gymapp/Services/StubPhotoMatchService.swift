//
//  StubPhotoMatchService.swift
//  gymapp
//
//  Deterministic PhotoExerciseMatchService for unit and UI tests: canned
//  success or failure after an optional delay (the delay keeps the
//  progress state visible and cancellation testable). Never touches the
//  network.
//

import Foundation

struct StubPhotoMatchService: PhotoExerciseMatchService {
    enum Outcome: Sendable {
        case success(PhotoMatchResult)
        case failure(SuggestionError)
    }

    var outcome: Outcome
    var delay: Duration = .zero

    func matchExercises(request: PhotoMatchRequestPayload) async throws -> PhotoMatchResult {
        if delay > .zero {
            // Task.sleep throws CancellationError on cancel, matching the
            // live client's cancellation behavior.
            try await Task.sleep(for: delay)
        }
        switch outcome {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}

/// Scenarios behind the `-uitest-photo-match <scenario>` launch argument.
extension StubPhotoMatchService {
    /// Catalog IDs here must exist in exercise-catalog.json so the results
    /// list resolves them against the seeded store.
    static let uiTestResult = PhotoMatchResult(matches: [
        .init(exerciseId: "gv0025", confidence: .high),
        .init(exerciseId: "gv0043", confidence: .medium),
    ])

    /// "error" fails with a network error; every other scenario (including
    /// "no-key", reachable once a key is saved in-session) succeeds.
    static func uiTestService(scenario: String) -> StubPhotoMatchService {
        switch scenario {
        case "error":
            StubPhotoMatchService(outcome: .failure(.network), delay: .milliseconds(500))
        default:
            StubPhotoMatchService(outcome: .success(uiTestResult), delay: .milliseconds(500))
        }
    }
}
