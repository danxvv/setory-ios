//
//  AIFlowScaffold.swift
//  gymapp
//
//  The shell both AI sheets need: the no-key explanation with its route into
//  AI Settings, the in-flight progress row with a cancel action, and the
//  failure alert offering retry plus a settings route for key and credit
//  failures. Each of these existed twice — once per sheet — with the same
//  wording and the same behavior.
//

import SwiftUI

/// The no-key state: explains what is missing and opens AI Settings. Shown
/// instead of the feature's own sections, so no request is ever attempted.
struct AIKeyRequiredSection: View {
    /// Feature-specific explanation of what the key enables.
    let explanation: LocalizedStringKey
    let explanationIdentifier: String
    let openSettingsIdentifier: String
    let onOpenSettings: () -> Void

    var body: some View {
        Section {
            Text(explanation)
                .accessibilityIdentifier(explanationIdentifier)
            Button("Open AI Settings") {
                onOpenSettings()
            }
            .accessibilityIdentifier(openSettingsIdentifier)
        }
    }
}

/// The in-flight row: progress plus a destructive cancel.
struct AIProgressRows: View {
    let message: LocalizedStringKey
    let progressIdentifier: String
    let cancelTitle: LocalizedStringKey
    let cancelIdentifier: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier(progressIdentifier)
        Button(cancelTitle, role: .destructive) {
            onCancel()
        }
        .accessibilityIdentifier(cancelIdentifier)
    }
}

extension View {
    /// The shared failure alert: a localized message, Retry, an AI Settings
    /// route for the failures the user fixes there, and Cancel.
    func aiFailureAlert(
        _ title: LocalizedStringKey,
        error: Binding<AIError?>,
        onRetry: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { failure in
            Button("Retry") {
                onRetry()
            }
            if failure.pointsToSettings {
                Button("Open AI Settings") {
                    onOpenSettings()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { failure in
            Text(failure.errorDescription ?? "")
        }
    }
}
