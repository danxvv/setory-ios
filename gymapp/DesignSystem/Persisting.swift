//
//  Persisting.swift
//  gymapp
//
//  The one place the app decides what a failed write means to the user.
//  Store types roll back and rethrow; views call them through this helper so
//  the policy — trap in Debug, carry on in Release — is declared once instead
//  of being copy-pasted into every save site.
//
//  Today's behavior is deliberately preserved: a failed save is a programmer
//  error worth catching in development, and the user sees nothing. Surfacing
//  it in the UI would be a behavior change, so it belongs in its own change.
//

import Foundation

/// Runs a store write, reporting failure rather than propagating it.
/// `what` names the operation in the assertion message.
func persisting(_ what: StaticString, _ work: () throws -> Void) {
    do {
        try work()
    } catch {
        assertionFailure("Failed to \(what): \(error)")
    }
}
