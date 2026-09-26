//
//  SuggestionPromptBuilder.swift
//  Setory
//
//  Builds the OpenRouter chat-completion request for a routine suggestion:
//  system prompt, user-message JSON payload, and the strict response
//  schema. Pure statics over already-fetched models, matching
//  ExerciseHistoryProvider style, so unit tests need no networking.
//

import Foundation

enum SuggestionPromptBuilder {
    /// How many of the most recent sessions are summarized for the model.
    static let maxHistorySessions = 10
    /// Hard cap on catalog entries per request: the full 1,300+ catalog
    /// would bloat every request by tens of thousands of tokens.
    static let maxCatalogEntries = 200
    /// Structured-output schema name required by OpenRouter.
    static let schemaName = "suggested_routine"

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - System prompt

    /// `languageCode` is the device language ("en"/"es"); the model writes
    /// the user-facing name and rationale in it.
    static func systemPrompt(languageCode: String) -> String {
        let language = languageCode.hasPrefix("es") ? "Spanish" : "English"
        return """
        You are an expert strength coach. Given a JSON payload with an \
        exercise catalog (a relevant subset of the user's full library), \
        the user's recent workout history, and an optional goal, compose \
        the user's next workout routine.

        Rules:
        - Use only exercise IDs from the catalog; never invent exercises.
        - Pick 3 to 8 exercises, each listed once, with targetSets between 1 and 10.
        - Balance muscle coverage against the recent history: favor muscles \
        that were not trained recently unless the goal says otherwise.
        - If the history is empty, propose a balanced starter routine.
        - Honor the goal text when present.
        - Respond only with JSON matching the provided schema. Write the \
        routine name and rationale in \(language); keep the rationale to a \
        short paragraph.
        """
    }

    // MARK: - User payload

    /// Snapshot of the local store for the user message. Sessions are
    /// summarized newest first, capped at `maxHistorySessions`; the catalog
    /// is a bounded relevance-filtered subset, ordered by ID so payloads
    /// are deterministic.
    static func payload(
        exercises: [Exercise],
        sessions: [WorkoutSession],
        goal: String?
    ) -> SuggestionRequestPayload {
        let recentSessions = sessions
            .sorted { $0.date > $1.date }
            .prefix(maxHistorySessions)

        let trimmedGoal = goal?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedGoal = (trimmedGoal?.isEmpty ?? true) ? nil : trimmedGoal

        let catalog = catalogSubset(
            exercises: exercises,
            recentSessions: Array(recentSessions),
            goal: normalizedGoal
        )
        .sorted { $0.id < $1.id }
        .map {
            SuggestionRequestPayload.CatalogEntry(
                id: $0.id,
                category: $0.categoryRaw,
                equipment: $0.equipmentRaw,
                primaryMuscles: $0.primaryMuscleRaws,
                secondaryMuscles: $0.secondaryMuscleRaws
            )
        }

        let recent = recentSessions.map { session in
            SuggestionRequestPayload.HistorySession(
                date: dayFormatter.string(from: session.date),
                exercises: exerciseEntries(for: session),
                musclesWorked: session.musclesWorked.map(\.rawValue)
            )
        }

        return SuggestionRequestPayload(
            catalog: catalog,
            recentSessions: Array(recent),
            goal: normalizedGoal
        )
    }

    // MARK: - Catalog subset

    /// Selects the bounded catalog subset for a request: every exercise
    /// from the recent history, then goal-relevant exercises (capped so
    /// variety survives), then a round-robin sample across primary muscle
    /// groups. Deterministic: candidates are always walked in ID order.
    static func catalogSubset(
        exercises: [Exercise],
        recentSessions: [WorkoutSession],
        goal: String?
    ) -> [Exercise] {
        let sorted = exercises.sorted { $0.id < $1.id }
        guard sorted.count > maxCatalogEntries else { return sorted }

        var subset: [Exercise] = []
        var includedIds = Set<String>()
        func include(_ exercise: Exercise) {
            guard subset.count < maxCatalogEntries,
                  includedIds.insert(exercise.id).inserted else { return }
            subset.append(exercise)
        }

        let recentIds = Set(recentSessions.flatMap { session in
            session.orderedSeries.compactMap { $0.exercise?.id }
        })
        for exercise in sorted where recentIds.contains(exercise.id) {
            include(exercise)
        }

        let goalMuscles = muscles(inGoal: goal)
        if !goalMuscles.isEmpty {
            // Leave a quarter of the budget for cross-muscle variety.
            let goalCap = maxCatalogEntries * 3 / 4
            for exercise in sorted
            where subset.count < goalCap && !goalMuscles.isDisjoint(with: exercise.primaryMuscles) {
                include(exercise)
            }
        }

        var buckets: [Muscle: [Exercise]] = [:]
        for exercise in sorted where !includedIds.contains(exercise.id) {
            guard let primary = exercise.primaryMuscles.first else { continue }
            buckets[primary, default: []].append(exercise)
        }
        while subset.count < maxCatalogEntries {
            var pickedAny = false
            for muscle in Muscle.allCases {
                guard subset.count < maxCatalogEntries, !(buckets[muscle]?.isEmpty ?? true) else { continue }
                include(buckets[muscle]!.removeFirst())
                pickedAny = true
            }
            if !pickedAny { break }
        }
        return subset
    }

    /// Muscles referenced by the free-text goal, matched against a small
    /// English/Spanish keyword table, case- and diacritic-insensitively.
    static func muscles(inGoal goal: String?) -> Set<Muscle> {
        guard let goal, !goal.isEmpty else { return [] }
        let folded = goal.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        var result: Set<Muscle> = []
        for (keyword, muscles) in goalMuscleKeywords where folded.contains(keyword) {
            result.formUnion(muscles)
        }
        return result
    }

    /// Keyword table for goal parsing. Keys are diacritic-folded lowercase
    /// substrings covering English and Spanish gym vocabulary.
    private static let goalMuscleKeywords: [String: [Muscle]] = [
        "chest": [.chest], "pecho": [.chest], "pectoral": [.chest],
        "back": [.back, .lats, .lowerBack], "espalda": [.back, .lats, .lowerBack],
        "lats": [.lats], "dorsal": [.lats],
        "trap": [.traps], "trapecio": [.traps],
        "shoulder": [.shoulders], "hombro": [.shoulders], "delt": [.shoulders], "deltoide": [.shoulders],
        "arm": [.biceps, .triceps, .forearms], "brazo": [.biceps, .triceps, .forearms],
        "bicep": [.biceps], "tricep": [.triceps],
        "forearm": [.forearms], "antebrazo": [.forearms],
        "abs": [.abs, .obliques], "abdom": [.abs, .obliques], "core": [.abs, .obliques, .lowerBack],
        "oblique": [.obliques], "oblicuo": [.obliques],
        "lower back": [.lowerBack], "lumbar": [.lowerBack],
        "glute": [.glutes], "gluteo": [.glutes],
        "leg": [.quads, .hamstrings, .glutes, .calves], "pierna": [.quads, .hamstrings, .glutes, .calves],
        "quad": [.quads], "cuadriceps": [.quads],
        "hamstring": [.hamstrings], "isquio": [.hamstrings], "femoral": [.hamstrings],
        "calf": [.calves], "calves": [.calves], "pantorrilla": [.calves], "gemelo": [.calves],
        "full body": [.fullBody], "cuerpo completo": [.fullBody],
    ]

    /// Series tallied per exercise in first-appearance order, skipping
    /// series without an exercise (same shape as TemplateDraft.draft(from:)).
    private static func exerciseEntries(
        for session: WorkoutSession
    ) -> [SuggestionRequestPayload.HistorySession.ExerciseEntry] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for series in session.orderedSeries {
            guard let id = series.exercise?.id else { continue }
            if counts[id] == nil {
                order.append(id)
            }
            counts[id, default: 0] += 1
        }
        return order.map { .init(exerciseId: $0, seriesCount: counts[$0] ?? 1) }
    }

    // MARK: - Response schema

    /// Strict JSON schema for `response_format`; `exerciseIds` becomes the
    /// enum constraining every suggested item to the catalog.
    static func responseSchema(exerciseIds: [String]) -> [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "required": ["name", "rationale", "items"],
            "properties": [
                "name": ["type": "string"],
                "rationale": ["type": "string"],
                "items": [
                    "type": "array",
                    "minItems": 1,
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": ["exerciseId", "targetSets"],
                        "properties": [
                            "exerciseId": ["type": "string", "enum": exerciseIds],
                            "targetSets": ["type": "integer", "minimum": 1, "maximum": 10],
                        ],
                    ],
                ],
            ],
        ]
    }

    // MARK: - Full request body

    /// The complete chat-completions body: system + user messages and the
    /// strict `response_format`. The payload travels as a JSON string in
    /// the user message, as the chat API requires.
    static func requestBody(
        model: String,
        payload: SuggestionRequestPayload,
        languageCode: String
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payloadJSON = String(decoding: try encoder.encode(payload), as: UTF8.self)

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt(languageCode: languageCode)],
                ["role": "user", "content": payloadJSON],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": schemaName,
                    "strict": true,
                    "schema": responseSchema(exerciseIds: payload.catalog.map(\.id)),
                ],
            ],
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }
}
