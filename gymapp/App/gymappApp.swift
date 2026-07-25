//
//  gymappApp.swift
//  gymapp
//
//  Created by Daniel Temalatzi Mojica on 10/07/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct gymappApp: App {
    /// AI dependencies resolved once at launch: Keychain + OpenRouter
    /// normally, or an in-memory store + stub services under
    /// `-uitest-ai <scenario>` / `-uitest-photo-match <scenario>`
    /// (success / error / no-key) so UI tests never touch the network or
    /// the real Keychain.
    private let aiKeyStore: any APIKeyStoring
    private let aiSuggestionService: any RoutineSuggestionService
    private let aiPhotoMatchService: any PhotoExerciseMatchService
    /// Media store resolved once at launch; `-uitest-offline-media`
    /// disables its network path so UI tests are deterministic.
    private let mediaStore: ExerciseMediaStore

    init() {
        // XCUITest waits for the app to quiesce after every event, so each
        // navigation push / sheet / tab switch otherwise pays its full
        // animation duration. Any -uitest-* flag marks a UI-test launch;
        // relaunches that need no other flag pass -uitest-disable-animations.
        if CommandLine.arguments.contains(where: { $0.hasPrefix("-uitest") }) {
            UIView.setAnimationsEnabled(false)
        }
        let offlineMedia = CommandLine.arguments.contains("-uitest-offline-media")
        mediaStore = ExerciseMediaStore(isNetworkDisabled: offlineMedia)
        if offlineMedia {
            // A GIF cached by an earlier (online) run would defeat the
            // deterministic degraded state the flag exists to produce.
            try? FileManager.default.removeItem(at: mediaStore.cacheDirectory)
        }
        // Either AI launch hook stubs the whole AI stack: both features
        // share one key store, so a test that stubs one must not leave the
        // other reading the real Keychain.
        if let scenario = Self.uiTestScenario(for: "-uitest-ai") ?? Self.uiTestScenario(for: "-uitest-photo-match") {
            let store = InMemoryAPIKeyStore(key: scenario == "no-key" ? nil : "uitest-stub-key")
            aiKeyStore = store
            aiSuggestionService = StubSuggestionService.uiTestService(scenario: scenario)
            aiPhotoMatchService = StubPhotoMatchService.uiTestService(scenario: scenario)
        } else {
            let store = KeychainAPIKeyStore()
            aiKeyStore = store
            aiSuggestionService = OpenRouterSuggestionService(keyStore: store)
            aiPhotoMatchService = OpenRouterPhotoMatchService(keyStore: store)
        }
    }

    /// The value following `flag` in the launch arguments, e.g. "success"
    /// for `-uitest-ai success`.
    private static func uiTestScenario(for flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    let sharedModelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.apiKeyStore, aiKeyStore)
                .environment(\.routineSuggestionService, aiSuggestionService)
                .environment(\.photoMatchService, aiPhotoMatchService)
                .environment(\.exerciseMediaStore, mediaStore)
        }
        .modelContainer(sharedModelContainer)
    }
}
