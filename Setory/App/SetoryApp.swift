//
//  SetoryApp.swift
//  Setory
//
//  Created by Daniel Temalatzi Mojica on 10/07/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct SetoryApp: App {
    /// AI dependencies resolved once at launch: Keychain + OpenRouter
    /// normally, or an in-memory store + stub services when a UI-test
    /// scenario asks for them (see TestOverrides, which is inert in Release).
    private let aiKeyStore: any APIKeyStoring
    private let aiSuggestionService: any RoutineSuggestionService
    private let aiPhotoMatchService: any PhotoExerciseMatchService
    /// Media store resolved once at launch; a UI-test hook can disable its
    /// network path so detail screens degrade deterministically.
    private let mediaStore: ExerciseMediaStore

    init() {
        if TestOverrides.disablesAnimations {
            UIView.setAnimationsEnabled(false)
        }

        let offlineMedia = TestOverrides.disablesMediaNetwork
        mediaStore = ExerciseMediaStore(isNetworkDisabled: offlineMedia)
        if offlineMedia {
            // A GIF cached by an earlier (online) run would defeat the
            // deterministic degraded state the hook exists to produce.
            try? FileManager.default.removeItem(at: mediaStore.cacheDirectory)
        }

        if let overrides = TestOverrides.aiDependencies() {
            aiKeyStore = overrides.keyStore
            aiSuggestionService = overrides.suggestion
            aiPhotoMatchService = overrides.photoMatch
        } else {
            let store = KeychainAPIKeyStore()
            aiKeyStore = store
            aiSuggestionService = OpenRouterSuggestionService(keyStore: store)
            aiPhotoMatchService = OpenRouterPhotoMatchService(keyStore: store)
        }
    }

    let sharedModelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.apiKeyStore, aiKeyStore)
                .environment(\.routineSuggestionService, aiSuggestionService)
                .environment(\.photoMatchService, aiPhotoMatchService)
                .environment(\.exerciseMediaStore, mediaStore)
                .environment(\.photoMatchFixture, TestOverrides.photoMatchFixture)
        }
        .modelContainer(sharedModelContainer)
    }
}
