//
//  PersistenceStoreTests.swift
//  SetoryTests
//
//  The write paths, now that they live in stores rather than view bodies.
//  Before the restructure none of this was reachable from a unit test: the
//  draft-to-session conversion, template duplication, and the exercise-edit
//  flag all sat inside SwiftUI views.
//
//  Rollback is driven through the stores' commit seam. SwiftData upserts on a
//  unique-constraint conflict instead of failing (verified: a duplicate
//  session date collapses to one row and save() does not throw), so there is
//  no natural way to make a real save fail.
//

import Foundation
import SwiftData
import Testing
@testable import Setory

struct PersistenceStoreTests {
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
    }

    private func makeContext() -> ModelContext { ModelContext(container) }

    private struct CommitFailure: Error {}

    /// A commit that always fails, for the rollback paths.
    private let failingCommit: (ModelContext) throws -> Void = { _ in throw CommitFailure() }

    private func makeExercises(in context: ModelContext) -> (bench: Exercise, squat: Exercise, run: Exercise) {
        let bench = Exercise(
            id: "bench", name: "Bench Press", category: .strength,
            primaryMuscles: [.chest], secondaryMuscles: [.triceps]
        )
        let squat = Exercise(
            id: "squat", name: "Squat", category: .strength,
            primaryMuscles: [.quads], secondaryMuscles: [.glutes]
        )
        let run = Exercise(id: "run", name: "Run", category: .cardio, primaryMuscles: [.fullBody])
        [bench, squat, run].forEach(context.insert)
        return (bench, squat, run)
    }

    // MARK: - WorkoutStore

    @Test func finishDayPersistsDraftsInOrderWithTheirValues() throws {
        let context = makeContext()
        let (bench, _, run) = makeExercises(in: context)
        let day = Calendar.current.startOfDay(for: .now)

        let drafts = [
            DraftSeries(exercise: bench, reps: 10, weightKg: 40),
            DraftSeries(exercise: bench, reps: 8, weightKg: 45),
            DraftSeries(exercise: run, durationSeconds: 900),
        ]
        try WorkoutStore(context: context).finishDay(date: day, drafts: drafts)

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        let session = try #require(sessions.first)
        #expect(session.date == day)

        let series = session.orderedSeries
        #expect(series.map(\.order) == [0, 1, 2])
        #expect(series.map { $0.exercise?.id } == ["bench", "bench", "run"])
        #expect(series.map(\.reps) == [10, 8, nil])
        #expect(series.map(\.weightKg) == [40, 45, nil])
        #expect(series.map(\.durationSeconds) == [nil, nil, 900])
    }

    /// The session date is normalized to start-of-day by the entity; a draft
    /// logged against an afternoon timestamp must still land on that day.
    @Test func finishDayNormalizesTheSessionDate() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        let calendar = Calendar.current
        let afternoon = try #require(
            calendar.date(bySettingHour: 15, minute: 30, second: 0, of: .now)
        )

        try WorkoutStore(context: context).finishDay(
            date: afternoon, drafts: [DraftSeries(exercise: bench, reps: 5)]
        )

        let session = try #require(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(session.date == calendar.startOfDay(for: afternoon))
    }

    @Test func finishDayWithNoDraftsPersistsAnEmptySession() throws {
        let context = makeContext()
        try WorkoutStore(context: context).finishDay(
            date: Calendar.current.startOfDay(for: .now), drafts: []
        )
        let session = try #require(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(session.series.isEmpty)
    }

    @Test func failedFinishDayRollsBackToPreOperationContents() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        try context.save()
        let sessionsBefore = try context.fetchCount(FetchDescriptor<WorkoutSession>())
        let exercisesBefore = try context.fetchCount(FetchDescriptor<Exercise>())

        let store = WorkoutStore(context: context, commit: failingCommit)
        #expect(throws: CommitFailure.self) {
            try store.finishDay(
                date: Calendar.current.startOfDay(for: .now),
                drafts: [DraftSeries(exercise: bench, reps: 10, weightKg: 40)]
            )
        }

        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == sessionsBefore)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSeries>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == exercisesBefore)
    }

    // MARK: - TemplateStore

    @Test func savingANewDraftCreatesATemplateWithOrderedItems() throws {
        let context = makeContext()
        let (bench, squat, _) = makeExercises(in: context)

        let draft = TemplateDraft(name: "  Push Day  ", items: [
            TemplateDraft.Item(exercise: bench, targetSets: 4),
            TemplateDraft.Item(exercise: squat, targetSets: 2),
        ])
        try TemplateStore(context: context).save(draft, to: nil)

        let templates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        #expect(templates.count == 1)
        let template = try #require(templates.first)
        #expect(template.name == "Push Day")
        #expect(template.orderedItems.map { $0.exercise?.id } == ["bench", "squat"])
        #expect(template.orderedItems.map(\.targetSets) == [4, 2])
    }

    @Test func savingAnExistingTemplateReplacesItsItems() throws {
        let context = makeContext()
        let (bench, squat, run) = makeExercises(in: context)
        let store = TemplateStore(context: context)

        let template = try store.save(
            TemplateDraft(name: "Day", items: [TemplateDraft.Item(exercise: bench, targetSets: 3)]),
            to: nil
        )
        try store.save(
            TemplateDraft(name: "Day", items: [
                TemplateDraft.Item(exercise: squat, targetSets: 5),
                TemplateDraft.Item(exercise: run, targetSets: 1),
            ]),
            to: template
        )

        #expect(template.orderedItems.map { $0.exercise?.id } == ["squat", "run"])
        // Replaced items are deleted, not orphaned.
        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplateItem>()) == 2)
    }

    @Test func duplicatePreservesOrderTargetsAndDerivedMuscleCoverage() throws {
        let context = makeContext()
        let (bench, squat, _) = makeExercises(in: context)
        let store = TemplateStore(context: context)

        let original = try store.save(
            TemplateDraft(name: "Leg & Chest", items: [
                TemplateDraft.Item(exercise: squat, targetSets: 5),
                TemplateDraft.Item(exercise: bench, targetSets: 3),
            ]),
            to: nil
        )
        let copy = try store.duplicate(original)

        #expect(copy.orderedItems.map { $0.exercise?.id } == ["squat", "bench"])
        #expect(copy.orderedItems.map(\.targetSets) == [5, 3])
        // Coverage is derived from the exercises, so it must match exactly.
        #expect(copy.primaryMusclesCovered == original.primaryMusclesCovered)
        #expect(copy.secondaryMusclesCovered == original.secondaryMusclesCovered)
        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplate>()) == 2)
        // The copy is a distinct record, not an alias.
        #expect(copy.persistentModelID != original.persistentModelID)
    }

    @Test func deleteRemovesTheTemplateAndItsItemsButNotSavedSessions() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        let templateStore = TemplateStore(context: context)

        let template = try templateStore.save(
            TemplateDraft(name: "Day", items: [TemplateDraft.Item(exercise: bench, targetSets: 3)]),
            to: nil
        )
        try WorkoutStore(context: context).finishDay(
            date: Calendar.current.startOfDay(for: .now),
            drafts: [DraftSeries(exercise: bench, reps: 10, weightKg: 40)]
        )

        try templateStore.delete(template)

        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplate>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplateItem>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSeries>()) == 1)
        // The exercise the template referenced survives too.
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 3)
    }

    @Test func failedDuplicateRollsBack() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        let original = try TemplateStore(context: context).save(
            TemplateDraft(name: "Day", items: [TemplateDraft.Item(exercise: bench, targetSets: 3)]),
            to: nil
        )

        let failing = TemplateStore(context: context, commit: failingCommit)
        #expect(throws: CommitFailure.self) {
            try failing.duplicate(original)
        }

        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplate>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<RoutineTemplateItem>()) == 1)
    }

    // MARK: - ExerciseStore

    private func edit(
        name: String = "Custom Bench",
        category: ExerciseCategory = .strength,
        primary: Set<Muscle> = [.chest],
        secondary: Set<Muscle> = [.triceps],
        summary: String = "A pressing movement.",
        steps: [String] = ["Lie down.", "Press up."]
    ) -> ExerciseEdit {
        ExerciseEdit(
            name: name, category: category,
            primarySelection: primary, secondarySelection: secondary,
            summary: summary, steps: steps
        )
    }

    @Test func savingAnEditWritesEveryFieldAndMarksUserModified() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        try context.save()
        #expect(!bench.isUserModified)

        try ExerciseStore(context: context).save(
            edit(name: "Barbell Bench", category: .strength, primary: [.chest, .shoulders]),
            to: bench
        )

        #expect(bench.name == "Barbell Bench")
        #expect(bench.category == .strength)
        #expect(bench.primaryMuscles == [.chest, .shoulders])
        #expect(bench.secondaryMuscles == [.triceps])
        #expect(bench.summary == "A pressing movement.")
        #expect(bench.instructionSteps == ["Lie down.", "Press up."])
        #expect(bench.isUserModified)
    }

    /// Rollback's guarantee is about the *store*, not about the live object:
    /// SwiftData discards the pending write, but the in-memory instance keeps
    /// the mutated values, so the check has to read through a fresh context.
    /// This matches the behavior the view code had before the restructure.
    @Test func failedEditPersistsNothing() throws {
        let context = makeContext()
        let (bench, _, _) = makeExercises(in: context)
        try context.save()

        let failing = ExerciseStore(context: context, commit: failingCommit)
        #expect(throws: CommitFailure.self) {
            try failing.save(edit(name: "Should Not Persist"), to: bench)
        }

        let fresh = makeContext()
        let stored = try #require(
            try fresh.fetch(FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == "bench" })).first
        )
        #expect(stored.name == "Bench Press")
        #expect(!stored.isUserModified)
        #expect(stored.primaryMuscles == [.chest])
    }

    // MARK: - ExerciseEdit normalization

    @Test func editTrimsNameAndSummaryAndDropsBlankSteps() {
        let normalized = edit(
            name: "  Barbell Bench  ",
            summary: "  A pressing movement.  ",
            steps: ["  Lie down.  ", "   ", "", "Press up."]
        )
        #expect(normalized.name == "Barbell Bench")
        #expect(normalized.summary == "A pressing movement.")
        #expect(normalized.instructionSteps == ["Lie down.", "Press up."])
    }

    @Test func editOrdersMusclesCanonicallyAndExcludesPrimaryFromSecondary() {
        let normalized = edit(
            primary: [.quads, .chest],
            secondary: [.chest, .calves, .triceps]
        )
        // Muscle.allCases order: chest … triceps … calves
        #expect(normalized.primaryMuscles == [.chest, .quads])
        #expect(normalized.secondaryMuscles == [.triceps, .calves])
        #expect(!normalized.secondaryMuscles.contains(.chest))
    }

    @Test func editRequiresANameAndAPrimaryMuscle() {
        #expect(edit().isValid)
        #expect(!edit(name: "   ").isValid)
        #expect(!edit(primary: []).isValid)
    }

    /// The no-op guard: re-saving the values the form opened with must not
    /// mark the exercise user-modified, or merely visiting edit mode would
    /// freeze its localization.
    @Test func anUnchangedEditIsDetectedAsChangingNothing() {
        let displayed = edit()
        #expect(edit() == displayed)
        #expect(edit(name: "Something Else") != displayed)
        #expect(edit(steps: ["Lie down."]) != displayed)
        #expect(edit(primary: [.chest, .shoulders]) != displayed)
    }
}
