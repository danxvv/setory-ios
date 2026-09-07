//
//  TemplateApplyPicker.swift
//  gymapp
//
//  Sheet listing the user's templates; tapping one applies it to the
//  selected day (after confirmation when a plan already exists).
//

import SwiftUI

struct TemplateApplyPicker: View {
    let templates: [RoutineTemplate]
    let onSelect: (RoutineTemplate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    row(for: template)
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("apply-template-\(template.name)")
            }
            .gymListStyle()
            .navigationTitle("Start from template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(for template: RoutineTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(template.name)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(template.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            let primary = template.primaryMusclesCovered
            if !primary.isEmpty {
                MuscleChips(muscles: primary, emphasis: .primary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
