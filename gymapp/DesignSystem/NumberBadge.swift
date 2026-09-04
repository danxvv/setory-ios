//
//  NumberBadge.swift
//  gymapp
//

import SwiftUI

/// Position badge for numbered rows (series, instruction steps).
struct NumberBadge: View {
    /// Zero-based position; displayed one-based.
    let index: Int

    var body: some View {
        Text("\(index + 1)")
            .font(.footnote.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 26, height: 26)
            .background(.quaternary, in: Circle())
    }
}
