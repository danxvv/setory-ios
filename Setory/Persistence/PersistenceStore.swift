//
//  PersistenceStore.swift
//  Setory
//
//  The write-failure policy, stated once for every store: a failed save rolls
//  the context back so no partial write survives, and the error reaches the
//  caller instead of being swallowed. Before this existed the policy was
//  copy-pasted into five view files.
//

import Foundation
import SwiftData

protocol PersistenceStore {
    var context: ModelContext { get }
    /// How a store commits. Production stores use `ModelContext.save()`;
    /// this is a seam only because SwiftData upserts on unique-constraint
    /// conflicts rather than failing, so tests have no natural way to make a
    /// real save throw and exercise the rollback path.
    var commit: (ModelContext) throws -> Void { get }
}

extension PersistenceStore {
    func saveOrRollback() throws {
        do {
            try commit(context)
        } catch {
            context.rollback()
            throw error
        }
    }
}
