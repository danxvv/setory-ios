//
//  TemplateDraftTests.swift
//  SetoryTests
//
//  Editor draft logic: save validation rules, pre-filling from a saved
//  session, and writing a draft back into a RoutineTemplate.
//

import Foundation
import SwiftData
import Testing
@testable import Setory

struct TemplateDraftTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeExercise(_ id: String, name: String) -> Exercise {
        Exercise(id: id, name: name, category: .strength, primaryMuscles: [.chest])
    }

    // MARK: - Validation

    @Test func emptyOrWhitespaceNameIsNotSavable() {
        let bench = makeExercise("bench-press", name: "Bench Press")
        var draft = TemplateDraft(name: "", items: [TemplateDraft.Item(exercise: bench)])
        #expect(!draft.isSavable)
        draft.name = "   \n"
        #expect(!draft.isSavable)
        draft.name = "Push Day"
        #expect(draft.isSavable)
    }

    @Test func draftWithoutExercisesIsNotSavable() {
        var draft = TemplateDraft(name: "Push Day")
        #expect(!draft.isSavable)
        draft.items.append(TemplateDraft.Item(exercise: makeExercise("bench-press", name: "Bench Press")))
        #expect(draft.isSavable)
    }

    @Test func suggestedNameIsNilWithoutExercises() {
        #expect(TemplateDraft().suggestedName == nil)
    }

    // MARK: - Pre-fill from a saved session

    @Test func draftFromSessionDeduplicatesInFirstAppearanceOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press", name: "Bench Press")
        let pushdown = makeExercise("triceps-pushdown", name: "Triceps Pushdown")
        context.insert(bench)
        context.insert(pushdown)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        // bench, bench, pushdown, bench: dedup keeps [bench, pushdown]
        // and bench's target is its total series count.
        for (order, exercise) in [bench, bench, pushdown, bench].enumerated() {
            let series = WorkoutSeries(order: order, exercise: exercise, reps: 10)
            series.session = session
            context.insert(series)
        }
        try context.save()

        let draft = TemplateDraft.draft(from: session)
        #expect(draft.items.map(\.exercise?.id) == ["bench-press", "triceps-pushdown"])
        #expect(draft.items.map(\.targetSets) == [3, 1])
        #expect(draft.name.isEmpty)
    }

    @Test func draftFromSessionClampsTargetSetsAndSkipsMissingExercises() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press", name: "Bench Press")
        context.insert(bench)
        let session = WorkoutSession(date: .now)
        context.insert(session)
        for order in 0..<12 {
            let series = WorkoutSeries(order: order, exercise: bench, reps: 10)
            series.session = session
            context.insert(series)
        }
        let orphan = WorkoutSeries(order: 12, exercise: nil, reps: 10)
        orphan.session = session
        context.insert(orphan)
        try context.save()

        let draft = TemplateDraft.draft(from: session)
        #expect(draft.items.count == 1)
        #expect(draft.items.first?.targetSets == 10)
    }

    // MARK: - Apply to a template

    @Test func applyWritesTrimmedNameAndOrderedItems() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press", name: "Bench Press")
        let squat = makeExercise("squat", name: "Squat")
        context.insert(bench)
        context.insert(squat)

        let draft = TemplateDraft(name: "  Push Day  ", items: [
            TemplateDraft.Item(exercise: bench, targetSets: 4),
            TemplateDraft.Item(exercise: squat, targetSets: 2),
        ])
        let template = RoutineTemplate(name: draft.trimmedName)
        context.insert(template)
        draft.apply(to: template, in: context)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<RoutineTemplate>()).first)
        #expect(fetched.name == "Push Day")
        #expect(fetched.orderedItems.map(\.order) == [0, 1])
        #expect(fetched.orderedItems.map(\.exercise?.id) == ["bench-press", "squat"])
        #expect(fetched.orderedItems.map(\.targetSets) == [4, 2])
    }

    @Test func applyReplacesPreviousItems() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press", name: "Bench Press")
        let squat = makeExercise("squat", name: "Squat")
        context.insert(bench)
        context.insert(squat)

        let template = RoutineTemplate(name: "Push Day")
        context.insert(template)
        for order in 0..<3 {
            let item = RoutineTemplateItem(order: order, targetSets: 3, exercise: bench)
            item.template = template
            context.insert(item)
        }
        try context.save()

        // Editing down to a single, different exercise removes the old rows.
        let draft = TemplateDraft(name: "Leg Day", items: [TemplateDraft.Item(exercise: squat, targetSets: 5)])
        draft.apply(to: template, in: context)
        try context.save()

        #expect(template.name == "Leg Day")
        #expect(template.orderedItems.map(\.exercise?.id) == ["squat"])
        #expect(template.orderedItems.map(\.targetSets) == [5])
        #expect(try context.fetch(FetchDescriptor<RoutineTemplateItem>()).count == 1)
    }
}
