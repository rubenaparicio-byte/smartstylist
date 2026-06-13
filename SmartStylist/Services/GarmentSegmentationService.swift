import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

actor GarmentSegmentationService {

    private let context = CIContext()

    // Segments the foreground garment from the background using Vision and
    // composites it over a white background for clean catalog-style images.
    // Returns PNG data preserving clean mask edges.
    func segment(_ image: UIImage) async throws -> Data {
        // Normalize orientation first so Vision receives correct pixel layout,
        // then downscale to keep memory and latency under control.
        let prepared = image.normalized().downscaled(maxDimension: 1200)

        guard let cgImage = prepared.cgImage else {
            throw SegmentationError.invalidInput
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        // No orientation hint needed — image is already normalized to .up
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw SegmentationError.noSubjectFound
        }

        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )

        let inputCI = CIImage(cgImage: cgImage)

        // Feather mask edges to avoid harsh cutout artifacts
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 2.0])
            .cropped(to: inputCI.extent)

        // White background for clean catalog-style presentation
        let background = CIImage(color: .white).cropped(to: inputCI.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage   = inputCI
        blend.backgroundImage = background
        blend.maskImage    = maskCI

        guard let output   = blend.outputImage,
              let cgOutput = context.createCGImage(output, from: output.extent) else {
            throw SegmentationError.renderFailed
        }

        // Image is already normalized — no orientation metadata needed
        let result = UIImage(cgImage: cgOutput)
        guard let png = result.pngData() else {
            throw SegmentationError.renderFailed
        }
        return png
    }

    // Returns a relative path ("garments/<UUID>.png") so it survives app reinstalls.
    // ClothingItem.resolvedImageURL reconstructs the absolute path at load time.
    func saveToDocuments(_ data: Data, for id: UUID) throws -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let garments = docs.appendingPathComponent("garments", isDirectory: true)
        try FileManager.default.createDirectory(at: garments, withIntermediateDirectories: true)
        let relativePath = "garments/\(id.uuidString).png"
        try data.write(to: docs.appendingPathComponent(relativePath))
        return relativePath
    }

    enum SegmentationError: LocalizedError {
        case invalidInput, noSubjectFound, renderFailed

        var errorDescription: String? {
            switch self {
            case .invalidInput:   return "Cannot read image."
            case .noSubjectFound: return "No garment detected — try with better lighting or a plain background."
            case .renderFailed:   return "Image processing failed."
            }
        }
    }
}

// ── UIImage helpers ───────────────────────────────────────────────────────────

private extension UIImage {

    // Redraws the image so pixel data matches the visual orientation (.up).
    // Required before passing to Vision — avoids EXIF orientation ambiguity.
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    // Downscales to maxDimension on the longest edge, preserving aspect ratio.
    // Processing at 1200px vs 4032px is ~11× less pixels — Vision stays fast and stable.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(
            width:  (size.width  * scale).rounded(),
            height: (size.height * scale).rounded()
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
