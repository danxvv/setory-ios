//
//  AnimatedGIFView.swift
//  Setory
//
//  Dependency-free GIF playback: ImageIO's CGAnimateImageDataWithBlock
//  drives frames into a UIImageView. SwiftUI owns the layout; callers give
//  the view an explicit frame.
//

import ImageIO
import SwiftUI
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let data: Data

    final class Coordinator {
        /// Bumped whenever the animation must stop (new data, teardown);
        /// in-flight animation blocks compare against it and cancel.
        var generation = 0
        var activeData: Data?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.activeData != data else { return }
        coordinator.activeData = data
        coordinator.generation += 1
        let generation = coordinator.generation
        CGAnimateImageDataWithBlock(data as CFData, nil) { [weak view, weak coordinator] _, image, stop in
            guard let view, let coordinator, coordinator.generation == generation else {
                stop.pointee = true
                return
            }
            view.image = UIImage(cgImage: image)
        }
    }

    static func dismantleUIView(_ uiView: UIImageView, coordinator: Coordinator) {
        coordinator.generation += 1
    }
}
