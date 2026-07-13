//
//  AIEnvironment.swift
//  gymapp
//
//  Environment seams for the AI feature, following the app's
//  default-with-substitution injection style: real Keychain + OpenRouter
//  unless gymappApp overrides them for the -uitest-ai launch hook.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var apiKeyStore: any APIKeyStoring = KeychainAPIKeyStore()
    @Entry var routineSuggestionService: any RoutineSuggestionService = OpenRouterSuggestionService()
}
