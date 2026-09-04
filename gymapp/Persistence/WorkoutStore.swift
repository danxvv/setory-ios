//
//  WorkoutStore.swift
//  gymapp
//
//  Writes for the logging screen. Lives here rather than in the view so the
//  draft-to-session conversion is reachable from unit tests, and so the
//  failure policy — roll back, keep no partial write, report to the caller —
//  is stated once instead of once per call site.
//

import Foundation
import SwiftData

struct WorkoutStore: PersistenceStore {
    let context: ModelContext
    var commit: (ModelContext) throws -> Void = { try $0.save() }

    /// Persists the day's drafts as one session, numbering the series in
    /// draft order. Throws (after rolling back) when the save fails, so the
    /// store is never left holding half a session.
    @discardableResult
    func finishDay(date: Date, drafts: [DraftSeries]) throws -> WorkoutSession {
        let session = WorkoutSession(date: date)
        context.insert(session)
        for (index, draft) in drafts.enumerated() {
            let series = WorkoutSeries(
                order: index,
                exercise: draft.exercise,
                reps: draft.reps,
                weightKg: draft.weightKg,
                durationSeconds: draft.durationSeconds
            )
            series.session = session
            context.insert(series)
        }
        try saveOrRollback()
        return session
    }
}
