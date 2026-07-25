//
//  ExerciseSearchTests.swift
//  gymappTests
//
//  Covers the shared search predicate (Exercise.matchesSearch) and its use
//  by ExerciseFilters. Search matches either the resolved display name or
//  the canonical English one, so a Spanish user finds an exercise by its
//  Spanish name and by the English name printed on the machine.
//
//  Every assertion that depends on which vocabulary resolves passes its
//  language code explicitly. These tests used to rely on the host simulator
//  being configured in Spanish, which made them pass here and fail on an
//  English machine.
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

    /// The canonical English name is searchable in every language, which is
    /// what lets a Spanish user find an exercise off the machine's label.
    @Test(arguments: ["en", "es", "fr"])
    func canonicalQueryMatchesInAnyLanguage(languageCode: String) {
        #expect(makeBenchPress().matchesSearch("bench press", languageCode: languageCode))
        #expect(makeSquat().matchesSearch("squat", languageCode: languageCode))
    }

    @Test func localizedQueryMatchesViaTheTranslation() {
        // "sentadilla" appears only in the Spanish name.
        let squat = makeSquat()
        #expect(squat.matchesSearch("sentadilla", languageCode: "es"))
        #expect(!squat.name.localizedStandardContains("sentadilla"))
    }

    /// The other side of the same seam: with English resolved, the Spanish
    /// vocabulary is not searchable.
    @Test func localizedQueryDoesNotMatchUnderAnotherLanguage() {
        #expect(!makeSquat().matchesSearch("sentadilla", languageCode: "en"))
        #expect(!makeSquat().matchesSearch("sentadilla", languageCode: "fr"))
    }

    @Test func matchingIgnoresCaseAndDiacritics() {
        #expect(makeSquat().matchesSearch("SENTADILLA", languageCode: "es"))
        #expect(makeSquat().matchesSearch("Sentadilla Completa", languageCode: "es"))
        #expect(makeBenchPress().matchesSearch("BARBELL", languageCode: "en"))
        #expect(makeBenchPress().matchesSearch("BARBELL", languageCode: "es"))
    }

    @Test(arguments: ["en", "es"])
    func emptyQueryMatchesEverything(languageCode: String) {
        #expect(makeBenchPress().matchesSearch("", languageCode: languageCode))
        #expect(makeRun().matchesSearch("", languageCode: languageCode))
    }

    @Test(arguments: ["en", "es"])
    func unrelatedQueryDoesNotMatch(languageCode: String) {
        #expect(!makeBenchPress().matchesSearch("sentadilla", languageCode: languageCode))
        #expect(!makeRun().matchesSearch("press", languageCode: languageCode))
    }

    /// The ambient convenience must agree with the explicit accessor for
    /// whatever language the host happens to be running.
    @Test func ambientConvenienceAgreesWithTheExplicitAccessor() {
        let squat = makeSquat()
        let code = Exercise.contentLanguageCode
        #expect(squat.matchesSearch("squat") == squat.matchesSearch("squat", languageCode: code))
        #expect(squat.matchesSearch("sentadilla") == squat.matchesSearch("sentadilla", languageCode: code))
    }

    @Test(arguments: ["en", "es"])
    func customExerciseWithoutTranslationsStillMatchesItsName(languageCode: String) {
        let custom = Exercise(
            id: "my-custom-move",
            name: "My Custom Move",
            category: .strength,
            primaryMuscles: [.chest]
        )
        #expect(custom.matchesSearch("custom", languageCode: languageCode))
    }

    @Test(arguments: ["en", "es"])
    func userModifiedExerciseMatchesItsStoredName(languageCode: String) {
        let exercise = makeBenchPress()
        exercise.name = "Press banca plano"
        exercise.isUserModified = true

        #expect(exercise.matchesSearch("banca plano", languageCode: languageCode))
        // The frozen exercise no longer resolves its catalog translation.
        #expect(!exercise.matchesSearch("Press de Banca con Barra", languageCode: languageCode))
    }

    @Test func filtersApplySearchInBothVocabularies() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        let filters = ExerciseFilters()

        let spanish = filters.apply(to: exercises, searchText: "sentadilla", languageCode: "es")
        let english = filters.apply(to: exercises, searchText: "squat", languageCode: "es")

        #expect(spanish.map(\.id) == ["gv0043"])
        #expect(english.map(\.id) == ["gv0043"])
    }

    @Test func searchCombinesWithMuscleFilter() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.muscle = .chest

        #expect(filters.apply(to: exercises, searchText: "banca", languageCode: "es").map(\.id) == ["gv0025"])
        // The muscle filter still wins over a name that matches elsewhere.
        #expect(filters.apply(to: exercises, searchText: "sentadilla", languageCode: "es").isEmpty)
    }

    @Test func searchCombinesWithEquipmentFilter() {
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.equipment = .barbell

        // Both vocabularies survive the equipment filter.
        #expect(filters.apply(to: exercises, searchText: "barra", languageCode: "es").map(\.id) == ["gv0025", "gv0043"])
        #expect(filters.apply(to: exercises, searchText: "barbell", languageCode: "es").map(\.id) == ["gv0025", "gv0043"])
        #expect(filters.apply(to: exercises, searchText: "correr", languageCode: "es").isEmpty)
    }

    @Test func filterResultsAreLanguageIndependent() {
        // Filtering runs on raw values, so the set never depends on language.
        let exercises = [makeBenchPress(), makeSquat(), makeRun()]
        var filters = ExerciseFilters()
        filters.muscle = .quads

        for languageCode in ["en", "es", "fr"] {
            #expect(filters.apply(to: exercises, searchText: "", languageCode: languageCode).map(\.id) == ["gv0043"])
        }
    }
}
