//
//  SuggestionPromptBuilderTests.swift
//  SetoryTests
//
//  Payload and request-body assembly: catalog muscle raw values, history
//  summarization (counts, order, ten-session cap), goal forwarding, and
//  the strict response_format schema with the catalog-ID enum.
//

import Foundation
import SwiftData
import Testing
@testable import Setory

struct SuggestionPromptBuilderTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeExercises() -> [Exercise] {
        [
            Exercise(
                id: "bench-press", name: "Bench Press", category: .strength,
                primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders]
            ),
            Exercise(
                id: "squat", name: "Squat", category: .strength,
                primaryMuscles: [.quads, .glutes], secondaryMuscles: [.hamstrings, .lowerBack]
            ),
            Exercise(id: "treadmill-run", name: "Treadmill Run", category: .cardio, primaryMuscles: [.fullBody]),
        ]
    }

    // MARK: - Payload: catalog

    @Test func catalogCarriesCategoryAndMuscleRawValues() {
        let payload = SuggestionPromptBuilder.payload(exercises: makeExercises(), sessions: [], goal: nil)

        #expect(payload.catalog.map(\.id) == ["bench-press", "squat", "treadmill-run"])
        let squat = payload.catalog[1]
        #expect(squat.category == "strength")
        #expect(squat.primaryMuscles == ["quads", "glutes"])
        #expect(squat.secondaryMuscles == ["hamstrings", "lower_back"])
        let run = payload.catalog[2]
        #expect(run.category == "cardio")
        #expect(run.primaryMuscles == ["full_body"])
    }

    // MARK: - Payload: history

    @Test func historySummarizesSeriesCountsMusclesAndDates() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let exercises = makeExercises()
        exercises.forEach(context.insert)

        let day = Calendar.current.startOfDay(for: .now)
        let session = WorkoutSession(date: day)
        context.insert(session)
        // bench, bench, squat: counts keep first-appearance order.
        for (order, exercise) in [exercises[0], exercises[0], exercises[1]].enumerated() {
            let series = WorkoutSeries(order: order, exercise: exercise, reps: 8)
            series.session = session
            context.insert(series)
        }
        try context.save()

        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [session], goal: nil)

        #expect(payload.recentSessions.count == 1)
        let recent = try #require(payload.recentSessions.first)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        #expect(recent.date == formatter.string(from: day))
        #expect(recent.exercises.map(\.exerciseId) == ["bench-press", "squat"])
        #expect(recent.exercises.map(\.seriesCount) == [2, 1])
        #expect(recent.musclesWorked == ["chest", "quads", "glutes"])
    }

    @Test func historyKeepsOnlyTheTenNewestSessionsNewestFirst() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let bench = makeExercises()[0]
        context.insert(bench)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var sessions: [WorkoutSession] = []
        for daysAgo in 0..<12 {
            let session = WorkoutSession(date: calendar.date(byAdding: .day, value: -daysAgo, to: today)!)
            context.insert(session)
            let series = WorkoutSeries(order: 0, exercise: bench, reps: 10)
            series.session = session
            context.insert(series)
            sessions.append(session)
        }
        try context.save()

        // Shuffle so the builder must sort, not trust fetch order.
        let payload = SuggestionPromptBuilder.payload(exercises: [bench], sessions: sessions.shuffled(), goal: nil)

        #expect(payload.recentSessions.count == 10)
        let dates = payload.recentSessions.map(\.date)
        #expect(dates == dates.sorted(by: >))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        #expect(dates.first == formatter.string(from: today))
    }

    @Test func emptyHistoryProducesAValidPayload() {
        let payload = SuggestionPromptBuilder.payload(exercises: makeExercises(), sessions: [], goal: nil)
        #expect(payload.recentSessions.isEmpty)
        #expect(!payload.catalog.isEmpty)
    }

    // MARK: - Payload: goal

    @Test func goalIsTrimmedAndForwarded() {
        let payload = SuggestionPromptBuilder.payload(
            exercises: makeExercises(), sessions: [], goal: "  focus legs, 45 minutes \n"
        )
        #expect(payload.goal == "focus legs, 45 minutes")
    }

    @Test func blankGoalBecomesNil() {
        #expect(SuggestionPromptBuilder.payload(exercises: [], sessions: [], goal: "   ").goal == nil)
        #expect(SuggestionPromptBuilder.payload(exercises: [], sessions: [], goal: nil).goal == nil)
    }

    // MARK: - Request body

    @Test func requestBodyCarriesModelMessagesAndStrictSchema() throws {
        let payload = SuggestionPromptBuilder.payload(exercises: makeExercises(), sessions: [], goal: "legs")
        let data = try SuggestionPromptBuilder.requestBody(
            model: "openai/gpt-5.4-mini", payload: payload, languageCode: "en"
        )
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(body["model"] as? String == "openai/gpt-5.4-mini")

        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.map { $0["role"] as? String } == ["system", "user"])
        let systemPrompt = try #require(messages[0]["content"] as? String)
        #expect(systemPrompt.contains("English"))

        // The user message is the payload, JSON-encoded as a string.
        let userContent = try #require(messages[1]["content"] as? String)
        let decoded = try JSONDecoder().decode(SuggestionRequestPayload.self, from: Data(userContent.utf8))
        #expect(decoded == payload)

        let responseFormat = try #require(body["response_format"] as? [String: Any])
        #expect(responseFormat["type"] as? String == "json_schema")
        let jsonSchema = try #require(responseFormat["json_schema"] as? [String: Any])
        #expect(jsonSchema["strict"] as? Bool == true)
        #expect(jsonSchema["name"] as? String == "suggested_routine")

        let schema = try #require(jsonSchema["schema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])
        let items = try #require(properties["items"] as? [String: Any])
        let itemSchema = try #require(items["items"] as? [String: Any])
        let itemProperties = try #require(itemSchema["properties"] as? [String: Any])
        let exerciseId = try #require(itemProperties["exerciseId"] as? [String: Any])
        #expect(exerciseId["enum"] as? [String] == ["bench-press", "squat", "treadmill-run"])
    }

    @Test func spanishDeviceLanguageIsRequestedInTheSystemPrompt() {
        #expect(SuggestionPromptBuilder.systemPrompt(languageCode: "es").contains("Spanish"))
        #expect(SuggestionPromptBuilder.systemPrompt(languageCode: "en").contains("English"))
    }

    // MARK: - Catalog subset

    /// Synthetic catalog spread across muscles/equipment, big enough to
    /// force subsetting. IDs are zero-padded so ID order is stable.
    private func makeBigCatalog(count: Int) -> [Exercise] {
        let muscles = Muscle.allCases
        let equipment = Equipment.allCases
        return (0..<count).map { index in
            Exercise(
                id: String(format: "gv%04d", index),
                name: "Exercise \(index)",
                category: index % 20 == 0 ? .cardio : .strength,
                primaryMuscles: [muscles[index % muscles.count]],
                equipment: equipment[index % equipment.count]
            )
        }
    }

    @Test func catalogSubsetIsBoundedAndDeterministic() {
        let exercises = makeBigCatalog(count: 900)

        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [], goal: nil)
        let again = SuggestionPromptBuilder.payload(exercises: exercises.shuffled(), sessions: [], goal: nil)

        #expect(payload.catalog.count == SuggestionPromptBuilder.maxCatalogEntries)
        #expect(payload == again)
        // Sampling spreads across muscle groups, not just the low ids.
        let musclesCovered = Set(payload.catalog.flatMap(\.primaryMuscles))
        #expect(musclesCovered.count == Muscle.allCases.count)
    }

    @Test func smallCatalogIsSentWhole() {
        let exercises = makeBigCatalog(count: 25)
        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [], goal: nil)
        #expect(payload.catalog.count == 25)
    }

    @Test func recentExercisesAreAlwaysIncluded() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let exercises = makeBigCatalog(count: 900)
        exercises.forEach(context.insert)
        // Log the very last exercise by id order, which round-robin
        // sampling alone would never reach.
        let last = exercises.last!
        let session = WorkoutSession(date: Calendar.current.startOfDay(for: .now))
        context.insert(session)
        let series = WorkoutSeries(order: 0, exercise: last, reps: 5)
        series.session = session
        context.insert(series)
        try context.save()

        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [session], goal: nil)

        #expect(payload.catalog.contains { $0.id == last.id })
        #expect(payload.catalog.count == SuggestionPromptBuilder.maxCatalogEntries)
    }

    @Test func goalPullsMatchingMusclesIntoTheSubset() {
        let exercises = makeBigCatalog(count: 900)

        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [], goal: "focus legs today")

        let legMuscles: Set<String> = ["quads", "hamstrings", "glutes", "calves"]
        let legEntries = payload.catalog.filter { !legMuscles.isDisjoint(with: $0.primaryMuscles) }
        // Goal fill takes up to three quarters of the budget…
        #expect(legEntries.count >= SuggestionPromptBuilder.maxCatalogEntries / 2)
        // …while variety sampling keeps other muscles present.
        #expect(legEntries.count < payload.catalog.count)
        #expect(payload.catalog.count == SuggestionPromptBuilder.maxCatalogEntries)
    }

    @Test func goalKeywordsMatchEnglishAndSpanishWithDiacritics() {
        #expect(SuggestionPromptBuilder.muscles(inGoal: "focus legs") == [.quads, .hamstrings, .glutes, .calves])
        #expect(SuggestionPromptBuilder.muscles(inGoal: "piernas y glúteos").isSuperset(of: [.quads, .glutes]))
        #expect(SuggestionPromptBuilder.muscles(inGoal: "PECHO y triceps") == [.chest, .triceps])
        #expect(SuggestionPromptBuilder.muscles(inGoal: "45 minutes, no idea").isEmpty)
        #expect(SuggestionPromptBuilder.muscles(inGoal: nil).isEmpty)
    }

    @Test func catalogEntriesCarryEquipment() {
        let exercises = [
            Exercise(
                id: "gv0025", name: "Barbell Bench Press", category: .strength,
                primaryMuscles: [.chest], equipment: .barbell
            ),
        ]
        let payload = SuggestionPromptBuilder.payload(exercises: exercises, sessions: [], goal: nil)
        #expect(payload.catalog.first?.equipment == "barbell")
    }
}
