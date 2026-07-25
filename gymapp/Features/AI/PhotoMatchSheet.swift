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

    /// Capture and results live in one sheet; loading is tracked by
    /// `isMatching` so the attached photos stay visible underneath.
    private enum Phase {
        case capture
        case results([Match])
    }

    /// A validated match paired with its local record — the only source of
    /// name, muscles, and thumbnail.
    private struct Match: Identifiable {
        let exercise: Exercise
        let confidence: PhotoMatchConfidence

        var id: String { exercise.id }
    }

    @State private var phase: Phase = .capture
    @State private var photos: [UIImage] = []
    /// Optional hints. Both survive a trip through the results phase and
    /// die with the sheet — nothing here is ever persisted.
    @State private var descriptionText = ""
    @State private var selectedMuscle: Muscle?
    /// How many stored exercises the selected muscle keeps. nil means no
    /// muscle is selected; 0 means the selection is a dead end — sending it
    /// would ship an empty schema enum, which OpenRouter rejects.
    @State private var muscleMatchCount: Int?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedIds: Set<String> = []
    @State private var isMatching = false
    @State private var matchTask: Task<Void, Never>?
    @State private var matchError: AIError?
    @State private var hasKey = false
    @State private var showCamera = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                if hasKey {
                    switch phase {
                    case .capture:
                        photosSection
                        detailsSection
                        matchSection
                    case .results(let matches):
                        resultsSection(matches)
                    }
                } else {
                    keyRequiredSection
                }
            }
            .navigationTitle("Match from Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        matchTask?.cancel()
                        dismiss()
                    }
                    .accessibilityIdentifier("photo-match-cancel-button")
                }
                if case .results(let matches) = phase {
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
            .alert(
                "Photo match failed",
                isPresented: Binding(
                    get: { matchError != nil },
                    set: { if !$0 { matchError = nil } }
                ),
                presenting: matchError
            ) { error in
                Button("Retry") {
                    findMatches()
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
            .onChange(of: pickerItems) {
                loadPickedPhotos()
            }
            .onChange(of: selectedMuscle) {
                refreshMuscleMatchCount()
            }
        }
    }

    // MARK: - No-key state

    private var keyRequiredSection: some View {
        Section {
            Text("Photo matching needs an OpenRouter API key. Add yours in AI Settings to enable it.")
                .accessibilityIdentifier("photo-match-key-required-text")
            Button("Open AI Settings") {
                showSettings = true
            }
            .accessibilityIdentifier("photo-match-open-settings-button")
        }
    }

    // MARK: - Capture phase

    private var canAttachMore: Bool { photos.count < PhotoMatchRequestBuilder.maxPhotos }

    private var photosSection: some View {
        Section {
            if photos.isEmpty {
                Text("Add a photo of the machine, the equipment, or the exercise being performed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                            photoPreview(photo, at: index)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if canAttachMore {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: PhotoMatchRequestBuilder.maxPhotos - photos.count,
                    matching: .images
                ) {
                    Label("Choose Photos", systemImage: "photo.on.rectangle")
                }
                .disabled(isMatching)
                .accessibilityIdentifier("photo-match-library-button")

                if CameraCaptureView.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .disabled(isMatching)
                    .accessibilityIdentifier("photo-match-camera-button")
                }

                if let photoMatchFixture {
                    // Keeps XCUITest out of the camera and the system photo
                    // picker. The image is injected; this view knows nothing
                    // about launch arguments.
                    Button {
                        attach(photoMatchFixture)
                    } label: {
                        // Verbatim: test-only affordance, never localized.
                        Text(verbatim: "Attach Test Photo")
                    }
                    .accessibilityIdentifier("photo-match-attach-fixture-button")
                }
            }
        } header: {
            Text("Photos")
        } footer: {
            Text("Up to \(PhotoMatchRequestBuilder.maxPhotos) photos are sent to OpenRouter under your API key.")
        }
    }

    private func photoPreview(_ photo: UIImage, at index: Int) -> some View {
        Image(uiImage: photo)
            .resizable()
            .scaledToFill()
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                Button {
                    photos.remove(at: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .padding(4)
                .disabled(isMatching)
                .accessibilityLabel("Remove photo")
                .accessibilityIdentifier("photo-match-remove-\(index)")
            }
    }

    /// Optional context the photos can't carry: a line of prose and the
    /// muscle the machine trains. The muscle is the sharper tool — it
    /// shrinks the catalog the model may answer from.
    private var detailsSection: some View {
        Section {
            TextField("What the machine or exercise looks like", text: $descriptionText)
                .disabled(isMatching)
                .accessibilityIdentifier("photo-match-description-field")

            Menu {
                Button("Any muscle") { selectedMuscle = nil }
                ForEach(Muscle.allCases, id: \.self) { muscle in
                    Button {
                        selectedMuscle = muscle
                    } label: {
                        if selectedMuscle == muscle {
                            Label(muscle.displayName, systemImage: "checkmark")
                        } else {
                            Text(muscle.displayName)
                        }
                    }
                }
            } label: {
                // Concrete colors for the same reason as the result rows:
                // inside a Form, .primary/.secondary resolve against the
                // control's tint and render the whole label blue.
                HStack {
                    Text("Main muscle")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text(selectedMuscle?.displayName ?? String(localized: "Any muscle"))
                        .foregroundStyle(Color.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .contentShape(Rectangle())
            }
            .disabled(isMatching)
            .accessibilityIdentifier("photo-match-muscle-menu")

            if hasEmptyMuscleSelection {
                Text("No exercise in your library targets that muscle. Pick another main muscle or clear it.")
                    .font(.footnote)
                    .foregroundStyle(Color.orange)
                    .accessibilityIdentifier("photo-match-empty-muscle-note")
            }
        } header: {
            Text("Details")
        } footer: {
            Text("Optional. Picking a main muscle sends only that muscle's exercises to OpenRouter.")
        }
    }

    /// A muscle no stored exercise targets: the request is blocked rather
    /// than sent with an empty id enum.
    private var hasEmptyMuscleSelection: Bool { muscleMatchCount == 0 }

    private var matchSection: some View {
        Section {
            if isMatching {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Identifying exercises…")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("photo-match-progress")
                Button("Cancel Match", role: .destructive) {
                    matchTask?.cancel()
                }
                .accessibilityIdentifier("photo-match-cancel-match-button")
            } else {
                Button {
                    findMatches()
                } label: {
                    Label("Find Exercises", systemImage: "sparkle.magnifyingglass")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .disabled(photos.isEmpty || hasEmptyMuscleSelection)
                .accessibilityIdentifier("photo-match-find-button")
            }
        }
    }

    // MARK: - Results phase

    @ViewBuilder
    private func resultsSection(_ matches: [Match]) -> some View {
        if matches.isEmpty {
            Section {
                ContentUnavailableView(
                    "No matching exercises",
                    systemImage: "questionmark.circle",
                    description: Text("Try a photo that shows the whole machine or its label.")
                )
                .accessibilityIdentifier("photo-match-no-results")
                Button("Try Other Photos") {
                    phase = .capture
                }
                .accessibilityIdentifier("photo-match-retry-photos-button")
            }
        } else {
            Section {
                ForEach(matches) { match in
                    resultRow(match)
                }
            } header: {
                Text("Matches")
            } footer: {
                Text("Select the exercises to add to this routine.")
            }
        }
    }

    private func resultRow(_ match: Match) -> some View {
        Button {
            if selectedIds.contains(match.id) {
                selectedIds.remove(match.id)
            } else {
                selectedIds.insert(match.id)
            }
        } label: {
            HStack(spacing: 12) {
                ExerciseThumbnailView(exercise: match.exercise, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    // Concrete colors, not the hierarchical .primary /
                    // .secondary: inside a Form button those resolve
                    // against the button's tint and render everything blue.
                    Text(match.exercise.localizedName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.primary)
                    Text(match.confidence.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    if !match.exercise.primaryMuscles.isEmpty {
                        MuscleChips(muscles: match.exercise.primaryMuscles, emphasis: .primary)
                    }
                }
                Spacer()
                if selectedIds.contains(match.id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("photo-match-result-\(match.exercise.id)")
    }

    // MARK: - Actions

    private func refreshKeyState() {
        hasKey = keyStore.read() != nil
    }

    /// Recomputed whenever the selection changes so the blocked state shows
    /// before the user taps send. The store is small enough to filter in
    /// memory, and the sheet already fetches it wholesale to match.
    private func refreshMuscleMatchCount() {
        guard let selectedMuscle else {
            muscleMatchCount = nil
            return
        }
        let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        muscleMatchCount = PhotoMatchRequestBuilder
            .matchingExercises(exercises, muscle: selectedMuscle)
            .count
    }

    private func attach(_ image: UIImage) {
        guard canAttachMore else { return }
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
                guard canAttachMore,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { continue }
                attach(image)
            }
        }
    }

    private func findMatches() {
        matchError = nil
        guard !photos.isEmpty, !hasEmptyMuscleSelection else { return }
        isMatching = true
        matchTask = Task {
            defer { isMatching = false }
            do {
                let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
                let jpegs = photos.compactMap(PhotoPreprocessor.jpegData(from:))
                guard !jpegs.isEmpty else { throw AIError.badResponse }

                let payload = PhotoMatchRequestBuilder.payload(
                    exercises: exercises,
                    photos: jpegs,
                    description: descriptionText,
                    muscle: selectedMuscle
                )
                // A muscle nothing targets would ship an empty id enum,
                // which OpenRouter rejects; surface the note instead.
                guard !payload.catalog.isEmpty else {
                    muscleMatchCount = 0
                    return
                }
                let result = try await matchService.matchExercises(request: payload)

                // Resolve matched IDs to local records; name, muscles, and
                // media always come from these, never from the model.
                let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
                let matches = result.matches.compactMap { match in
                    exercisesById[match.exerciseId].map {
                        Match(exercise: $0, confidence: match.confidence)
                    }
                }
                selectedIds = []
                phase = .results(matches)
            } catch is CancellationError {
                // User cancelled: back to the attached photos, no alert.
            } catch let error as AIError {
                matchError = error
            } catch {
                matchError = .badResponse
            }
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
