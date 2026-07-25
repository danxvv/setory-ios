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
    /// One suggestion per call; throws SuggestionError (or CancellationError
    /// when the surrounding task was cancelled).
    func suggestRoutine(request: SuggestionRequestPayload) async throws -> SuggestedRoutine
}

struct OpenRouterSuggestionService: RoutineSuggestionService {
    /// Cheap, structured-outputs-capable default (verified on openrouter.ai
    /// 2026-07); users can override it in AI Settings.
    static let defaultModel = "openai/gpt-5.4-mini"
    /// UserDefaults key of the model override — a preference, not a secret.
    static let modelOverrideDefaultsKey = "aiModelOverride"
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

    /// The override when one is set (non-blank), otherwise the default.
    /// Static because the photo-match client resolves the same preference —
    /// one model setting covers every AI feature.
    static func resolvedModel(defaults: UserDefaults) -> String {
        let override = defaults.string(forKey: modelOverrideDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (override?.isEmpty ?? true) ? defaultModel : override!
    }

    var model: String { Self.resolvedModel(defaults: defaults) }

    func suggestRoutine(request payload: SuggestionRequestPayload) async throws -> SuggestedRoutine {
        guard let key = keyStore.read(), !key.isEmpty else {
            throw SuggestionError.missingAPIKey
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
            throw SuggestionError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw SuggestionError.badResponse
        }
        return try SuggestionResponseParser.routine(
            from: data,
            statusCode: http.statusCode,
            validExerciseIds: Set(payload.catalog.map(\.id))
        )
    }
}
