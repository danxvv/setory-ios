//
//  OpenRouterClientParityTests.swift
//  gymappTests
//
//  Both AI features share one transport (OpenRouterClient), so a given HTTP
//  status must produce the same AIError in both — that consistency is the
//  whole point of the shared client, and it is exactly what silently drifted
//  while each feature owned its own copy of the exchange. Driven through the
//  suite's URLProtocol fake; no real network.
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

/// Own subclass so this suite never answers another suite's requests.
final class TransportParityMockURLProtocol: MockURLProtocol {}

@Suite(.serialized)
struct OpenRouterClientParityTests {
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
        try context.save()
    }

    private func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TransportParityMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func suggestionService(key: String? = "sk-or-v1-unit-test") -> OpenRouterSuggestionService {
        OpenRouterSuggestionService(keyStore: InMemoryAPIKeyStore(key: key), session: session())
    }

    private func photoMatchService(key: String? = "sk-or-v1-unit-test") -> OpenRouterPhotoMatchService {
        OpenRouterPhotoMatchService(keyStore: InMemoryAPIKeyStore(key: key), session: session())
    }

    private func exercises() throws -> [Exercise] {
        try ModelContext(container).fetch(FetchDescriptor<Exercise>())
    }

    private func suggestionPayload() throws -> SuggestionRequestPayload {
        SuggestionPromptBuilder.payload(exercises: try exercises(), sessions: [], goal: nil)
    }

    private func photoPayload() throws -> PhotoMatchRequestPayload {
        PhotoMatchRequestBuilder.payload(exercises: try exercises(), photos: [Data([0xFF, 0xD8, 0xFF])])
    }

    private func respond(_ statusCode: Int, body: Data = Data("{}".utf8)) {
        TransportParityMockURLProtocol.handler = { request in
            (
                HTTPURLResponse(
                    url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil
                )!,
                body
            )
        }
    }

    /// Runs the same scenario through both features and returns the error each
    /// surfaced, so the assertion is about equality rather than two
    /// independently-maintained expectations.
    private func errorsFromBothFeatures() async throws -> (suggestion: AIError?, photoMatch: AIError?) {
        let suggestionPayload = try suggestionPayload()
        let photoPayload = try photoPayload()

        var suggestionError: AIError?
        do {
            _ = try await suggestionService().suggestRoutine(request: suggestionPayload)
        } catch let error as AIError {
            suggestionError = error
        }

        var photoError: AIError?
        do {
            _ = try await photoMatchService().matchExercises(request: photoPayload)
        } catch let error as AIError {
            photoError = error
        }
        return (suggestionError, photoError)
    }

    // MARK: - Status mapping parity

    @Test(arguments: [
        (401, AIError.invalidKey),
        (402, AIError.insufficientCredits),
        (429, AIError.rateLimited),
        (500, AIError.badResponse),
    ])
    func bothFeaturesMapStatusTheSameWay(statusCode: Int, expected: AIError) async throws {
        respond(statusCode)
        defer { TransportParityMockURLProtocol.handler = nil }

        let errors = try await errorsFromBothFeatures()
        #expect(errors.suggestion == expected)
        #expect(errors.photoMatch == expected)
        #expect(errors.suggestion == errors.photoMatch)
    }

    @Test func bothFeaturesMapAMalformedBodyToBadResponse() async throws {
        respond(200, body: Data("not json at all".utf8))
        defer { TransportParityMockURLProtocol.handler = nil }

        let errors = try await errorsFromBothFeatures()
        #expect(errors.suggestion == .badResponse)
        #expect(errors.photoMatch == .badResponse)
    }

    @Test func bothFeaturesMapATransportFailureToNetwork() async throws {
        TransportParityMockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        defer { TransportParityMockURLProtocol.handler = nil }

        let errors = try await errorsFromBothFeatures()
        #expect(errors.suggestion == .network)
        #expect(errors.photoMatch == .network)
    }

    // MARK: - Key handling parity

    @Test func bothFeaturesFailOnAMissingKeyWithoutTouchingTheNetwork() async throws {
        nonisolated(unsafe) var requestCount = 0
        TransportParityMockURLProtocol.handler = { request in
            requestCount += 1
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Data()
            )
        }
        defer { TransportParityMockURLProtocol.handler = nil }

        let suggestionPayload = try suggestionPayload()
        let photoPayload = try photoPayload()

        await #expect(throws: AIError.missingAPIKey) {
            _ = try await suggestionService(key: nil).suggestRoutine(request: suggestionPayload)
        }
        await #expect(throws: AIError.missingAPIKey) {
            _ = try await photoMatchService(key: nil).matchExercises(request: photoPayload)
        }
        // An empty stored key counts as missing, not as a Bearer of "".
        await #expect(throws: AIError.missingAPIKey) {
            _ = try await suggestionService(key: "").suggestRoutine(request: suggestionPayload)
        }
        await #expect(throws: AIError.missingAPIKey) {
            _ = try await photoMatchService(key: "").matchExercises(request: photoPayload)
        }
        #expect(requestCount == 0)
    }

    // MARK: - Cancellation parity

    @Test func bothFeaturesTranslateURLCancellationToCancellationError() async throws {
        TransportParityMockURLProtocol.handler = { _ in throw URLError(.cancelled) }
        defer { TransportParityMockURLProtocol.handler = nil }

        let suggestionPayload = try suggestionPayload()
        let photoPayload = try photoPayload()

        await #expect(throws: CancellationError.self) {
            _ = try await suggestionService().suggestRoutine(request: suggestionPayload)
        }
        await #expect(throws: CancellationError.self) {
            _ = try await photoMatchService().matchExercises(request: photoPayload)
        }
    }

    // MARK: - Shared request shape

    @Test func bothFeaturesSendTheSameEndpointAuthAndHeaders() async throws {
        nonisolated(unsafe) var seen: [URLRequest] = []
        TransportParityMockURLProtocol.handler = { request in
            seen.append(request)
            return (
                HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!,
                Data()
            )
        }
        defer { TransportParityMockURLProtocol.handler = nil }

        _ = try await errorsFromBothFeatures()

        #expect(seen.count == 2)
        for request in seen {
            #expect(request.url == OpenRouterClient.endpoint)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-or-v1-unit-test")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.timeoutInterval == OpenRouterClient.requestTimeout)
        }
    }
}
