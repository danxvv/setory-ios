//
//  PhotoPreprocessor.swift
//  Setory
//
//  Turns a captured or picked photo into the compact JPEG the vision
//  request carries: downscaled to a bounded max dimension and encoded at a
//  quality that keeps three photos comfortably under a megabyte or two.
//  Pure statics over UIImage so it unit-tests without any UI.
//

import UIKit

enum PhotoPreprocessor {
    /// Longest-edge budget. Vision models tile inputs anyway, so anything
    /// larger costs tokens and upload time without adding detail.
    static let maxDimension: CGFloat = 1024
    static let jpegQuality: CGFloat = 0.7

    /// Downscales when either dimension exceeds `maxDimension`, preserving
    /// aspect ratio; smaller images are returned untouched (upscaling would
    /// only inflate the payload).
    static func downscaled(_ image: UIImage) -> UIImage {
        let size = image.size
        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxDimension, longestEdge > 0 else { return image }

        let scale = maxDimension / longestEdge
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        // Points, not pixels: the target size is already in final pixels.
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// Downscaled JPEG bytes, or nil when the image can't be encoded.
    static func jpegData(from image: UIImage) -> Data? {
        downscaled(image).jpegData(compressionQuality: jpegQuality)
    }

    /// The `image_url` value OpenRouter expects for inline images.
    static func dataURL(forJPEG data: Data) -> String {
        "data:image/jpeg;base64,\(data.base64EncodedString())"
    }
}
