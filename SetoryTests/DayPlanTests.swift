//
//  DayPlanTests.swift
//  SetoryTests
//
//  Staging a plan from a template (missing-exercise skip, order, targets)
//  and deriving plan-row progress from the day's draft series.
//

import Foundation
import SwiftData
import Testing
@testable import Setory

struct DayPlanTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeExercise(_ id: String) -> Exercise {
        Exercise(id: id, name: id, category: .strength, primaryMuscles: [.chest])
    }

    @Test func stagingKeepsTemplateOrderAndTargets() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press")
        let squat = makeExercise("squat")
        context.insert(bench)
        context.insert(squat)
        let template = RoutineTemplate(name: "Push Day")
        context.insert(template)
        for (order, pair) in [(squat, 2), (bench, 4)].enumerated() {
            let item = RoutineTemplateItem(order: order, targetSets: pair.1, exercise: pair.0)
            item.template = template
            context.insert(item)
        }
        try context.save()

        let plan = DayPlan.staged(from: template)
        #expect(plan.templateName == "Push Day")
        #expect(plan.exercises.map(\.exercise.id) == ["squat", "bench-press"])
        #expect(plan.exercises.map(\.targetSets) == [2, 4])
    }

    @Test func stagingMergesDuplicateExercisesSummingTargets() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press")
        let squat = makeExercise("squat")
        context.insert(bench)
        context.insert(squat)
        let template = RoutineTemplate(name: "Doubles")
        context.insert(template)
        // bench 3 + squat 2 + bench 4: progress is counted per exercise, so
        // the plan must show one bench row targeting 7, not two rows that
        // both advance with every bench set.
        for (order, pair) in [(bench, 3), (squat, 2), (bench, 4)].enumerated() {
            let item = RoutineTemplateItem(order: order, targetSets: pair.1, exercise: pair.0)
            item.template = template
            context.insert(item)
        }
        try context.save()

        let plan = DayPlan.staged(from: template)
        #expect(plan.exercises.map(\.exercise.id) == ["bench-press", "squat"])
        #expect(plan.exercises.map(\.targetSets) == [7, 2])
    }

    @Test func stagingSkipsItemsWithMissingExercise() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = makeExercise("bench-press")
        context.insert(bench)
        let template = RoutineTemplate(name: "Sparse")
        context.insert(template)
        for (order, exercise) in [nil, bench, nil].enumerated() {
            let item = RoutineTemplateItem(order: order, targetSets: 3, exercise: exercise)
            item.template = template
            context.insert(item)
        }
        try context.save()

        let plan = DayPlan.staged(from: template)
        #expect(plan.exercises.map(\.exercise.id) == ["bench-press"])
    }

    @Test func loggedSetsCountOnlyTheMatchingExercise() {
        let bench = makeExercise("bench-press")
        let squat = makeExercise("squat")
        let pushdown = makeExercise("triceps-pushdown")
        let drafts = [
            DraftSeries(exercise: bench, reps: 10, weightKg: 40),
            DraftSeries(exercise: squat, reps: 8, weightKg: 60),
            DraftSeries(exercise: bench, reps: 8, weightKg: 45),
        ]

        #expect(DayPlan.loggedSets(for: bench, in: drafts) == 2)
        #expect(DayPlan.loggedSets(for: squat, in: drafts) == 1)
        #expect(DayPlan.loggedSets(for: pushdown, in: drafts) == 0)
        #expect(DayPlan.loggedSets(for: bench, in: []) == 0)
    }
}
