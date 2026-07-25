//
//  ExerciseThumbnailView.swift
//  gymapp
//
//  Row-sized exercise thumbnail from the bundled catalog media, falling
//  back to the category icon for exercises without media (legacy orphans,
//  custom exercises).
//

import SwiftUI

struct ExerciseThumbnailView: View {
    let exercise: Exercise
    var size: CGFloat = 40

    @Environment(\.exerciseMediaStore) private var mediaStore

    var body: some View {
        Group {
            if exercise.hasMedia, let image = mediaStore.thumbnail(forExerciseId: exercise.id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: exercise.category == .cardio ? "heart.circle" : "dumbbell")
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 5))
    }
}
