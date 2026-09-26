//
//  ExerciseMediaView.swift
//  Setory
//
//  The detail screen's media section: plays the exercise's animated
//  demonstration (downloading and caching it on first view) and degrades
//  to the bundled thumbnail with a quiet retry affordance when the
//  animation can't be fetched. Always shows the Gym visual attribution.
//

import SwiftUI

struct ExerciseMediaView: View {
    let exercise: Exercise

    @Environment(\.exerciseMediaStore) private var mediaStore
    @State private var gifData: Data?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if let gifData {
                    AnimatedGIFView(data: gifData)
                        .accessibilityIdentifier("exercise-media-animation")
                } else {
                    thumbnail
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .frame(width: 180, height: 180)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            if loadFailed {
                Button {
                    Task { await load() }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.footnote.weight(.medium))
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("media-retry-button")
            }

            Text(verbatim: ExerciseMediaStore.attribution)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("media-attribution")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(SetoryTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .task(id: exercise.id) { await load() }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = mediaStore.thumbnail(forExerciseId: exercise.id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: exercise.category == .cardio ? "heart.circle" : "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
        }
    }

    private func load() async {
        guard let gifFileName = exercise.gifFileName, gifData == nil else { return }
        loadFailed = false
        isLoading = true
        defer { isLoading = false }
        do {
            gifData = try await mediaStore.gifData(forExerciseId: exercise.id, gifFileName: gifFileName)
        } catch {
            loadFailed = true
        }
    }
}
