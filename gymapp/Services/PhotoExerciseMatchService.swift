//
//  PhotoExerciseMatchService.swift
//  gymapp
//
//  The photo-match client: one OpenRouter chat-completion call per match,
//  behind a protocol so tests and UI-test launch hooks can substitute a
//  stub. Mirrors OpenRouterSuggestionService — same key store, same
//  endpoint, same model preference, same error taxonomy — so a future
//  proxy backend changes both clients the same way.
//

import Foundation

protocol PhotoExerciseMatchService: Sendable {
    /// One match per call; throws SuggestionError (or CancellationError
    /// when the surrounding task was cancelled). An empty match list is a
    /// success, not an error.
    func matchExercises(request: PhotoMatchRequestPayload) async throws -> PhotoMatchResult
}

struct OpenRouterPhotoMatchService: PhotoExerciseMatchService {
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

    /// The same model (and same user override) the suggestion client uses.
    /// A text-only override fails at OpenRouter and maps to `badResponse`,
    /// whose alert points the user back at AI Settings.
    var model: String { OpenRouterSuggestionService.resolvedModel(defaults: defaults) }

    func matchExercises(request payload: PhotoMatchRequestPayload) async throws -> PhotoMatchResult {
        guard let key = keyStore.read(), !key.isEmpty else {
            throw SuggestionError.missingAPIKey
        }

        var request = URLRequest(url: OpenRouterSuggestionService.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = OpenRouterSuggestionService.requestTimeout
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try PhotoMatchRequestBuilder.requestBody(model: model, payload: payload)

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
        return try PhotoMatchResponseParser.matches(
            from: data,
            statusCode: http.statusCode,
            validExerciseIds: Set(payload.catalog.map(\.id))
        )
    }
}

/// Validates model output against the catalog that was sent. Unlike the
/// suggestion parser this never throws on an empty result: "no matches" is
/// a normal outcome the UI renders as its own state.
enum PhotoMatchResponseParser {
    static func matches(
        from data: Data,
        statusCode: Int,
        validExerciseIds: Set<String>
    ) throws -> PhotoMatchResult {
        let result = try ChatCompletionResponse.decode(
            PhotoMatchResult.self,
            from: data,
            statusCode: statusCode
        )
        return validated(result, validExerciseIds: validExerciseIds)
    }

    /// Drops matches with unknown exercise IDs and collapses duplicates,
    /// preserving the model's best-first ordering.
    static func validated(
        _ result: PhotoMatchResult,
        validExerciseIds: Set<String>
    ) -> PhotoMatchResult {
        var seen = Set<String>()
        var matches: [PhotoMatch] = []
        for match in result.matches {
            guard validExerciseIds.contains(match.exerciseId),
                  seen.insert(match.exerciseId).inserted
            else { continue }
            matches.append(match)
        }
        return PhotoMatchResult(matches: matches)
    }
}
