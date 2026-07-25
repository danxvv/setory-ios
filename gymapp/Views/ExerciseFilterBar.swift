//
//  ExerciseFilterBar.swift
//  gymapp
//
//  Muscle and equipment filters shared by the exercise library and the
//  exercise pickers. Filters combine with each other and with search; the
//  bar lives above the list (not in the navigation bar) so it stays
//  visible while search is active.
//

import SwiftUI

/// Active filter selection plus the shared filter pipeline.
struct ExerciseFilters: Equatable {
    var muscle: Muscle?
    var equipment: Equipment?

    var isActive: Bool { muscle != nil || equipment != nil }

    /// Case- and diacritic-insensitive search combined with the active
    /// filters. Preserves the input order (callers sort).
    func apply(to exercises: [Exercise], searchText: String) -> [Exercise] {
        var result = exercises
        if let muscle {
            result = result.filter { $0.primaryMuscles.contains(muscle) }
        }
        if let equipment {
            result = result.filter { $0.equipment == equipment }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.localizedName.localizedStandardContains(searchText) }
        }
        return result
    }
}

struct ExerciseFilterBar: View {
    @Binding var filters: ExerciseFilters

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Button("All muscles") { filters.muscle = nil }
                ForEach(Muscle.allCases, id: \.self) { muscle in
                    Button {
                        filters.muscle = muscle
                    } label: {
                        if filters.muscle == muscle {
                            Label(muscle.displayName, systemImage: "checkmark")
                        } else {
                            Text(muscle.displayName)
                        }
                    }
                }
            } label: {
                chip(
                    text: filters.muscle?.displayName ?? String(localized: "Muscle"),
                    isActive: filters.muscle != nil
                )
            }
            .accessibilityIdentifier("filter-muscle")

            Menu {
                Button("All equipment") { filters.equipment = nil }
                ForEach(Equipment.allCases, id: \.self) { equipment in
                    Button {
                        filters.equipment = equipment
                    } label: {
                        if filters.equipment == equipment {
                            Label(equipment.displayName, systemImage: "checkmark")
                        } else {
                            Text(equipment.displayName)
                        }
                    }
                }
            } label: {
                chip(
                    text: filters.equipment?.displayName ?? String(localized: "Equipment"),
                    isActive: filters.equipment != nil
                )
            }
            .accessibilityIdentifier("filter-equipment")

            if filters.isActive {
                Button {
                    filters = ExerciseFilters()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Clear filters"))
                .accessibilityIdentifier("filter-clear")
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func chip(text: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? AnyShapeStyle(.tint.opacity(0.18)) : AnyShapeStyle(.quaternary.opacity(0.5)), in: Capsule())
        .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }
}
