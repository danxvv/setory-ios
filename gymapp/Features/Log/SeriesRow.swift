//
//  SeriesRow.swift
//  gymapp
//
//  Row presentation shared by the logging screen's plan checklist and its
//  series list: the numbered series row, and the thumbnail that opens an
//  exercise's animated demonstration.
//

import SwiftUI

/// One numbered series row: position badge, thumbnail, name, and value summary.
struct SeriesRow: View {
    let exercise: Exercise?
    let name: String
    let summary: String
    /// Zero-based position; displayed one-based.
    let index: Int
    let onShowMedia: (Exercise) -> Void

    var body: some View {
        HStack(spacing: 12) {
            NumberBadge(index: index)
            RoutineThumbnail(exercise: exercise, onShowMedia: onShowMedia)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.body.weight(.medium))
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Routine-row thumbnail: opens the media viewer when the exercise has
/// media, stays inert (category-icon fallback) when it doesn't, and
/// shows a neutral placeholder when the exercise is missing (deleted
/// catalog entry). Borderless so the tap never triggers the row's
/// primary action.
struct RoutineThumbnail: View {
    let exercise: Exercise?
    let onShowMedia: (Exercise) -> Void

    var body: some View {
        if let exercise, exercise.hasMedia {
            Button {
                onShowMedia(exercise)
            } label: {
                ExerciseThumbnailView(exercise: exercise)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "Show demonstration for \(exercise.localizedName)"))
            .accessibilityIdentifier("routine-thumbnail-\(exercise.id)")
        } else if let exercise {
            ExerciseThumbnailView(exercise: exercise)
        } else {
            Image(systemName: "questionmark")
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
