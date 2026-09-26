//
//  ExerciseMediaStore.swift
//  Setory
//
//  Exercise media delivery: bundled 180×180 thumbnails looked up by
//  exercise id, and animated demonstration GIFs fetched on demand from a
//  CDN pinned to a fixed dataset commit, cached permanently on disk.
//  Media is © Gym visual (https://gymvisual.com/), redistributed with
//  permission; the attribution string must stay visible wherever it shows.
//

import Foundation
import SwiftUI

struct ExerciseMediaStore: Sendable {
    /// The dataset commit media URLs are pinned to. Keep in sync with
    /// PINNED_COMMIT in tools/catalog/transform.py.
    static let datasetCommit = "118e4bd6b14da6df0e36605d7169b65db18389a4"
    static let attribution = "© Gym visual — https://gymvisual.com/"

    enum MediaError: Error {
        case networkDisabled
        case badResponse
    }

    var bundle: Bundle = .main
    var urlSession: URLSession = .shared
    /// True under the -uitest-offline-media launch hook so UI tests never
    /// perform network requests and deterministically exercise the
    /// degraded (thumbnail + retry) state.
    var isNetworkDisabled = false
    var cacheDirectory: URL = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ExerciseGIFs", isDirectory: true)

    /// Bundled thumbnail image, nil when the exercise ships no media.
    func thumbnail(forExerciseId id: String) -> UIImage? {
        UIImage(named: "\(id).jpg", in: bundle, with: nil)
    }

    func gifURL(fileName: String) -> URL {
        URL(string: "https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@\(Self.datasetCommit)/videos/")!
            .appendingPathComponent(fileName)
    }

    private func cachedGIFLocation(forExerciseId id: String) -> URL {
        cacheDirectory.appendingPathComponent("\(id).gif")
    }

    func cachedGIFData(forExerciseId id: String) -> Data? {
        try? Data(contentsOf: cachedGIFLocation(forExerciseId: id))
    }

    /// Cached animation data, or downloads from the pinned CDN and caches.
    func gifData(forExerciseId id: String, gifFileName: String) async throws -> Data {
        if let cached = cachedGIFData(forExerciseId: id) {
            return cached
        }
        guard !isNetworkDisabled else { throw MediaError.networkDisabled }
        let (data, response) = try await urlSession.data(from: gifURL(fileName: gifFileName))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            throw MediaError.badResponse
        }
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? data.write(to: cachedGIFLocation(forExerciseId: id), options: .atomic)
        return data
    }
}

extension EnvironmentValues {
    @Entry var exerciseMediaStore = ExerciseMediaStore()
}
