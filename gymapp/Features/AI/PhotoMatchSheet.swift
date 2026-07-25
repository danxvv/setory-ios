//
//  PhotoMatchSheet.swift
//  gymapp
//
//  The "Match from Photo" flow: attach up to three photos (camera or
//  library) → send them with the catalog to the vision model (cancellable
//  progress) → pick from the matched exercises, which are handed back to
//  the template editor. One sheet with internal phases, so nothing has to
//  survive a dismiss/present handoff. Without a stored key the sheet only
//  explains how to enable the feature and never touches the network.
//
//  The request cycle lives in PhotoMatchFlow, the sections in
//  PhotoMatchCaptureSection / PhotoMatchResultsSection, and the no-key,
//  progress, and failure states in AIFlowScaffold, shared with suggestions.
//

import SwiftUI
import SwiftData
import PhotosUI

struct PhotoMatchSheet: View {
    /// Called with the exercises the user confirmed; the sheet dismisses
    /// itself right after. Same shape as ExerciseMultiPicker's callback.
    let onAdd: ([Exercise]) -> Void

    @Environment(\.apiKeyStore) private var keyStore
    @Environment(\.photoMatchService) private var matchService
    @Environment(\.photoMatchFixture) private var photoMatchFixture
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var flow = PhotoMatchFlow()
    @State private var photos: [UIImage] = []
    /// Optional hints. Both survive a trip through the results phase and
    /// die with the sheet — nothing here is ever persisted.
    @State private var descriptionText = ""
    @State private var selectedMuscle: Muscle?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedIds: Set<String> = []
    @State private var hasKey = false
    @State private var showCamera = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                if hasKey {
                    switch flow.phase {
                    case .capture:
                        PhotoMatchPhotosSection(
                            photos: $photos,
                            pickerItems: $pickerItems,
                            isMatching: flow.isMatching,
                            fixture: photoMatchFixture,
                            onTakePhoto: { showCamera = true },
                            onAttachFixture: attach
                        )
                        PhotoMatchDetailsSection(
                            descriptionText: $descriptionText,
                            selectedMuscle: $selectedMuscle,
                            isMatching: flow.isMatching,
                            hasEmptyMuscleSelection: flow.hasEmptyMuscleSelection
                        )
                        PhotoMatchSendSection(
                            isMatching: flow.isMatching,
                            canSend: !photos.isEmpty && !flow.hasEmptyMuscleSelection,
                            onFind: findMatches,
                            onCancel: flow.cancel
                        )
                    case .results(let matches):
                        PhotoMatchResultsSection(
                            matches: matches,
                            selectedIds: $selectedIds,
                            onTryOtherPhotos: flow.returnToCapture
                        )
                    }
                } else {
                    AIKeyRequiredSection(
                        explanation: "Photo matching needs an OpenRouter API key. Add yours in AI Settings to enable it.",
                        explanationIdentifier: "photo-match-key-required-text",
                        openSettingsIdentifier: "photo-match-open-settings-button",
                        onOpenSettings: { showSettings = true }
                    )
                }
            }
            .navigationTitle("Match from Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        flow.cancel()
                        dismiss()
                    }
                    .accessibilityIdentifier("photo-match-cancel-button")
                }
                if case .results(let matches) = flow.phase {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            onAdd(matches.filter { selectedIds.contains($0.id) }.map(\.exercise))
                            dismiss()
                        }
                        .disabled(selectedIds.isEmpty)
                        .accessibilityIdentifier("photo-match-add-button")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    attach(image)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showSettings, onDismiss: refreshKeyState) {
                AISettingsView()
            }
            .aiFailureAlert(
                "Photo match failed",
                error: $flow.error,
                onRetry: findMatches,
                onOpenSettings: { showSettings = true }
            )
            .onAppear(perform: refreshKeyState)
            .onChange(of: pickerItems) {
                loadPickedPhotos()
            }
            .onChange(of: selectedMuscle) {
                flow.refreshMuscleMatchCount(muscle: selectedMuscle, context: modelContext)
            }
        }
    }

    // MARK: - Actions

    private func refreshKeyState() {
        hasKey = keyStore.read() != nil
    }

    private func attach(_ image: UIImage) {
        guard photos.count < PhotoMatchRequestBuilder.maxPhotos else { return }
        photos.append(image)
    }

    /// PhotosPicker hands back opaque items; load them into images and clear
    /// the selection so re-picking the same asset works.
    private func loadPickedPhotos() {
        let items = pickerItems
        guard !items.isEmpty else { return }
        pickerItems = []
        Task {
            for item in items {
                guard photos.count < PhotoMatchRequestBuilder.maxPhotos,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { continue }
                attach(image)
            }
        }
    }

    private func findMatches() {
        flow.findMatches(
            photos: photos,
            description: descriptionText,
            muscle: selectedMuscle,
            context: modelContext,
            service: matchService
        ) {
            selectedIds = []
        }
    }
}

// Previews use the Debug-only stub AI dependencies, so they compile
// out of Release along with the rest of TestSupport.
#if DEBUG

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return PhotoMatchSheet { _ in }
        .environment(\.apiKeyStore, InMemoryAPIKeyStore(key: "preview-key"))
        .environment(\.photoMatchService, StubPhotoMatchService(
            outcome: .success(StubPhotoMatchService.uiTestResult),
            delay: .seconds(1)
        ))
        .modelContainer(container)
}

#endif
