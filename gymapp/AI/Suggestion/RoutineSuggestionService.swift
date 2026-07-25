//
//  RoutineSuggestionService.swift
//  gymapp
//
//  One OpenRouter chat-completion call per suggestion, behind a protocol so
//  tests and UI-test launch hooks can substitute a stub. The HTTP exchange
//  itself belongs to OpenRouterClient; this file owns only what is specific
//  to suggestions — the request body and the response validation.
//

import Foundation

protocol RoutineSuggestionService: Sendable {
    /// One suggestion per call; throws AIError (or CancellationError
    /// when the surrounding task was cancelled).
    func suggestRoutine(request: SuggestionRequestPayload) async throws -> SuggestedRoutine
}

struct OpenRouterSuggestionService: RoutineSuggestionService {
    private let client: OpenRouterClient

    init(
        keyStore: any APIKeyStoring = KeychainAPIKeyStore(),
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        client = OpenRouterClient(keyStore: keyStore, session: session, defaults: defaults)
    }

    var model: String { client.model }

    func suggestRoutine(request payload: SuggestionRequestPayload) async throws -> SuggestedRoutine {
        let (data, statusCode) = try await client.send { model in
            // The device language travels in the prompt, not the payload:
            // the model writes the routine name and rationale in it while
            // the catalog ids and muscle raw values stay locale-independent.
            try SuggestionPromptBuilder.requestBody(
                model: model,
                payload: payload,
                languageCode: Locale.current.language.languageCode?.identifier ?? "en"
            )
        }
        return try SuggestionResponseParser.routine(
            from: data,
            statusCode: statusCode,
            validExerciseIds: Set(payload.catalog.map(\.id))
        )
    }
}
