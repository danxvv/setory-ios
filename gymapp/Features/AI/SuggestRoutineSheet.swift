//
//  SuggestRoutineSheet.swift
//  gymapp
//
//  The "Suggest with AI" flow: optional goal → generate (cancellable
//  progress) → hand the validated draft back to the Routines list for
//  review in the template editor. Without a stored key the sheet only
//  explains how to enable the feature and never touches the network.
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

    @State private var hasKey = false
    @State private var goal = ""
    @State private var isGenerating = false
    @State private var generationTask: Task<Void, Never>?
    @State private var suggestionError: AIError?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                if hasKey {
                    goalSection
                    generateSection
                } else {
                    keyRequiredSection
                }
            }
            .navigationTitle("Suggest with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        generationTask?.cancel()
                        dismiss()
                    }
                    .accessibilityIdentifier("suggest-dismiss-button")
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: refreshKeyState) {
                AISettingsView()
            }
            .alert(
                "Suggestion failed",
                isPresented: Binding(
                    get: { suggestionError != nil },
                    set: { if !$0 { suggestionError = nil } }
                ),
                presenting: suggestionError
            ) { error in
                Button("Retry") {
                    generate()
                }
                if error.pointsToSettings {
                    Button("Open AI Settings") {
                        showSettings = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { error in
                Text(error.errorDescription ?? "")
            }
            .onAppear(perform: refreshKeyState)
        }
    }

    // MARK: - No-key state

    private var keyRequiredSection: some View {
        Section {
            Text("Routine suggestions need an OpenRouter API key. Add yours in AI Settings to enable them.")
                .accessibilityIdentifier("suggest-key-required-text")
            Button("Open AI Settings") {
                showSettings = true
            }
            .accessibilityIdentifier("suggest-open-settings-button")
        }
    }

    // MARK: - Goal and generation

    private var goalSection: some View {
        Section {
            TextField("e.g. focus legs, 45 minutes", text: $goal, axis: .vertical)
                .lineLimit(1...3)
                .disabled(isGenerating)
                .accessibilityIdentifier("suggest-goal-field")
        } header: {
            Text("Goal (optional)")
        } footer: {
            Text("The suggestion balances your recent workout history; add a goal to steer it.")
        }
    }

    private var generateSection: some View {
        Section {
            if isGenerating {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Generating suggestion…")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("suggest-progress")
                Button("Cancel Generation", role: .destructive) {
                    generationTask?.cancel()
                }
                .accessibilityIdentifier("suggest-cancel-button")
            } else {
                Button {
                    generate()
                } label: {
                    Label("Generate", systemImage: "sparkles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("suggest-generate-button")
            }
        }
    }

    // MARK: - Actions

    private func refreshKeyState() {
        hasKey = keyStore.read() != nil
    }

    private func generate() {
        suggestionError = nil
        isGenerating = true
        generationTask = Task {
            defer { isGenerating = false }
            do {
                let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
                var descriptor = FetchDescriptor<WorkoutSession>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                descriptor.fetchLimit = SuggestionPromptBuilder.maxHistorySessions
                let sessions = try modelContext.fetch(descriptor)

                let payload = SuggestionPromptBuilder.payload(
                    exercises: exercises,
                    sessions: sessions,
                    goal: goal
                )
                let routine = try await suggestionService.suggestRoutine(request: payload)

                // Resolve suggested IDs to local records; muscle metadata
                // always comes from these, never from the model.
                let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
                let items = routine.items.compactMap { item in
                    exercisesById[item.exerciseId].map {
                        TemplateDraft.Item(exercise: $0, targetSets: item.targetSets)
                    }
                }
                guard !items.isEmpty else { throw AIError.emptySuggestion }

                onSuggestion(RoutineSuggestion(
                    draft: TemplateDraft(name: routine.name, items: items),
                    rationale: routine.rationale
                ))
                dismiss()
            } catch is CancellationError {
                // User cancelled: back to the sheet, no error alert.
            } catch let error as AIError {
                suggestionError = error
            } catch {
                suggestionError = .badResponse
            }
        }
    }
}

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
