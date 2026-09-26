//
//  MuscleChips.swift
//  Setory
//
//  Capsule chips for muscle-target metadata. Primary muscles render
//  emphasized (tinted fill), secondary ones muted (outlined). Chips wrap
//  onto new lines so long secondary lists fit any screen width.
//

import SwiftUI

struct MuscleChips: View {
    enum Emphasis {
        case primary, secondary
    }

    let muscles: [Muscle]
    let emphasis: Emphasis

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(muscles, id: \.self) { muscle in
                chip(for: muscle)
            }
        }
    }

    @ViewBuilder
    private func chip(for muscle: Muscle) -> some View {
        let label = Text(muscle.displayName)
            .font(.caption.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        switch emphasis {
        case .primary:
            label
                .foregroundStyle(Color.accentColor)
                .background(SetoryTheme.softAccent, in: Capsule())
        case .secondary:
            label
                .foregroundStyle(.secondary)
                .background(Color.primary.opacity(0.06), in: Capsule())
        }
    }
}

/// Minimal wrapping layout: places subviews left to right, moving to a new
/// row when the proposed width is exceeded.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let offsets = arrange(subviews: subviews, maxWidth: bounds.width).offsets
        for (subview, offset) in zip(subviews, offsets) {
            subview.place(
                at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y),
                proposal: ProposedViewSize(width: min(subview.sizeThatFits(.unspecified).width, bounds.width), height: nil)
            )
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let width = min(subview.sizeThatFits(.unspecified).width, maxWidth)
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if origin.x > 0, origin.x + size.width > maxWidth {
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(origin)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, origin.x - spacing)
        }
        return (CGSize(width: totalWidth, height: origin.y + rowHeight), offsets)
    }
}
