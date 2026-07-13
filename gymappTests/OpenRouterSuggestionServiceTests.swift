//
//  OpenRouterSuggestionServiceTests.swift
//  gymappTests
//
//  Request assembly and response handling of the live client through a
//  URLProtocol fake — no real network. Serialized because the fake's
//  handler is shared static state.
//

import Foundation
import Testing
@testable import gymapp

/// Intercepts every request of an ephemeral URLSession and answers from
/// the static handler. POST bodies arrive as a stream, so the handler
/// reads `httpBodyStream`, not `httpBody`.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    /// Drains httpBodyStream (how URLSession hands a POST body to a
    /// URLProtocol) back into Data.
    var streamedBody: Data? {
        guard let stream = httpBodyStream else { return httpBody }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 16_384
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

@Suite(.serialized)
struct OpenRouterSuggestionServiceTests {
    private func makeService(
        key: String? = "sk-or-v1-unit-test",
        defaults: UserDefaults = .standard
    ) -> OpenRouterSuggestionService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return OpenRouterSuggestionService(
            keyStore: InMemoryAPIKeyStore(key: key),
            session: URLSession(configuration: config),
            defaults: defaults
        )
    }

    private var payload: SuggestionRequestPayload {
        SuggestionRequestPayload(
            catalog: [
                .init(id: "bench-press", category: "strength", primaryMuscles: ["chest"], secondaryMuscles: ["triceps"]),
                .init(id: "squat", category: "strength", primaryMuscles: ["quads"], secondaryMuscles: []),
            ],
            recentSessions: [],
            goal: nil
        )
    }

    private func successBody(routine: [String: Any]) throws -> Data {
        let content = String(decoding: try JSONSerialization.data(withJSONObject: routine), as: UTF8.self)
        return try JSONSerialization.data(withJSONObject: [
            "choices": [["message": ["content": content], "finish_reason": "stop"]],
        ])
    }

    private func httpResponse(_ statusCode: Int, for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Request assembly

    @Test func requestCarriesEndpointMethodHeadersAndDefaultModel() async throws {
        nonisolated(unsafe) var captured: URLRequest?
        nonisolated(unsafe) var capturedBody: Data?
        let body = try successBody(routine: [
            "name": "Push", "rationale": "r",
            "items": [["exerciseId": "bench-press", "targetSets": 3]],
        ])
        MockURLProtocol.handler = { request in
            captured = request
            capturedBody = request.streamedBody
            return (self.httpResponse(200, for: request), body)
        }
        defer { MockURLProtocol.handler = nil }

        _ = try await makeService().suggestRoutine(request: payload)

        let request = try #require(captured)
        #expect(request.url == OpenRouterSuggestionService.endpoint)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-or-v1-unit-test")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let bodyData = try #require(capturedBody)
        let sent = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(sent["model"] as? String == OpenRouterSuggestionService.defaultModel)
        #expect((sent["messages"] as? [[String: Any]])?.count == 2)
        #expect(sent["response_format"] != nil)
    }

    @Test func modelOverrideFromDefaultsIsUsed() async throws {
        let suiteName = "OpenRouterSuggestionServiceTests-override"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("custom/model-id", forKey: OpenRouterSuggestionService.modelOverrideDefaultsKey)

        nonisolated(unsafe) var capturedBody: Data?
        let body = try successBody(routine: [
            "name": "Push", "rationale": "r",
            "items": [["exerciseId": "bench-press", "targetSets": 3]],
        ])
        MockURLProtocol.handler = { request in
            capturedBody = request.streamedBody
            return (self.httpResponse(200, for: request), body)
        }
        defer { MockURLProtocol.handler = nil }

        _ = try await makeService(defaults: defaults).suggestRoutine(request: payload)

        let bodyData = try #require(capturedBody)
        let sent = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(sent["model"] as? String == "custom/model-id")
    }

    @Test func blankModelOverrideFallsBackToDefault() throws {
        let suiteName = "OpenRouterSuggestionServiceTests-blank"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("   ", forKey: OpenRouterSuggestionService.modelOverrideDefaultsKey)

        #expect(makeService(defaults: defaults).model == OpenRouterSuggestionService.defaultModel)
    }

    // MARK: - Key handling

    @Test func missingKeyFailsWithoutTouchingTheNetwork() async throws {
        nonisolated(unsafe) var requestCount = 0
        MockURLProtocol.handler = { request in
            requestCount += 1
            return (self.httpResponse(200, for: request), Data())
        }
        defer { MockURLProtocol.handler = nil }

        await #expect(throws: SuggestionError.missingAPIKey) {
            _ = try await makeService(key: nil).suggestRoutine(request: payload)
        }
        #expect(requestCount == 0)
    }

    // MARK: - Response handling

    @Test func successResponseDecodesAndValidates() async throws {
        let body = try successBody(routine: [
            "name": "Leg Focus", "rationale": "Quads were rested.",
            "items": [
                ["exerciseId": "squat", "targetSets": 12],
                ["exerciseId": "unknown-id", "targetSets": 3],
            ],
        ])
        MockURLProtocol.handler = { request in
            (self.httpResponse(200, for: request), body)
        }
        defer { MockURLProtocol.handler = nil }

        let routine = try await makeService().suggestRoutine(request: payload)
        #expect(routine.name == "Leg Focus")
        // Validation runs inside the service: unknown IDs drop, sets clamp.
        #expect(routine.items.map(\.exerciseId) == ["squat"])
        #expect(routine.items.map(\.targetSets) == [10])
    }

    @Test func status401SurfacesAsInvalidKey() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "error": ["message": "No auth credentials found", "code": 401],
        ])
        MockURLProtocol.handler = { request in
            (self.httpResponse(401, for: request), body)
        }
        defer { MockURLProtocol.handler = nil }

        await #expect(throws: SuggestionError.invalidKey) {
            _ = try await makeService().suggestRoutine(request: payload)
        }
    }

    @Test func transportFailureSurfacesAsNetworkError() async {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { MockURLProtocol.handler = nil }

        await #expect(throws: SuggestionError.network) {
            _ = try await makeService().suggestRoutine(request: payload)
        }
    }
}
