//
//  OpenRouterClient.swift
//  gymapp
//
//  The app's only networking, and the one place an OpenRouter chat
//  completion is actually sent. Both AI features (routine suggestion, photo
//  exercise match) build their own request body and parse their own
//  response, but share this transport — so the key guard, the timeout,
//  cancellation translation, and HTTP status handling exist once and cannot
//  drift apart between features.
//
//  Swapping to a proxy backend later means changing only this file's
//  endpoint and auth wiring.
//

import Foundation

struct OpenRouterClient: Sendable {
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

    /// The model every AI feature honors, override included.
    var model: String { AIModelPreference.resolvedModel(defaults: defaults) }

    /// Sends one chat completion and returns the raw body with its status,
    /// leaving decoding and validation to the caller's parser.
    ///
    /// `buildBody` receives the resolved model so each feature can assemble
    /// its own request shape — a plain string user message for suggestions,
    /// a multimodal content array for photo matching.
    ///
    /// Throws `AIError.missingAPIKey` when no key is stored (without
    /// touching the network), `AIError.network` for transport failures,
    /// `AIError.badResponse` for a non-HTTP response, and
    /// `CancellationError` when the surrounding task was cancelled.
    func send(buildBody: (String) throws -> Data) async throws -> (data: Data, statusCode: Int) {
        guard let key = keyStore.read(), !key.isEmpty else {
            throw AIError.missingAPIKey
        }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = Self.requestTimeout
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildBody(model)

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
        return (data, http.statusCode)
    }
}
