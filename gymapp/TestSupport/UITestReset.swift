//
//  UITestReset.swift
//  gymapp
//
//  The `-uitest-reset` path: drop all user-generated data and restore a
//  pristine catalog so UI tests never inherit state from a previous run.
//
//  Performance requirement, not just a preference: wiping and reseeding all
//  ~1300 Exercise rows here used to dominate every UI-test launch. Instead we
//  re-align edited exercises, which parses the catalog JSON only when an edit
//  actually leaked from a prior test. Do not reintroduce a full Exercise wipe
//  + reseed.
//
//  The catalog operations themselves stay in Persistence, where they are
//  unit-tested; this file only sequences them.
//

#if DEBUG

import Foundation
import SwiftData

enum UITestReset {
    static func apply(context: ModelContext) {
        try? context.delete(model: WorkoutSeries.self)
        try? context.delete(model: WorkoutSession.self)
        try? context.delete(model: RoutineTemplateItem.self)
        try? context.delete(model: RoutineTemplate.self)
        try? CatalogSeeder.restorePristineCatalog(context: context)
        try? context.save()
    }
}

#endif
