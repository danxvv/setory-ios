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

extension EnvironmentValues {
    @Entry var apiKeyStore: any APIKeyStoring = KeychainAPIKeyStore()
    @Entry var routineSuggestionService: any RoutineSuggestionService = OpenRouterSuggestionService()
    @Entry var photoMatchService: any PhotoExerciseMatchService = OpenRouterPhotoMatchService()
}
