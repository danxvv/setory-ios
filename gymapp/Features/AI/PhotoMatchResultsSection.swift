//
//  PhotoMatchResultsSection.swift
//  gymapp
//
//  The results phase of the photo match sheet: the matched exercises with
//  their confidence and muscle targets, or the nothing-recognized state.
//  Every displayed value comes from the local Exercise record the match
//  resolved to, never from the model response.
//

import SwiftUI

struct PhotoMatchResultsSection: View {
    let matches: [PhotoMatchFlow.Match]
    @Binding var selectedIds: Set<String>
    let onTryOtherPhotos: () -> Void

    var body: some View {
        if matches.isEmpty {
            Section {
                ContentUnavailableView(
                    "No matching exercises",
                    systemImage: "questionmark.circle",
                    description: Text("Try a photo that shows the whole machine or its label.")
                )
                .accessibilityIdentifier("photo-match-no-results")
                Button("Try Other Photos") {
                    onTryOtherPhotos()
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

    private func resultRow(_ match: PhotoMatchFlow.Match) -> some View {
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
}
