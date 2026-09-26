//
//  SetEntrySheet.swift
//  Setory
//

import SwiftUI

/// Focused data-entry sheet for one set: reps + optional weight for strength
/// exercises, duration for cardio. Confirm stays disabled until the required
/// input is a positive value.
struct SetEntrySheet: View {
    let exercise: Exercise
    let onConfirm: (DraftSeries) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var repsText = ""
    @State private var weightText = ""
    @State private var minutesText = ""

    @FocusState private var focusedField: Field?

    private enum Field {
        case reps, weight, minutes
    }

    private var reps: Int? {
        Int(repsText)
    }

    /// Nil when empty (weight is optional); invalid text stays nil but
    /// non-empty, which blocks Confirm.
    private var weightKg: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var minutes: Int? {
        Int(minutesText)
    }

    private var isValid: Bool {
        switch exercise.category {
        case .strength:
            guard let reps, reps > 0 else { return false }
            if weightText.isEmpty { return true }
            guard let weightKg, weightKg >= 0 else { return false }
            return true
        case .cardio:
            guard let minutes, minutes > 0 else { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ExerciseThumbnailView(exercise: exercise, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Log a set").font(.headline)
                            Text(exercise.localizedName).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                switch exercise.category {
                case .strength:
                    Section {
                        LabeledContent("Reps") {
                            TextField("Required", text: $repsText)
                                .keyboardType(.numberPad)
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .reps)
                                .accessibilityIdentifier("reps-field")
                        }
                        LabeledContent("Weight (kg)") {
                            TextField("Optional", text: $weightText)
                                .keyboardType(.decimalPad)
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .weight)
                                .accessibilityIdentifier("weight-field")
                        }
                    } footer: {
                        Text("Reps are required. Leave weight empty for bodyweight sets.")
                    }
                case .cardio:
                    Section {
                        LabeledContent("Duration (min)") {
                            TextField("Required", text: $minutesText)
                                .keyboardType(.numberPad)
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .minutes)
                                .accessibilityIdentifier("duration-field")
                        }
                    } footer: {
                        Text("How long you did this exercise.")
                    }
                }
            }
            .setoryListStyle()
            .navigationTitle(exercise.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        confirm()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                focusedField = exercise.category == .strength ? .reps : .minutes
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func confirm() {
        guard isValid else { return }
        let draft: DraftSeries
        switch exercise.category {
        case .strength:
            draft = DraftSeries(
                exercise: exercise,
                reps: reps,
                weightKg: weightText.isEmpty ? nil : weightKg
            )
        case .cardio:
            draft = DraftSeries(
                exercise: exercise,
                durationSeconds: (minutes ?? 0) * 60
            )
        }
        onConfirm(draft)
        dismiss()
    }
}
