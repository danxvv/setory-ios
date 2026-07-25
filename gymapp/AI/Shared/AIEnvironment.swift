//
//  AIEnvironment.swift
//  gymapp
//
//  Environment seams for the AI features, following the app's
//  default-with-substitution injection style: real Keychain + OpenRouter
//  unless gymappApp overrides them for the -uitest-ai and
//  -uitest-photo-match launch hooks.
//

import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var apiKeyStore: any APIKeyStoring = KeychainAPIKeyStore()
    @Entry var routineSuggestionService: any RoutineSuggestionService = OpenRouterSuggestionService()
    @Entry var photoMatchService: any PhotoExerciseMatchService = OpenRouterPhotoMatchService()
    /// Stand-in photo offered instead of the camera and system picker under
    /// the photo-match UI-test hook; nil everywhere else, always nil in
    /// Release. Injected like the services above so the feature view needs
    /// no knowledge of launch arguments.
    @Entry var photoMatchFixture: UIImage?
}
