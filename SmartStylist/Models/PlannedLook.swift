import Foundation
import SwiftData

@Model
final class PlannedLook {
    var id: UUID = UUID()
    var scheduledDate: Date = Date()
    var occasionRaw: String = "Daily"   // EventContext.rawValue — English, not localised
    var venueNote: String?              // "Restaurante elegante", "Bar de copas"…
    var generatedOutfitData: Data?      // JSON-encoded StyleResponse
    var itemIds: [UUID] = []
    var isInstant: Bool = false         // true = created from Instant mode, not the calendar
    var weatherContext: String?

    init(scheduledDate: Date = Date(),
         occasionRaw: String = "Daily",
         venueNote: String? = nil,
         isInstant: Bool = false) {
        self.scheduledDate = scheduledDate
        self.occasionRaw   = occasionRaw
        self.venueNote     = venueNote
        self.isInstant     = isInstant
    }

    var occasion: EventContext {
        EventContext(rawValue: occasionRaw) ?? .daily
    }

    // Deterministic identifier derived from the model ID — no need to store separately.
    var notificationIdentifier: String {
        "smartstylist.planned-look.\(id.uuidString)"
    }

    var styleResponse: StyleResponse? {
        get {
            guard let data = generatedOutfitData else { return nil }
            return try? JSONDecoder().decode(StyleResponse.self, from: data)
        }
        set {
            generatedOutfitData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
}
