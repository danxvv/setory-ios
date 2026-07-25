//
//  AIError.swift
//  gymapp
//
//  The failure taxonomy shared by every AI feature: routine suggestion and
//  photo exercise match both map their OpenRouter exchanges onto these
//  cases, so a given HTTP status produces the same message and the same
//  recovery route in both flows. Key- and credit-related cases steer the
//  user to AI Settings.
//

import Foundation

enum AIError: Error, Equatable, LocalizedError {
    case missingAPIKey
    case network
    case invalidKey
    case insufficientCredits
    case rateLimited
    case badResponse
    case emptySuggestion

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            String(localized: "An OpenRouter API key is required.")
        case .network:
            String(localized: "Couldn't reach OpenRouter. Check your connection and try again.")
        case .invalidKey:
            String(localized: "Your API key appears to be invalid. Update it in AI Settings.")
        case .insufficientCredits:
            String(localized: "Your OpenRouter account is out of credits. Add credits or update the key in AI Settings.")
        case .rateLimited:
            String(localized: "Too many requests right now. Try again in a moment.")
        case .badResponse:
            String(localized: "OpenRouter returned an unexpected response. Try again.")
        case .emptySuggestion:
            String(localized: "The model didn't suggest any usable exercises. Try again.")
        }
    }

    /// True for failures the user fixes in AI Settings rather than by retrying.
    var pointsToSettings: Bool {
        switch self {
        case .missingAPIKey, .invalidKey, .insufficientCredits: true
        case .network, .rateLimited, .badResponse, .emptySuggestion: false
        }
    }
}
