//
//  RoutineSuggestionService.swift
//  gymapp
//
//  The app's only networking: one OpenRouter chat-completion call per
//  suggestion, behind a protocol so tests and UI-test launch hooks can
//  substitute a stub. Swapping to a proxy backend later means changing
//  only this file's endpoint and auth wiring.
//

import Foundation

protocol RoutineSuggestionService: Sendable {
    /// One suggestion per call; throws AIError (or CancellationError
    /// when the surrounding task was cancelled).
    func suggestRoutine(request: SuggestionRequestPayload) async throws -> SuggestedRoutine
}

struct OpenRouterSuggestionService: RoutineSuggestionService {
    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    static let requestTimeout: TimeInterval = 60

    private let keyStore: any APIKeyStoring
    private let session: URLSession
    private let defaults: UserDefaults

    init(
        keyStore: any APIKeyStoring = KeychainAPIKeyStore(),
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.keyStore = keyStore
        self.session = session
        self.defaults = defaults
    }

    var model: String { AIModelPreference.resolvedModel(defaults: defaults) }

    func suggestRoutine(request payload: SuggestionRequestPayload) async throws -> SuggestedRoutine {
        guard let key = keyStore.read(), !key.isEmpty else {
            throw AIError.missingAPIKey
        }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = Self.requestTimeout
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try SuggestionPromptBuilder.requestBody(
            model: model,
            payload: payload,
            languageCode: Locale.current.language.languageCode?.identifier ?? "en"
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            // URLSession reports task cancellation as URLError; surface it
            // as CancellationError so the UI can return silently.
            throw CancellationError()
        } catch {
            throw AIError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIError.badResponse
        }
        return try SuggestionResponseParser.routine(
            from: data,
            statusCode: http.statusCode,
            validExerciseIds: Set(payload.catalog.map(\.id))
        )
    }
}
