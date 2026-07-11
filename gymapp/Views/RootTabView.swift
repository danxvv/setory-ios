//
//  RootTabView.swift
//  gymapp
//

import SwiftUI
import SwiftData

/// App root: the "Log" tab (daily logging), the "Exercises" tab (catalog
/// browser and detail screens), the "Routines" tab (saved session
/// history), and the "Progress" tab (charts and stats). Each tab owns its
/// own navigation stack — ContentView, ExerciseLibraryView, and
/// ProgressTabView bring their own; the Routines tab gets one here.
struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Log", systemImage: "square.and.pencil") {
                ContentView()
            }
            Tab("Exercises", systemImage: "figure.strengthtraining.traditional") {
                ExerciseLibraryView()
            }
            Tab("Routines", systemImage: "list.bullet.rectangle") {
                NavigationStack {
                    RoutineListView()
                }
            }
            Tab("Progress", systemImage: "chart.xyaxis.line") {
                ProgressTabView()
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(
            for: [Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self, RoutineTemplateItem.self],
            inMemory: true
        )
}
