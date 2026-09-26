//
//  TemplateDraft.swift
//  Setory
//
//  Editable, unsaved state of the template editor. Value semantics so
//  cancelling discards everything; `apply(to:in:)` writes it back into a
//  RoutineTemplate on save. Pure logic lives here so unit tests need no UI.
//

import Foundation
import SwiftData

struct TemplateDraft: Equatable {
    /// One editable exercise row with a stable identity for ForEach, so rows
    /// keep their stepper state while reordering.
    struct Item: Identifiable, Equatable {
        let id = UUID()
        var exercise: Exercise?
        var targetSets: Int = 3
    }

    var name: String = ""
    var items: [Item] = []

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Save is allowed only with a non-empty trimmed name and ≥1 exercise.
    var isSavable: Bool {
        !trimmedName.isEmpty && !items.isEmpty
    }

    /// The items' exercises in draft order, skipping missing references.
    var exercises: [Exercise] {
        items.compactMap(\.exercise)
    }

    var suggestedName: String? {
        TemplateNameSuggester.suggestedName(for: exercises)
    }

    init(name: String = "", items: [Item] = []) {
        self.name = name
        self.items = items
    }

    /// Draft pre-filled from an existing template (edit flow).
    init(template: RoutineTemplate) {
        self.name = template.name
        self.items = template.orderedItems.map {
            Item(exercise: $0.exercise, targetSets: $0.targetSets)
        }
    }

    /// Draft pre-filled from a saved session: exercises deduplicated in
    /// first-appearance order, target sets = that exercise's series count
    /// clamped to 1–10. Series without an exercise are skipped.
    static func draft(from session: WorkoutSession) -> TemplateDraft {
        var firstAppearance: [Exercise] = []
        var seriesCounts: [String: Int] = [:]
        for series in session.orderedSeries {
            guard let exercise = series.exercise else { continue }
            if seriesCounts[exercise.id] == nil {
                firstAppearance.append(exercise)
            }
            seriesCounts[exercise.id, default: 0] += 1
        }
        let range = RoutineTemplateItem.targetSetsRange
        return TemplateDraft(items: firstAppearance.map { exercise in
            Item(
                exercise: exercise,
                targetSets: min(max(seriesCounts[exercise.id] ?? range.lowerBound, range.lowerBound), range.upperBound)
            )
        })
    }

    /// Writes the draft into `template`, replacing its previous items.
    /// The caller owns inserting a brand-new template and saving the context.
    func apply(to template: RoutineTemplate, in context: ModelContext) {
        template.name = trimmedName
        for item in template.items {
            context.delete(item)
        }
        for (index, item) in items.enumerated() {
            let modelItem = RoutineTemplateItem(order: index, targetSets: item.targetSets, exercise: item.exercise)
            modelItem.template = template
            context.insert(modelItem)
        }
    }
}
