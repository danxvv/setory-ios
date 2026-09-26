//
//  SuggestRoutineSheet.swift
//  Setory
//
//  The "Suggest with AI" flow: optional goal → generate (cancellable
//  progress) → hand the validated draft back to the Routines list for
//  review in the template editor. Without a stored key the sheet only
//  explains how to enable the feature and never touches the network.
//
//  The request cycle lives in SuggestionFlow; the no-key, progress, and
//  failure states come from AIFlowScaffold, shared with photo matching.
//

import SwiftUI
import SwiftData

/// A validated suggestion ready for review: the pre-filled draft plus the
/// model's rationale. Identifiable so it can drive a `.sheet(item:)`.
struct RoutineSuggestion: Identifiable {
    let id = UUID()
    let draft: TemplateDraft
    let rationale: String
}

struct SuggestRoutineSheet: View {
    @Environment(\.apiKeyStore) private var keyStore
    @Environment(\.routineSuggestionService) private var suggestionService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Called right before the sheet dismisses itself; the parent presents
    /// the editor once this sheet is gone.
    let onSuggestion: (RoutineSuggestion) -> Void

    @State private var flow = SuggestionFlow()
    @State private var hasKey = false
    @State private var goal = ""
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                if hasKey {
                    Section {
                        SetoryIntro(
                            title: "A routine that fits you",
                            subtitle: "Set a direction. Review your plan before saving.",
                            symbol: "sparkles"
                        )
                    }
                    .listRowBackground(SetoryTheme.softAccent)
                    goalSection
                    generateSection
                } else {
                    AIKeyRequiredSection(
                        explanation: "Routine suggestions need an OpenRouter API key. Add yours in AI Settings to enable them.",
                        explanationIdentifier: "suggest-key-required-text",
                        openSettingsIdentifier: "suggest-open-settings-button",
                        onOpenSettings: { showSettings = true }
                    )
                }
            }
            .setoryListStyle()
            .navigationTitle("Suggest with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        flow.cancel()
                        dismiss()
                    }
                    .accessibilityIdentifier("suggest-dismiss-button")
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: refreshKeyState) {
                AISettingsView()
            }
            .aiFailureAlert(
                "Suggestion failed",
                error: $flow.error,
                onRetry: generate,
                onOpenSettings: { showSettings = true }
            )
            .onAppear(perform: refreshKeyState)
        }
    }

    // MARK: - Goal and generation

    private var goalSection: some View {
        Section {
            TextField("e.g. focus legs, 45 minutes", text: $goal, axis: .vertical)
                .lineLimit(3...5)
                .disabled(flow.isGenerating)
                .accessibilityIdentifier("suggest-goal-field")
        } header: {
            Text("Goal (optional)")
        } footer: {
            Text("The suggestion balances your recent workout history; add a goal to steer it.")
        }
    }

    private var generateSection: some View {
        Section {
            if flow.isGenerating {
                AIProgressRows(
                    message: "Generating suggestion…",
                    progressIdentifier: "suggest-progress",
                    cancelTitle: "Cancel Generation",
                    cancelIdentifier: "suggest-cancel-button",
                    onCancel: flow.cancel
                )
            } else {
                Button {
                    generate()
                } label: {
                    Label("Generate", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SetoryPrimaryButtonStyle())
                .accessibilityIdentifier("suggest-generate-button")
            }
        }
    }

    // MARK: - Actions

    private func refreshKeyState() {
        hasKey = keyStore.read() != nil
    }

    private func generate() {
        flow.generate(
            goal: goal,
            context: modelContext,
            service: suggestionService
        ) { suggestion in
            onSuggestion(suggestion)
            dismiss()
        }
    }
}

// Previews use the Debug-only stub AI dependencies, so they compile
// out of Release along with the rest of TestSupport.
#if DEBUG

#Preview {
    SuggestRoutineSheet { _ in }
        .environment(\.apiKeyStore, InMemoryAPIKeyStore(key: "preview-key"))
        .environment(\.routineSuggestionService, StubSuggestionService(
            outcome: .success(StubSuggestionService.uiTestRoutine),
            delay: .seconds(1)
        ))
        .modelContainer(
            for: [Exercise.self, WorkoutSession.self, WorkoutSeries.self],
            inMemory: true
        )
}

#endif
