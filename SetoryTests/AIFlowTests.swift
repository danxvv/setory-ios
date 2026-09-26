//
//  AIFlowTests.swift
//  SetoryTests
//
//  The orchestration behind both AI features, now that it lives in flow types
//  instead of view methods: fetch the store, build the request, call the
//  service, resolve returned ids back to local records. None of this was
//  reachable from a unit test before the restructure — only the prompt
//  builders and response parsers were.
//
//  Driven with stub services and an in-memory container: no network, no UI.
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import Setory

@MainActor
struct AIFlowTests {
    private let container: ModelContainer

    init() throws {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)
        context.insert(Exercise(
            id: "gv0025", name: "Barbell Bench Press", category: .strength,
            primaryMuscles: [.chest], secondaryMuscles: [.triceps], equipment: .barbell
        ))
        context.insert(Exercise(
            id: "gv0043", name: "Barbell Full Squat", category: .strength,
            primaryMuscles: [.quads], secondaryMuscles: [.glutes], equipment: .barbell
        ))
        try context.save()
    }

    private func makeContext() -> ModelContext { ModelContext(container) }

    private func photo() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }
    }

    // MARK: - SuggestionFlow

    @Test func suggestionResolvesItemsAgainstLocalRecords() async throws {
        let routine = SuggestedRoutine(
            name: "Push Day",
            rationale: "Balanced.",
            items: [
                SuggestedRoutine.Item(exerciseId: "gv0025", targetSets: 4),
                SuggestedRoutine.Item(exerciseId: "gv0043", targetSets: 3),
            ]
        )
        let suggestion = try await SuggestionFlow.suggest(
            goal: "legs",
            context: makeContext(),
            service: StubSuggestionService(outcome: .success(routine))
        )

        #expect(suggestion.draft.name == "Push Day")
        #expect(suggestion.rationale == "Balanced.")
        #expect(suggestion.draft.items.map { $0.exercise?.id } == ["gv0025", "gv0043"])
        #expect(suggestion.draft.items.map(\.targetSets) == [4, 3])
        // Muscle metadata comes from the local record, not the model.
        #expect(suggestion.draft.items.first?.exercise?.primaryMuscles == [.chest])
        #expect(suggestion.draft.items.first?.exercise?.secondaryMuscles == [.triceps])
    }

    @Test func suggestionDropsIdsTheStoreDoesNotKnow() async throws {
        let routine = SuggestedRoutine(
            name: "Mixed",
            rationale: "r",
            items: [
                SuggestedRoutine.Item(exerciseId: "gv0025", targetSets: 3),
                SuggestedRoutine.Item(exerciseId: "does-not-exist", targetSets: 3),
            ]
        )
        let suggestion = try await SuggestionFlow.suggest(
            goal: "",
            context: makeContext(),
            service: StubSuggestionService(outcome: .success(routine))
        )
        #expect(suggestion.draft.items.map { $0.exercise?.id } == ["gv0025"])
    }

    @Test func suggestionWithNoResolvableItemsIsAnEmptySuggestion() async throws {
        let routine = SuggestedRoutine(
            name: "Nothing",
            rationale: "r",
            items: [SuggestedRoutine.Item(exerciseId: "does-not-exist", targetSets: 3)]
        )
        await #expect(throws: AIError.emptySuggestion) {
            _ = try await SuggestionFlow.suggest(
                goal: "",
                context: makeContext(),
                service: StubSuggestionService(outcome: .success(routine))
            )
        }
    }

    @Test func suggestionServiceFailuresPropagate() async throws {
        await #expect(throws: AIError.missingAPIKey) {
            _ = try await SuggestionFlow.suggest(
                goal: "",
                context: makeContext(),
                service: StubSuggestionService(outcome: .failure(.missingAPIKey))
            )
        }
    }

    /// The observable wrapper: a failure lands in `error` and clears the
    /// in-flight state, which is what the sheet's alert and progress read.
    @Test func suggestionFlowSurfacesFailuresAsObservableState() async throws {
        let flow = SuggestionFlow()
        let context = makeContext()
        nonisolated(unsafe) var delivered: RoutineSuggestion?

        flow.generate(
            goal: "",
            context: context,
            service: StubSuggestionService(outcome: .failure(.rateLimited))
        ) { delivered = $0 }

        while flow.isGenerating { await Task.yield() }
        #expect(flow.error == .rateLimited)
        #expect(delivered == nil)
    }

    @Test func suggestionFlowDeliversTheSuggestionOnSuccess() async throws {
        let flow = SuggestionFlow()
        nonisolated(unsafe) var delivered: RoutineSuggestion?

        flow.generate(
            goal: "",
            context: makeContext(),
            service: StubSuggestionService(outcome: .success(StubSuggestionService.uiTestRoutine))
        ) { delivered = $0 }

        while flow.isGenerating { await Task.yield() }
        #expect(flow.error == nil)
        #expect(delivered != nil)
    }

    // MARK: - PhotoMatchFlow

    @Test func photoMatchResolvesMatchesAgainstLocalRecords() async throws {
        let result = PhotoMatchResult(matches: [
            PhotoMatch(exerciseId: "gv0025", confidence: .high),
        ])
        let outcome = try await PhotoMatchFlow.match(
            photos: [photo()],
            description: "a bench",
            muscle: nil,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .success(result))
        )

        guard case .matches(let matches) = outcome else {
            Issue.record("expected matches, got \(outcome)")
            return
        }
        #expect(matches.count == 1)
        let match = try #require(matches.first)
        // Name and muscles come from the local record, never the model.
        #expect(match.exercise.name == "Barbell Bench Press")
        #expect(match.exercise.primaryMuscles == [.chest])
        #expect(match.confidence == .high)
    }

    @Test func photoMatchDropsIdsTheStoreDoesNotKnow() async throws {
        let result = PhotoMatchResult(matches: [
            PhotoMatch(exerciseId: "gv0025", confidence: .high),
            PhotoMatch(exerciseId: "does-not-exist", confidence: .low),
        ])
        let outcome = try await PhotoMatchFlow.match(
            photos: [photo()],
            description: "",
            muscle: nil,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .success(result))
        )
        guard case .matches(let matches) = outcome else {
            Issue.record("expected matches")
            return
        }
        #expect(matches.map(\.exercise.id) == ["gv0025"])
    }

    /// An empty match list is a valid answer, not a failure.
    @Test func photoMatchEmptyResultIsSuccess() async throws {
        let outcome = try await PhotoMatchFlow.match(
            photos: [photo()],
            description: "",
            muscle: nil,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .success(PhotoMatchResult(matches: [])))
        )
        guard case .matches(let matches) = outcome else {
            Issue.record("expected matches")
            return
        }
        #expect(matches.isEmpty)
    }

    /// A muscle nothing targets must not be sent: an empty id enum is
    /// rejected by OpenRouter, so the flow reports the dead end instead.
    @Test func photoMatchBlocksAMuscleNoExerciseTargets() async throws {
        let outcome = try await PhotoMatchFlow.match(
            photos: [photo()],
            description: "",
            muscle: .calves,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .success(PhotoMatchResult(matches: [])))
        )
        guard case .emptyCatalog = outcome else {
            Issue.record("expected emptyCatalog, got \(outcome)")
            return
        }
    }

    @Test func photoMatchServiceFailuresPropagate() async throws {
        await #expect(throws: AIError.network) {
            _ = try await PhotoMatchFlow.match(
                photos: [photo()],
                description: "",
                muscle: nil,
                context: makeContext(),
                service: StubPhotoMatchService(outcome: .failure(.network))
            )
        }
    }

    @Test func muscleMatchCountTracksTheSelection() {
        let flow = PhotoMatchFlow()
        let context = makeContext()

        flow.refreshMuscleMatchCount(muscle: nil, context: context)
        #expect(flow.muscleMatchCount == nil)
        #expect(!flow.hasEmptyMuscleSelection)

        flow.refreshMuscleMatchCount(muscle: .chest, context: context)
        #expect(flow.muscleMatchCount == 1)
        #expect(!flow.hasEmptyMuscleSelection)

        // Secondary targets do not qualify: the bench press has triceps as a
        // secondary muscle only.
        flow.refreshMuscleMatchCount(muscle: .triceps, context: context)
        #expect(flow.muscleMatchCount == 0)
        #expect(flow.hasEmptyMuscleSelection)
    }

    @Test func photoMatchFlowReachesItsResultsPhase() async throws {
        let flow = PhotoMatchFlow()
        let result = PhotoMatchResult(matches: [PhotoMatch(exerciseId: "gv0043", confidence: .medium)])

        flow.findMatches(
            photos: [photo()],
            description: "",
            muscle: nil,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .success(result))
        ) {}

        while flow.isMatching { await Task.yield() }
        guard case .results(let matches) = flow.phase else {
            Issue.record("expected results phase")
            return
        }
        #expect(matches.map(\.exercise.id) == ["gv0043"])

        flow.returnToCapture()
        guard case .capture = flow.phase else {
            Issue.record("expected capture phase")
            return
        }
    }

    @Test func photoMatchFlowRefusesToSendWithoutPhotos() async throws {
        let flow = PhotoMatchFlow()
        flow.findMatches(
            photos: [],
            description: "",
            muscle: nil,
            context: makeContext(),
            service: StubPhotoMatchService(outcome: .failure(.network))
        ) {}

        #expect(!flow.isMatching)
        #expect(flow.error == nil)
        guard case .capture = flow.phase else {
            Issue.record("expected capture phase")
            return
        }
    }
}
