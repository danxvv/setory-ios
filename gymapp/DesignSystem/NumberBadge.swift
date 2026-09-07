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
            .foregroundStyle(.tint)
            .frame(minWidth: 30, minHeight: 30)
            .background(GymTheme.softAccent, in: RoundedRectangle(cornerRadius: 10))
    }
}
