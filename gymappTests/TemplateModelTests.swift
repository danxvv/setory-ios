//
//  TemplateModelTests.swift
//  gymappTests
//
//  RoutineTemplate persistence: CRUD + cascade delete, item ordering,
//  target-set clamping, derived muscle coverage, and name suggestion.
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct TemplateModelTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func addItem(
        _ exercise: Exercise?,
        to template: RoutineTemplate,
        order: Int,
        targetSets: Int = 3,
        context: ModelContext
    ) {
        let item = RoutineTemplateItem(order: order, targetSets: targetSets, exercise: exercise)
        item.template = template
        context.insert(item)
    }

    @Test func templateCreationPersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        let squat = Exercise(id: "squat", name: "Squat", category: .strength, primaryMuscles: [.quads])
        context.insert(bench)
        context.insert(squat)

        let template = RoutineTemplate(name: "Push Day")
        context.insert(template)
        addItem(bench, to: template, order: 0, targetSets: 4, context: context)
        addItem(squat, to: template, order: 1, targetSets: 2, context: context)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<RoutineTemplate>()).first)
        #expect(fetched.name == "Push Day")
        let ordered = fetched.orderedItems
        #expect(ordered.count == 2)
        #expect(ordered.map(\.exercise?.id) == ["bench-press", "squat"])
        #expect(ordered.map(\.targetSets) == [4, 2])
    }

    @Test func orderedItemsSortByOrderColumn() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        context.insert(bench)
        let template = RoutineTemplate(name: "Scrambled")
        context.insert(template)
        addItem(bench, to: template, order: 2, context: context)
        addItem(bench, to: template, order: 0, context: context)
        addItem(bench, to: template, order: 1, context: context)
        try context.save()

        #expect(template.orderedItems.map(\.order) == [0, 1, 2])
    }

    @Test func deletingTemplateCascadesToItemsAndSparesExercises() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        context.insert(bench)
        let template = RoutineTemplate(name: "Push Day")
        context.insert(template)
        addItem(bench, to: template, order: 0, context: context)
        addItem(bench, to: template, order: 1, context: context)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<RoutineTemplateItem>()).count == 2)

        context.delete(template)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<RoutineTemplate>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RoutineTemplateItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == 1)
    }

    @Test func targetSetsAreClampedToValidRange() {
        #expect(RoutineTemplateItem(order: 0, targetSets: 0, exercise: nil).targetSets == 1)
        #expect(RoutineTemplateItem(order: 0, targetSets: 15, exercise: nil).targetSets == 10)
        #expect(RoutineTemplateItem(order: 0, targetSets: 5, exercise: nil).targetSets == 5)
        #expect(RoutineTemplateItem(order: 0, exercise: nil).targetSets == 3)
    }

    // MARK: - Muscle coverage

    @Test func primaryCoverageIsUnionInFirstAppearanceOrder() {
        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        let lunge = Exercise(id: "lunge", name: "Lunge", category: .strength, primaryMuscles: [.quads, .glutes])
        let squat = Exercise(id: "squat", name: "Squat", category: .strength, primaryMuscles: [.quads])

        let covered = RoutineTemplate.primaryMusclesCovered(by: [bench, lunge, squat])
        #expect(covered == [.chest, .quads, .glutes])
    }

    @Test func secondaryCoverageExcludesPrimaryMuscles() {
        // Bench press: primary chest; secondary shoulders, triceps.
        // Triceps pushdown: primary triceps.
        let bench = Exercise(
            id: "bench-press",
            name: "Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps]
        )
        let pushdown = Exercise(
            id: "triceps-pushdown",
            name: "Triceps Pushdown",
            category: .strength,
            primaryMuscles: [.triceps]
        )

        let exercises = [bench, pushdown]
        #expect(RoutineTemplate.primaryMusclesCovered(by: exercises) == [.chest, .triceps])
        // Triceps is already covered as primary, so only shoulders remains.
        #expect(RoutineTemplate.secondaryMusclesCovered(by: exercises) == [.shoulders])
    }

    @Test func coverageSkipsItemsWithMissingExercise() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = Exercise(
            id: "bench-press",
            name: "Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps]
        )
        context.insert(bench)
        let template = RoutineTemplate(name: "Sparse")
        context.insert(template)
        addItem(nil, to: template, order: 0, context: context)
        addItem(bench, to: template, order: 1, context: context)
        try context.save()

        #expect(template.orderedItems.count == 2)
        #expect(template.exercises.map(\.id) == ["bench-press"])
        #expect(template.primaryMusclesCovered == [.chest])
        #expect(template.secondaryMusclesCovered == [.triceps])
    }
}

/// Pure-function name suggestion. Expected values are built through the same
/// localization tables the suggester uses, so assertions hold in any test
/// locale while still verifying which muscles were selected and in what order.
struct TemplateNameSuggesterTests {
    private func exercise(
        _ id: String,
        primary: [Muscle],
        category: ExerciseCategory = .strength
    ) -> Exercise {
        Exercise(id: id, name: id, category: category, primaryMuscles: primary)
    }

    @Test func emptyExerciseListSuggestsNothing() {
        #expect(TemplateNameSuggester.suggestedName(for: []) == nil)
    }

    @Test func dominantMusclesJoinTopTwoByVotes() {
        // Chest gets two votes, triceps one; shoulders never appears.
        let exercises = [
            exercise("bench-press", primary: [.chest]),
            exercise("incline-bench-press", primary: [.chest]),
            exercise("triceps-pushdown", primary: [.triceps]),
        ]
        let expected = String(localized: "\(Muscle.chest.displayName) & \(Muscle.triceps.displayName)")
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == expected)
    }

    @Test func singleMuscleSuggestsJustThatMuscle() {
        let exercises = [exercise("bench-press", primary: [.chest])]
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == Muscle.chest.displayName)
    }

    @Test func tieKeepsFirstAppearanceOrder() {
        let exercises = [
            exercise("bench-press", primary: [.chest]),
            exercise("lat-pulldown", primary: [.lats]),
        ]
        let expected = String(localized: "\(Muscle.chest.displayName) & \(Muscle.lats.displayName)")
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == expected)
    }

    @Test func lowerBodyMajoritySuggestsLegDay() {
        let exercises = [
            exercise("squat", primary: [.quads]),
            exercise("leg-curl", primary: [.hamstrings]),
            exercise("bench-press", primary: [.chest]),
        ]
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == String(localized: "Leg Day"))
    }

    @Test func allCardioSuggestsCardio() {
        let exercises = [
            exercise("treadmill-run", primary: [.fullBody], category: .cardio),
            exercise("rowing-machine", primary: [.fullBody], category: .cardio),
        ]
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == String(localized: "Cardio"))
    }

    @Test func mixedUpperBodySessionIsNotLegDayOrCardio() {
        // One lower-body vote out of two is not a majority.
        let exercises = [
            exercise("bench-press", primary: [.chest]),
            exercise("squat", primary: [.quads]),
        ]
        let expected = String(localized: "\(Muscle.chest.displayName) & \(Muscle.quads.displayName)")
        #expect(TemplateNameSuggester.suggestedName(for: exercises) == expected)
    }
}
