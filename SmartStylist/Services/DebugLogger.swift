import Foundation

@MainActor
final class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    private init() {}

    @Published private(set) var entries: [String] = []

    private static let maxEntries = 30

    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
    }

    func clear() {
        entries = []
    }
}
