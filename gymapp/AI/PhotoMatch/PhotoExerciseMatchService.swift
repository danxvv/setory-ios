//
//  PhotoExerciseMatchService.swift
//  gymapp
//
//  One OpenRouter chat-completion call per photo match, behind a protocol so
//  tests and UI-test launch hooks can substitute a stub. Shares
//  OpenRouterClient with the suggestion feature — same key store, same
//  endpoint, same timeout, same model preference, same error taxonomy — so
//  this file owns only the multimodal request body and the match validation.
//

import Foundation

protocol PhotoExerciseMatchService: Sendable {
    /// One match per call; throws AIError (or CancellationError
    /// when the surrounding task was cancelled). An empty match list is a
    /// success, not an error.
    func matchExercises(request: PhotoMatchRequestPayload) async throws -> PhotoMatchResult
}

struct OpenRouterPhotoMatchService: PhotoExerciseMatchService {
    private let client: OpenRouterClient

    init(
        keyStore: any APIKeyStoring = KeychainAPIKeyStore(),
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        client = OpenRouterClient(keyStore: keyStore, session: session, defaults: defaults)
    }

    /// The same model (and same user override) the suggestion client uses.
    /// A text-only override fails at OpenRouter and maps to `badResponse`,
    /// whose alert points the user back at AI Settings.
    var model: String { client.model }

    func matchExercises(request payload: PhotoMatchRequestPayload) async throws -> PhotoMatchResult {
        let (data, statusCode) = try await client.send { model in
            try PhotoMatchRequestBuilder.requestBody(model: model, payload: payload)
        }
        return try PhotoMatchResponseParser.matches(
            from: data,
            statusCode: statusCode,
            validExerciseIds: Set(payload.catalog.map(\.id))
        )
    }
}
