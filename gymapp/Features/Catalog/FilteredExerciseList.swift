//
//  FilteredExerciseList.swift
//  gymapp
//
//  The list shell shared by the exercise library and both pickers: search,
//  muscle/equipment filters, localized-name order, and the empty state. The
//  caller supplies the row and owns the navigation title and toolbar.
//

import SwiftUI

struct FilteredExerciseList<Row: View>: View {
    let exercises: [Exercise]
    @ViewBuilder let row: (Exercise) -> Row

    @State private var searchText = ""
    @State private var filters = ExerciseFilters()

    private var filtered: [Exercise] {
        filters.apply(to: exercises, searchText: searchText).sorted(by: Exercise.byLocalizedName)
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No exercises found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search.")
                )
            } else {
                List(filtered, rowContent: row)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ExerciseFilterBar(filters: $filters)
                .background(.bar)
        }
        .searchable(text: $searchText, prompt: Text("Search exercises"))
    }
}
