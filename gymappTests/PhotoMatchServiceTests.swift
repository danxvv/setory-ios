//
//  PhotoMatchServiceTests.swift
//  gymappTests
//
//  Request assembly and response handling of the live photo-match client
//  through this suite's URLProtocol fake — no real network. Serialized
//  because the fake's handler is static state shared by the tests here.
//  Match validation is covered too: it runs inside the service, against
//  the catalog the request carried.
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import gymapp

@Suite(.serialized)
struct PhotoMatchServiceTests {
    /// In-memory store standing in for the seeded catalog: payloads are
    /// built from it, so the service validates against real records. A
    /// stored property because SwiftData traps when a context outlives its
    /// container.
    private let container: ModelContainer

    init() throws {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])

        let context = ModelContext(container)
        context.insert(Exercise(
            id: "gv0025", name: "Barbell Bench Press", category: .strength,
            primaryMuscles: [.chest], equipment: .barbell
        ))
        context.insert(Exercise(
            id: "gv0043", name: "Barbell Full Squat", category: .strength,
            primaryMuscles: [.quads, .glutes], equipment: .barbell
        ))
        try context.save()
    }

    private func makeService(
        key: String? = "sk-or-v1-unit-test",
        defaults: UserDefaults = .standard
    ) -> OpenRouterPhotoMatchService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PhotoMatchMockURLProtocol.self]
        return OpenRouterPhotoMatchService(
            keyStore: InMemoryAPIKeyStore(key: key),
            session: URLSession(configuration: config),
            defaults: defaults
        )
    }

    private func makePayload() throws -> PhotoMatchRequestPayload {
        let context = ModelContext(container)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }
        return PhotoMatchRequestBuilder.payload(
            exercises: exercises,
            photos: [try #require(photo.jpegData(compressionQuality: 0.7))]
        )
    }

    private func successBody(matches: [[String: Any]]) throws -> Data {
        let content = String(
            decoding: try JSONSerialization.data(withJSONObject: ["matches": matches]),
            as: UTF8.self
        )
        return try JSONSerialization.data(withJSONObject: [
            "choices": [["message": ["content": content], "finish_reason": "stop"]],
        ])
    }

    private func httpResponse(_ statusCode: Int, for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Request assembly

    @Test func requestCarriesEndpointMethodHeadersAndMultimodalBody() async throws {
        // Isolated defaults: .standard is the host app's, where a model
        // override set in AI Settings on this simulator would leak in.
        let suiteName = "PhotoMatchServiceTests-default"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        nonisolated(unsafe) var captured: URLRequest?
        nonisolated(unsafe) var capturedBody: Data?
        let body = try successBody(matches: [["exerciseId": "gv0025", "confidence": "high"]])
        PhotoMatchMockURLProtocol.handler = { request in
            captured = request
            capturedBody = request.streamedBody
            return (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        _ = try await makeService(defaults: defaults).matchExercises(request: try makePayload())

        let request = try #require(captured)
        #expect(request.url == OpenRouterSuggestionService.endpoint)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-or-v1-unit-test")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let bodyData = try #require(capturedBody)
        let sent = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(sent["model"] as? String == OpenRouterSuggestionService.defaultModel)
        let messages = try #require(sent["messages"] as? [[String: Any]])
        let content = try #require(messages.last?["content"] as? [[String: Any]])
        #expect(content.map { $0["type"] as? String } == ["text", "image_url"])
        #expect(sent["response_format"] != nil)
    }

    @Test func modelOverrideFromDefaultsIsUsed() async throws {
        let suiteName = "PhotoMatchServiceTests-override"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("custom/vision-model", forKey: OpenRouterSuggestionService.modelOverrideDefaultsKey)

        nonisolated(unsafe) var capturedBody: Data?
        let body = try successBody(matches: [])
        PhotoMatchMockURLProtocol.handler = { request in
            capturedBody = request.streamedBody
            return (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        _ = try await makeService(defaults: defaults).matchExercises(request: try makePayload())

        let bodyData = try #require(capturedBody)
        let sent = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(sent["model"] as? String == "custom/vision-model")
    }

    // MARK: - Key handling

    @Test func missingKeyFailsWithoutTouchingTheNetwork() async throws {
        nonisolated(unsafe) var requestCount = 0
        PhotoMatchMockURLProtocol.handler = { request in
            requestCount += 1
            return (self.httpResponse(200, for: request), Data())
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.missingAPIKey) {
            _ = try await makeService(key: nil).matchExercises(request: payload)
        }
        #expect(requestCount == 0)
    }

    // MARK: - Response handling

    @Test func successResponseDecodesMatchesInOrder() async throws {
        let body = try successBody(matches: [
            ["exerciseId": "gv0043", "confidence": "high"],
            ["exerciseId": "gv0025", "confidence": "low"],
        ])
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let result = try await makeService().matchExercises(request: try makePayload())
        #expect(result.matches.map(\.exerciseId) == ["gv0043", "gv0025"])
        #expect(result.matches.map(\.confidence) == [.high, .low])
    }

    @Test func status401SurfacesAsInvalidKey() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "error": ["message": "No auth credentials found", "code": 401],
        ])
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(401, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.invalidKey) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    @Test func status402SurfacesAsInsufficientCredits() async throws {
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(402, for: request), Data())
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.insufficientCredits) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    @Test func status429SurfacesAsRateLimited() async throws {
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(429, for: request), Data())
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.rateLimited) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    /// A text-only model override is rejected by OpenRouter; whatever the
    /// provider says, the client reports the generic bad-response error.
    @Test func embeddedProviderErrorSurfacesAsBadResponse() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "choices": [["message": ["content": "{}"], "finish_reason": "error"]],
        ])
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.badResponse) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    @Test func transportFailureSurfacesAsNetworkError() async throws {
        PhotoMatchMockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: SuggestionError.network) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    @Test func cancelledRequestSurfacesAsCancellationError() async throws {
        PhotoMatchMockURLProtocol.handler = { _ in
            throw URLError(.cancelled)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let payload = try makePayload()
        await #expect(throws: CancellationError.self) {
            _ = try await makeService().matchExercises(request: payload)
        }
    }

    // MARK: - Validation against the catalog

    @Test func unknownIdsAreDroppedAndDuplicatesCollapsePreservingOrder() async throws {
        let body = try successBody(matches: [
            ["exerciseId": "gv0043", "confidence": "high"],
            ["exerciseId": "zz9999", "confidence": "high"],
            ["exerciseId": "gv0043", "confidence": "low"],
            ["exerciseId": "gv0025", "confidence": "medium"],
        ])
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let result = try await makeService().matchExercises(request: try makePayload())
        #expect(result.matches.map(\.exerciseId) == ["gv0043", "gv0025"])
        // The first occurrence's confidence wins.
        #expect(result.matches.first?.confidence == .high)
    }

    /// "Nothing recognized" is a normal outcome the sheet renders as its
    /// no-matches state — unlike the suggestion path, it never throws.
    @Test func emptyResultIsSuccessNotError() async throws {
        let body = try successBody(matches: [["exerciseId": "zz9999", "confidence": "low"]])
        PhotoMatchMockURLProtocol.handler = { request in
            (self.httpResponse(200, for: request), body)
        }
        defer { PhotoMatchMockURLProtocol.handler = nil }

        let result = try await makeService().matchExercises(request: try makePayload())
        #expect(result.matches.isEmpty)
    }
}
