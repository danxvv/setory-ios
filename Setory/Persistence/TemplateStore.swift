//
//  TemplateStore.swift
//  Setory
//
//  Writes for routine templates: save (create or update from a draft),
//  duplicate, and delete. Muscle coverage is never written — it stays derived
//  from the referenced exercises, so a later exercise edit is reflected
//  automatically.
//

import Foundation
import SwiftData

struct TemplateStore: PersistenceStore {
    let context: ModelContext
    var commit: (ModelContext) throws -> Void = { try $0.save() }

    /// Writes `draft` into `template`, creating one when `template` is nil
    /// (the create flow). Returns the persisted template.
    @discardableResult
    func save(_ draft: TemplateDraft, to template: RoutineTemplate?) throws -> RoutineTemplate {
        let target = template ?? {
            let created = RoutineTemplate(name: draft.trimmedName)
            context.insert(created)
            return created
        }()
        draft.apply(to: target, in: context)
        try saveOrRollback()
        return target
    }

    /// Copies a template and its items, preserving order and target sets.
    /// The copy's name is the localized "<name> copy".
    @discardableResult
    func duplicate(_ template: RoutineTemplate) throws -> RoutineTemplate {
        let copy = RoutineTemplate(name: String(localized: "\(template.name) copy"))
        context.insert(copy)
        for item in template.orderedItems {
            let copiedItem = RoutineTemplateItem(
                order: item.order, targetSets: item.targetSets, exercise: item.exercise
            )
            copiedItem.template = copy
            context.insert(copiedItem)
        }
        try saveOrRollback()
        return copy
    }

    /// Deletes a template. Its items cascade; saved workout sessions are
    /// untouched, since templates and sessions share no records.
    func delete(_ template: RoutineTemplate) throws {
        context.delete(template)
        try saveOrRollback()
    }
}
