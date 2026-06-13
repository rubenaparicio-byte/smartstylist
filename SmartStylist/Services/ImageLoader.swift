import UIKit

// Thread-safe image cache with async off-main loading.
// Keyed by the file path string; cost = RGBA byte count.
@MainActor
final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func load(from url: URL) async -> UIImage? {
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let path = url.path
        let image = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: path)
        }.value
        if let image {
            cache.setObject(image, forKey: key,
                            cost: Int(image.size.width * image.size.height * 4))
        }
        return image
    }

    func evict(url: URL) {
        cache.removeObject(forKey: url.path as NSString)
    }

    func evictAll() {
        cache.removeAllObjects()
    }
}
