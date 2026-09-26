//
//  SuggestionFlow.swift
//  Setory
//
//  The work behind "Suggest with AI": read the local store, build the request,
//  call the REST client, and resolve the returned exercise ids back to local
//  records. Lives outside the sheet so all of it is reachable from unit tests
//  — while this was a method on the view, only the prompt builder and the
//  response parser could be tested.
//
//  Dependencies arrive as method parameters rather than through init:
//  @Environment values aren't available when a @State initial value is built,
//  so an init-injected model would need a configure(...) call from .task —
//  a lifecycle step that is easy to forget and awkward to assert.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class SuggestionFlow {
    /// True while a request is in flight; drives the progress state.
    private(set) var isGenerating = false
    /// The failure to show, if any. Settable so the alert can clear it.
    var error: AIError?

    private var task: Task<Void, Never>?

    /// Starts a generation, handing the validated suggestion to `onSuccess`.
    /// Cancelling returns silently: the user asked to stop, which is not an
    /// error worth an alert.
    func generate(
        goal: String,
        context: ModelContext,
        service: any RoutineSuggestionService,
        onSuccess: @escaping (RoutineSuggestion) -> Void
    ) {
        error = nil
        isGenerating = true
        task = Task { [weak self] in
            defer { self?.isGenerating = false }
            do {
                let suggestion = try await Self.suggest(goal: goal, context: context, service: service)
                onSuccess(suggestion)
            } catch is CancellationError {
                // User cancelled: back to the sheet, no error alert.
            } catch let error as AIError {
                self?.error = error
            } catch {
                self?.error = .badResponse
            }
        }
    }

    func cancel() {
        task?.cancel()
    }

    /// The whole request cycle as a throwing async function, with no view and
    /// no observable state — this is what the unit tests drive.
    ///
    /// Muscle metadata for accepted items is resolved from the local Exercise
    /// records, never from the model response.
    static func suggest(
        goal: String,
        context: ModelContext,
        service: any RoutineSuggestionService
    ) async throws -> RoutineSuggestion {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        var descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = SuggestionPromptBuilder.maxHistorySessions
        let sessions = try context.fetch(descriptor)

        let payload = SuggestionPromptBuilder.payload(
            exercises: exercises,
            sessions: sessions,
            goal: goal
        )
        let routine = try await service.suggestRoutine(request: payload)

        // Resolve suggested IDs to local records; unknown ids are dropped.
        let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        let items = routine.items.compactMap { item in
            exercisesById[item.exerciseId].map {
                TemplateDraft.Item(exercise: $0, targetSets: item.targetSets)
            }
        }
        guard !items.isEmpty else { throw AIError.emptySuggestion }

        return RoutineSuggestion(
            draft: TemplateDraft(name: routine.name, items: items),
            rationale: routine.rationale
        )
    }
}
