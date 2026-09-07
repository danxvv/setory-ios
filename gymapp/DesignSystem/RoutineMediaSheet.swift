//
//  RoutineMediaSheet.swift
//  gymapp
//
//  Media viewer sheet for the logging screen's routine rows: wraps the
//  shared ExerciseMediaView (on-demand fetch, disk cache, thumbnail
//  degradation with retry, attribution) with the exercise's name as title
//  and a Done button.
//

import SwiftUI

struct RoutineMediaSheet: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ExerciseMediaView(exercise: exercise)
                .padding(20)
                .frame(maxHeight: .infinity)
                .background(GymTheme.canvas)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("routine-media-\(exercise.id)")
                .navigationTitle(exercise.localizedName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .accessibilityIdentifier("routine-media-done")
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}
