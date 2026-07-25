//
//  AISettingsView.swift
//  gymapp
//
//  AI configuration sheet (from the Routines tab toolbar): OpenRouter API
//  key entry backed by the Keychain, model-ID override, and the privacy
//  note. The stored key is never echoed back — the field always starts
//  empty and saving replaces whatever was stored.
//

import SwiftUI

struct AISettingsView: View {
    @Environment(\.apiKeyStore) private var keyStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(OpenRouterSuggestionService.modelOverrideDefaultsKey) private var modelOverride = ""

    @State private var enteredKey = ""
    @State private var isKeyConfigured = false

    var body: some View {
        NavigationStack {
            Form {
                keySection
                modelSection
                privacySection
                aboutSection
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("ai-settings-done-button")
                }
            }
            .onAppear {
                isKeyConfigured = keyStore.read() != nil
            }
        }
    }

    // MARK: - API key

    private var trimmedKey: String {
        enteredKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var keySection: some View {
        Section {
            if isKeyConfigured {
                Label("API key configured", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("ai-key-configured-label")
            }
            SecureField("OpenRouter API Key", text: $enteredKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("ai-api-key-field")
            Button("Save Key") {
                keyStore.save(trimmedKey)
                enteredKey = ""
                isKeyConfigured = true
            }
            .disabled(trimmedKey.isEmpty)
            .accessibilityIdentifier("ai-save-key-button")
            if isKeyConfigured {
                Button("Clear Key", role: .destructive) {
                    keyStore.clear()
                    enteredKey = ""
                    isKeyConfigured = false
                }
                .accessibilityIdentifier("ai-clear-key-button")
            }
        } header: {
            Text("API Key")
        } footer: {
            Text("Stored securely in the Keychain and never shown again after saving. Saving replaces the previous key.")
        }
    }

    // MARK: - Model override

    private var modelSection: some View {
        Section {
            TextField("Model ID", text: $modelOverride)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("ai-model-field")
        } header: {
            Text("Model")
        } footer: {
            Text("Leave empty to use the default: \(OpenRouterSuggestionService.defaultModel)")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About & Licenses", systemImage: "info.circle")
            }
            .accessibilityIdentifier("about-licenses-link")
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            Text("When you request a suggestion, your exercise IDs, set counts, muscle data, session dates, and optional goal are sent to OpenRouter under your API key. When you request a photo match, the photos you attach are sent along with the exercise catalog (IDs, names, and muscle data); the app never stores them. Requests happen only when you ask for a suggestion or a photo match.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("ai-privacy-note")
        } header: {
            Text("Privacy")
        }
    }
}

#Preview {
    AISettingsView()
        .environment(\.apiKeyStore, InMemoryAPIKeyStore())
}
