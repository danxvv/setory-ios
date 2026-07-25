//
//  ExerciseMediaStoreTests.swift
//  gymappTests
//
//  GIF cache behavior of the media store through this suite's URLProtocol
//  fake: hit, miss → download → store, error surfacing, and the network
//  kill-switch. Serialized because the fake's handler is static state
//  shared by the tests here.
//

import Foundation
import Testing
@testable import gymapp

@Suite(.serialized)
struct ExerciseMediaStoreTests {
    private func makeStore(networkDisabled: Bool = false) -> (ExerciseMediaStore, URL) {
        let cacheDir = URL.temporaryDirectory.appending(component: "gif-cache-\(UUID().uuidString)")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MediaMockURLProtocol.self]
        var store = ExerciseMediaStore()
        store.urlSession = URLSession(configuration: config)
        store.isNetworkDisabled = networkDisabled
        store.cacheDirectory = cacheDir
        return (store, cacheDir)
    }

    @Test func gifURLIsPinnedToTheDatasetCommit() {
        let store = ExerciseMediaStore()
        let url = store.gifURL(fileName: "0025-EIeI8Vf.gif").absoluteString
        #expect(url == "https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@\(ExerciseMediaStore.datasetCommit)/videos/0025-EIeI8Vf.gif")
    }

    @Test func downloadStoresInCacheAndSecondCallSkipsNetwork() async throws {
        let (store, cacheDir) = makeStore()
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        let gifBytes = Data("GIF89a-fake".utf8)
        MediaMockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, gifBytes)
        }

        let first = try await store.gifData(forExerciseId: "gv0025", gifFileName: "0025-x.gif")
        #expect(first == gifBytes)
        #expect(store.cachedGIFData(forExerciseId: "gv0025") == gifBytes)

        // Second call must come from disk: a network hit would fail loudly.
        MediaMockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let second = try await store.gifData(forExerciseId: "gv0025", gifFileName: "0025-x.gif")
        #expect(second == gifBytes)
    }

    @Test func serverErrorSurfacesAndCachesNothing() async {
        let (store, cacheDir) = makeStore()
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        MediaMockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await #expect(throws: ExerciseMediaStore.MediaError.self) {
            try await store.gifData(forExerciseId: "gv9999", gifFileName: "missing.gif")
        }
        #expect(store.cachedGIFData(forExerciseId: "gv9999") == nil)
    }

    @Test func disabledNetworkThrowsWithoutTouchingTheSession() async {
        let (store, cacheDir) = makeStore(networkDisabled: true)
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        MediaMockURLProtocol.handler = { _ in
            Issue.record("The kill-switch must not reach the network")
            throw URLError(.badURL)
        }

        await #expect(throws: ExerciseMediaStore.MediaError.self) {
            try await store.gifData(forExerciseId: "gv0025", gifFileName: "0025-x.gif")
        }
    }

    @Test func disabledNetworkStillServesTheCache() async throws {
        let (store, cacheDir) = makeStore(networkDisabled: false)
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        let gifBytes = Data("cached".utf8)
        MediaMockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, gifBytes)
        }
        _ = try await store.gifData(forExerciseId: "gv0001", gifFileName: "0001-x.gif")

        var offline = store
        offline.isNetworkDisabled = true
        let data = try await offline.gifData(forExerciseId: "gv0001", gifFileName: "0001-x.gif")
        #expect(data == gifBytes)
    }

    @Test func bundledThumbnailResolvesByExerciseId() {
        let store = ExerciseMediaStore()
        #expect(store.thumbnail(forExerciseId: "gv0025") != nil)
        #expect(store.thumbnail(forExerciseId: "no-such-exercise") == nil)
    }
}
