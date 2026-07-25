//
//  PhotoMatchFlow.swift
//  gymapp
//
//  The work behind "Match from Photo": preprocess the photos, narrow the
//  catalog, call the REST client, and resolve the returned ids back to local
//  records. Lives outside the sheet for the same reason as SuggestionFlow —
//  so the fetch/build/call/resolve cycle is testable without UI.
//

import Foundation
import SwiftData
import UIKit

@MainActor
@Observable
final class PhotoMatchFlow {
    /// A validated match paired with its local record — the only source of
    /// name, muscles, and thumbnail.
    struct Match: Identifiable {
        let exercise: Exercise
        let confidence: PhotoMatchConfidence

        var id: String { exercise.id }
    }

    /// Capture and results live in one sheet; loading is tracked separately so
    /// the attached photos stay visible underneath.
    enum Phase {
        case capture
        case results([Match])
    }

    /// What a completed request produced. An empty catalog is not a failure:
    /// it means the muscle selection is a dead end and the UI says so instead.
    enum Outcome {
        case matches([Match])
        case emptyCatalog
    }

    private(set) var phase: Phase = .capture
    private(set) var isMatching = false
    var error: AIError?
    /// How many stored exercises the selected muscle keeps. nil means no
    /// muscle is selected; 0 means the selection is a dead end — sending it
    /// would ship an empty schema enum, which OpenRouter rejects.
    private(set) var muscleMatchCount: Int?

    private var task: Task<Void, Never>?

    /// A muscle no stored exercise targets: the request is blocked rather
    /// than sent with an empty id enum.
    var hasEmptyMuscleSelection: Bool { muscleMatchCount == 0 }

    func returnToCapture() {
        phase = .capture
    }

    /// Recomputed whenever the selection changes so the blocked state shows
    /// before the user taps send. The store is small enough to filter in
    /// memory, and the flow already fetches it wholesale to match.
    func refreshMuscleMatchCount(muscle: Muscle?, context: ModelContext) {
        guard let muscle else {
            muscleMatchCount = nil
            return
        }
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        muscleMatchCount = PhotoMatchRequestBuilder
            .matchingExercises(exercises, muscle: muscle)
            .count
    }

    func cancel() {
        task?.cancel()
    }

    /// Starts a match. On success the flow moves to its results phase; a dead-
    /// end muscle selection surfaces as the blocked state instead of an error.
    func findMatches(
        photos: [UIImage],
        description: String,
        muscle: Muscle?,
        context: ModelContext,
        service: any PhotoExerciseMatchService,
        onResults: @escaping () -> Void
    ) {
        error = nil
        guard !photos.isEmpty, !hasEmptyMuscleSelection else { return }
        isMatching = true
        task = Task { [weak self] in
            defer { self?.isMatching = false }
            do {
                let outcome = try await Self.match(
                    photos: photos,
                    description: description,
                    muscle: muscle,
                    context: context,
                    service: service
                )
                switch outcome {
                case .matches(let matches):
                    self?.phase = .results(matches)
                    onResults()
                case .emptyCatalog:
                    self?.muscleMatchCount = 0
                }
            } catch is CancellationError {
                // User cancelled: back to the attached photos, no alert.
            } catch let error as AIError {
                self?.error = error
            } catch {
                self?.error = .badResponse
            }
        }
    }

    /// The whole request cycle as a throwing async function, with no view and
    /// no observable state — this is what the unit tests drive.
    ///
    /// Name, muscles, and media always come from the local Exercise records,
    /// never from the model; ids the store doesn't know are dropped.
    static func match(
        photos: [UIImage],
        description: String,
        muscle: Muscle?,
        context: ModelContext,
        service: any PhotoExerciseMatchService
    ) async throws -> Outcome {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let jpegs = photos.compactMap(PhotoPreprocessor.jpegData(from:))
        guard !jpegs.isEmpty else { throw AIError.badResponse }

        let payload = PhotoMatchRequestBuilder.payload(
            exercises: exercises,
            photos: jpegs,
            description: description,
            muscle: muscle
        )
        // A muscle nothing targets would ship an empty id enum, which
        // OpenRouter rejects; report it instead of sending.
        guard !payload.catalog.isEmpty else { return .emptyCatalog }

        let result = try await service.matchExercises(request: payload)

        let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        let matches = result.matches.compactMap { match in
            exercisesById[match.exerciseId].map {
                Match(exercise: $0, confidence: match.confidence)
            }
        }
        return .matches(matches)
    }
}
