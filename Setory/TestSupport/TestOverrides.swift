//
//  TestOverrides.swift
//  Setory
//
//  The single seam between the app and its automated-test scaffolding. Every
//  member here is a no-op in Release, so no stub service, in-memory key store,
//  data-wipe path, or fixture image exists in a shipped binary and the
//  `-uitest-*` arguments are inert.
//
//  This is the only file with a Debug/Release conditional: SetoryApp,
//  AppModelContainer, and the feature views call these members
//  unconditionally, which is what keeps the gating from spreading.
//
//  The scaffolding cannot move to the test target — XCUITest drives the app
//  out of process and cannot inject types into it.
//

import Foundation
import SwiftData
import UIKit

enum TestOverrides {

    /// True when a UI-test launch asked for animations to be disabled.
    static var disablesAnimations: Bool {
        #if DEBUG
        return LaunchOptions.current.isUITestLaunch
        #else
        return false
        #endif
    }

    /// True when the media store's network path must stay off.
    static var disablesMediaNetwork: Bool {
        #if DEBUG
        return LaunchOptions.current.disablesMediaNetwork
        #else
        return false
        #endif
    }

    /// Substitute AI dependencies for a UI-test scenario, or nil to use the
    /// Keychain and the real OpenRouter clients.
    static func aiDependencies() -> (
        keyStore: any APIKeyStoring,
        suggestion: any RoutineSuggestionService,
        photoMatch: any PhotoExerciseMatchService
    )? {
        #if DEBUG
        guard let scenario = LaunchOptions.current.aiScenario else { return nil }
        let store = InMemoryAPIKeyStore(key: scenario == "no-key" ? nil : "uitest-stub-key")
        return (
            store,
            StubSuggestionService.uiTestService(scenario: scenario),
            StubPhotoMatchService.uiTestService(scenario: scenario)
        )
        #else
        return nil
        #endif
    }

    /// The bundled image the photo match flow offers instead of the camera and
    /// the system picker, or nil outside that hook.
    static var photoMatchFixture: UIImage? {
        #if DEBUG
        guard LaunchOptions.current.exposesPhotoMatchFixture else { return nil }
        return PhotoMatchFixture.image
        #else
        return nil
        #endif
    }

    /// Applies the store-level launch hooks in order: reset, then session
    /// seeding. Catalog seeding is the app's own concern and runs between them.
    static func applyStoreReset(context: ModelContext) {
        #if DEBUG
        guard LaunchOptions.current.resetsStore else { return }
        UITestReset.apply(context: context)
        #endif
    }

    static func applySessionSeeding(context: ModelContext) {
        #if DEBUG
        guard LaunchOptions.current.seedsSessions else { return }
        do {
            try UITestSeeding.seedSessions(context: context)
        } catch {
            assertionFailure("UI-test session seeding failed: \(error)")
        }
        #endif
    }
}
