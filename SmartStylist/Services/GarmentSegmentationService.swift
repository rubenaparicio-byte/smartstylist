import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

actor GarmentSegmentationService {

    private let context = CIContext()

    // Segments the foreground garment from the background using Vision and
    // composites it over a white background for clean catalog-style images.
    // Returns PNG data preserving clean mask edges.
    //
    // Low-contrast handling: Vision runs on a contrast/saturation-boosted copy of the
    // image so edge detection succeeds even for white garments on white backgrounds.
    // The final composite always uses the original pixel data for colour fidelity.
    func segment(_ image: UIImage) async throws -> Data {
        // Normalize orientation first so Vision receives correct pixel layout,
        // then downscale to keep memory and latency under control.
        let prepared = image.normalized().downscaled(maxDimension: 1200)

        guard let cgImage = prepared.cgImage else {
            throw SegmentationError.invalidInput
        }

        // Build a contrast-enhanced version for Vision only — this amplifies small
        // luminance/saturation differences at garment edges that would otherwise be
        // invisible to the foreground mask algorithm on low-contrast shots.
        let ciForDetection = CIImage(cgImage: cgImage).contrastEnhancedForDetection()
        let cgForDetection = context.createCGImage(ciForDetection, from: ciForDetection.extent) ?? cgImage

        let request = VNGenerateForegroundInstanceMaskRequest()
        // No orientation hint needed — image is already normalized to .up
        let handler = VNImageRequestHandler(cgImage: cgForDetection, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw SegmentationError.noSubjectFound
        }

        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )

        // Composite uses the ORIGINAL image for colour-accurate output
        let inputCI = CIImage(cgImage: cgImage)

        // Sharpen the mask before feathering: push uncertain mid-range pixel values
        // (common on low-contrast edges) toward 0 or 1, then apply a lighter blur.
        // This avoids the garment "fading into" a similar-toned background.
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
            .clampedToExtent()
            .withSharpenedMaskEdges()
            .cropped(to: inputCI.extent)

        // White background for clean catalog-style presentation
        let background = CIImage(color: .white).cropped(to: inputCI.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage      = inputCI
        blend.backgroundImage = background
        blend.maskImage       = maskCI

        guard let blended = blend.outputImage else {
            throw SegmentationError.renderFailed
        }

        let enhanced = blended.enhancedForCatalog()

        guard let cgOutput = context.createCGImage(enhanced, from: enhanced.extent) else {
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

// ── CIImage enhancement ───────────────────────────────────────────────────────

private extension CIImage {

    // Amplifies contrast and saturation so Vision can distinguish garment edges
    // in low-contrast scenes (e.g. white garment on white background).
    // Only applied to the detection input — never to the final composite.
    func contrastEnhancedForDetection() -> CIImage {
        applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey:   1.8,  // exaggerate luminance differences at edges
            kCIInputSaturationKey: 1.4   // boost saturation to separate whites from greys
        ])
    }

    // Pushes soft mask pixel values (0.2–0.8) toward 0 or 1 so that uncertain
    // regions on low-contrast garment boundaries become decisive cutouts rather
    // than semi-transparent fades into the white background.
    // A light Gaussian blur then restores natural edge feathering.
    func withSharpenedMaskEdges() -> CIImage {
        let sharpened = applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 4.0   // strong curve on grayscale mask values
        ])
        return sharpened.applyingFilter("CIGaussianBlur", parameters: [
            kCIInputRadiusKey: 1.0     // lighter feather than the previous 2.0
        ])
    }

    // Applies a catalog-quality enhancement chain after segmentation:
    //   1. Noise reduction — removes grain/compression artifacts
    //   2. Vibrance boost — makes colors pop without oversaturating skin/neutrals
    //   3. Highlight/shadow compression — flattens wrinkle shadows without losing texture
    //   4. Luminance sharpen — recovers edge crispness lost in the segmentation blur
    func enhancedForCatalog() -> CIImage {
        let noiseReduced = applyingFilter("CINoiseReduction", parameters: [
            "inputNoiseLevel": 0.02,
            "inputSharpness":  0.4
        ])

        let vibrant = noiseReduced.applyingFilter("CIVibrance", parameters: [
            kCIInputAmountKey: 0.3
        ])

        let tonal = vibrant.applyingFilter("CIHighlightShadowAdjust", parameters: [
            "inputHighlightAmount": 0.8,   // compress bright wrinkle highlights
            "inputShadowAmount":    0.6    // lift dark wrinkle shadows
        ])

        return tonal.applyingFilter("CISharpenLuminance", parameters: [
            kCIInputSharpnessKey: 0.4,
            kCIInputRadiusKey:    1.5
        ])
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
