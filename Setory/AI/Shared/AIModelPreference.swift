//
//  AIModelPreference.swift
//  Setory
//
//  The one model setting every AI feature honors. Lives in the shared layer
//  because both the suggestion and photo-match clients resolve it — before
//  this file existed, the photo client reached across a feature boundary to
//  read the suggestion service's statics.
//
//  The defaults key is a preference, not a secret, so it belongs in
//  UserDefaults; the API key itself never leaves the Keychain.
//

import Foundation

enum AIModelPreference {
    /// Cheap, structured-outputs-capable default (verified on openrouter.ai
    /// 2026-07); users can override it in AI Settings.
    static let defaultModel = "openai/gpt-5.4-mini"
    /// UserDefaults key of the model override.
    static let overrideDefaultsKey = "aiModelOverride"

    /// The override when one is set (non-blank), otherwise the default.
    static func resolvedModel(defaults: UserDefaults) -> String {
        let override = defaults.string(forKey: overrideDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let override, !override.isEmpty else { return defaultModel }
        return override
    }
}
