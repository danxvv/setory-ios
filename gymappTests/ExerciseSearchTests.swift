//
//  ExerciseSearchTests.swift
//  gymappTests
//
//  Covers the shared search predicate (Exercise.matchesSearch) and its use
//  by ExerciseFilters. Search matches either the resolved display name or
//  the canonical English one, so a Spanish user finds an exercise by its
//  Spanish name and by the English name printed on the machine.
//

import Foundation
import Testing
@testable import gymapp

struct ExerciseSearchTests {
    private func makeBenchPress() -> Exercise {
        Exercise(
            id: "gv0025",
            name: "Barbell Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipment: .barbell,
            nameTranslations: ["es": "Press de Banca con Barra"]
        )
    }

    private func makeSquat() -> Exercise {
        Exercise(
            id: "gv0043",
            name: "Barbell Full Squat",
            category: .strength,
            primaryMuscles: [.quads],
            equipment: .barbell,
            nameTranslations: ["es": "Sentadilla Completa con Barra"]
        )
    }

    private func makeRun() -> Exercise {
        Exercise(
            id: "gv0685",
            name: "Run",
            category: .cardio,
            primaryMuscles: [.fullBody],
            equipment: .bodyWeight,
            nameTranslations: ["es": "Correr"]
        )
    }

    @Test func canonicalQueryMatches() {
        #expect(makeBenchPress().matchesSearch("bench press"))
    }

    @Test func localizedQueryMatchesViaTheTranslation() {
        // "sentadilla" appears only in the Spanish name.
        let squat = makeSquat()
        #expect(squat.matchesSearch("sentadilla"))
        #expect(!squat.name.localizedStandardContains("sentadilla"))
    }

    @Test func matchingIgnoresCaseAndDiacritics() {
        #expect(makeSquat().matchesSearch("SENTADILLA"))
        #expect(makeSquat().matchesSearch("Sentadilla Completa"))
        #expect(makeBenchPress().matchesSearch("BARBELL"))
    }

    @Test func emptyQueryMatchesEverything() {
        #expect(makeBenchPress().matchesSearch(""))
        #expect(makeRun().matchesSearch(""))
    }

    @Test func unrelatedQueryDoesNotMatch() {
        #expect(!makeBenchPress().matchesSearch("sentadilla"))
        #expect(!makeRun().matchesSearch("press"))
    }

    @Test func customExerciseWithoutTranslationsStillMatchesItsName() {
        let custom = Exercise(
            id: "my-custom-move",
            name: "My Custom Move",
            category: .strength,
            primaryMuscles: [.chest]
        )
        #expect(custom.matchesSearch("custom"))
    }

    @Test func userModifiedExerciseMatchesItsStoredName() {
        let exercise = makeBenchPress()
        exercise.name = "Press banca plano"
        exercise.isUserModified = true

        #expect(exercise.matchesSearch("banca plano"))
        // The frozen exercise no longer resolves its catalog translation.
        #expect(!exercise.matchesSearch("Press de Banca con Barra"))
    }

    @Test func filtersApplySearchInBothVocabularies() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        let filters = ExerciseFilters()

        let spanish = filters.apply(to: exercises, searchText: "sentadilla")
        let english = filters.apply(to: exercises, searchText: "squat")

        #expect(spanish.map(\.id) == ["gv0043"])
        #expect(english.map(\.id) == ["gv0043"])
    }

    @Test func searchCombinesWithMuscleFilter() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.muscle = .chest

        #expect(filters.apply(to: exercises, searchText: "banca").map(\.id) == ["gv0025"])
        // The muscle filter still wins over a name that matches elsewhere.
        #expect(filters.apply(to: exercises, searchText: "sentadilla").isEmpty)
    }

    @Test func searchCombinesWithEquipmentFilter() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.equipment = .barbell

        // Both vocabularies survive the equipment filter.
        #expect(filters.apply(to: exercises, searchText: "barra").map(\.id) == ["gv0025", "gv0043"])
        #expect(filters.apply(to: exercises, searchText: "barbell").map(\.id) == ["gv0025", "gv0043"])
        #expect(filters.apply(to: exercises, searchText: "correr").isEmpty)
    }

    @Test func filterResultsAreLanguageIndependent() {
        // Filtering runs on raw values, so the set never depends on language.
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.muscle = .quads

        #expect(filters.apply(to: exercises, searchText: "").map(\.id) == ["gv0043"])
    }
}
