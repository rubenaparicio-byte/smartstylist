import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

actor GarmentSegmentationService {

    private let context = CIContext()

    // Segments the foreground garment from the background using Vision and
    // composites it over the DS neutral surface (dsCardSlate #2C2C2E).
    // Returns PNG data preserving clean mask edges.
    func segment(_ image: UIImage) async throws -> Data {
        guard let cgImage = image.cgImage else {
            throw SegmentationError.invalidInput
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.cgImagePropertyOrientation,
            options: [:]
        )
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw SegmentationError.noSubjectFound
        }

        // Merge all detected instances into a single mask
        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )

        // Work in the CGImage's native coordinate space — the mask dimensions
        // match the CGImage dimensions regardless of EXIF orientation
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
        let inputCI = CIImage(cgImage: cgImage)

        // DS neutral background: dsCardSlate #2C2C2E
        let bgColor = CIColor(red: 0.173, green: 0.173, blue: 0.18, alpha: 1.0)
        let background = CIImage(color: bgColor).cropped(to: inputCI.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = inputCI
        blend.backgroundImage = background
        blend.maskImage = maskCI

        guard let output = blend.outputImage,
              let cgOutput = context.createCGImage(output, from: output.extent) else {
            throw SegmentationError.renderFailed
        }

        // Restore UIImage orientation metadata so the result displays correctly
        let result = UIImage(cgImage: cgOutput, scale: image.scale, orientation: image.imageOrientation)
        guard let png = result.pngData() else {
            throw SegmentationError.renderFailed
        }
        return png
    }

    func saveToDocuments(_ data: Data, for id: UUID) throws -> String {
        let garments = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("garments", isDirectory: true)
        try FileManager.default.createDirectory(at: garments, withIntermediateDirectories: true)
        let url = garments.appendingPathComponent("\(id.uuidString).png")
        try data.write(to: url)
        return url.path
    }

    enum SegmentationError: LocalizedError {
        case invalidInput, noSubjectFound, renderFailed

        var errorDescription: String? {
            switch self {
            case .invalidInput:    return "Cannot read image."
            case .noSubjectFound:  return "No garment detected — try with better lighting or a plain background."
            case .renderFailed:    return "Image processing failed."
            }
        }
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
