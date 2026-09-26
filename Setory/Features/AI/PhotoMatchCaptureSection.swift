//
//  PhotoMatchCaptureSection.swift
//  Setory
//
//  The capture phase of the photo match sheet: the attached photos with their
//  sources, the optional hints, and the send action. Sections inside the
//  sheet's own Form.
//

import SwiftUI
import PhotosUI

struct PhotoMatchPhotosSection: View {
    @Binding var photos: [UIImage]
    @Binding var pickerItems: [PhotosPickerItem]
    let isMatching: Bool
    /// Injected stand-in photo for automated tests; nil in normal use and
    /// always nil in Release.
    let fixture: UIImage?
    let onTakePhoto: () -> Void
    let onAttachFixture: (UIImage) -> Void

    private var canAttachMore: Bool { photos.count < PhotoMatchRequestBuilder.maxPhotos }

    var body: some View {
        Section {
            if photos.isEmpty {
                SetoryIntro(
                    title: "Find it with a photo",
                    subtitle: "Add a photo of the machine, the equipment, or the exercise being performed.",
                    symbol: "camera.viewfinder"
                )
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
                        onTakePhoto()
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .disabled(isMatching)
                    .accessibilityIdentifier("photo-match-camera-button")
                }

                if let fixture {
                    // Keeps XCUITest out of the camera and the system photo
                    // picker. The image is injected; this view knows nothing
                    // about launch arguments.
                    Button {
                        onAttachFixture(fixture)
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
            .frame(width: 104, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                Button {
                    photos.remove(at: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .padding(4)
                .disabled(isMatching)
                .accessibilityLabel("Remove photo")
                .accessibilityIdentifier("photo-match-remove-\(index)")
            }
    }
}

/// Optional context the photos can't carry: a line of prose and the
/// muscle the machine trains. The muscle is the sharper tool — it
/// shrinks the catalog the model may answer from.
struct PhotoMatchDetailsSection: View {
    @Binding var descriptionText: String
    @Binding var selectedMuscle: Muscle?
    let isMatching: Bool
    let hasEmptyMuscleSelection: Bool

    var body: some View {
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
}

struct PhotoMatchSendSection: View {
    let isMatching: Bool
    let canSend: Bool
    let onFind: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Section {
            if isMatching {
                AIProgressRows(
                    message: "Identifying exercises…",
                    progressIdentifier: "photo-match-progress",
                    cancelTitle: "Cancel Match",
                    cancelIdentifier: "photo-match-cancel-match-button",
                    onCancel: onCancel
                )
            } else {
                Button {
                    onFind()
                } label: {
                    Label("Find Exercises", systemImage: "sparkle.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SetoryPrimaryButtonStyle())
                .disabled(!canSend)
                .accessibilityIdentifier("photo-match-find-button")
            }
        }
    }
}
