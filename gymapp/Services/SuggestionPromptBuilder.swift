//
//  SuggestionPromptBuilder.swift
//  gymapp
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
        exercise catalog, the user's recent workout history, and an \
        optional goal, compose the user's next workout routine.

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
    /// summarized newest first, capped at `maxHistorySessions`; catalog
    /// order is by ID so payloads are deterministic.
    static func payload(
        exercises: [Exercise],
        sessions: [WorkoutSession],
        goal: String?
    ) -> SuggestionRequestPayload {
        let catalog = exercises
            .sorted { $0.id < $1.id }
            .map {
                SuggestionRequestPayload.CatalogEntry(
                    id: $0.id,
                    category: $0.categoryRaw,
                    primaryMuscles: $0.primaryMuscleRaws,
                    secondaryMuscles: $0.secondaryMuscleRaws
                )
            }

        let recent = sessions
            .sorted { $0.date > $1.date }
            .prefix(maxHistorySessions)
            .map { session in
                SuggestionRequestPayload.HistorySession(
                    date: dayFormatter.string(from: session.date),
                    exercises: exerciseEntries(for: session),
                    musclesWorked: session.musclesWorked.map(\.rawValue)
                )
            }

        let trimmedGoal = goal?.trimmingCharacters(in: .whitespacesAndNewlines)
        return SuggestionRequestPayload(
            catalog: catalog,
            recentSessions: Array(recent),
            goal: (trimmedGoal?.isEmpty ?? true) ? nil : trimmedGoal
        )
    }

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
